"""Sign-in and user management."""
from __future__ import annotations

from typing import Annotated, Any

from fastapi import APIRouter, Depends, Request
from fastapi.security import OAuth2PasswordRequestForm
from pydantic import BaseModel, Field

from app.api.deps import AdminDep, ContainerDep, ViewerDep
from app.api.middleware import client_address
from app.core import metrics
from app.core.errors import AuthenticationError, RateLimited, ValidationFailed
from app.domain.users import Role, User

router = APIRouter(prefix="/auth", tags=["auth"])


class LoginBody(BaseModel):
    username: str = Field(min_length=1, max_length=64)
    password: str = Field(min_length=1, max_length=256)


class NewUser(BaseModel):
    username: str = Field(min_length=2, max_length=64)
    password: str = Field(min_length=10, max_length=256)
    role: Role = Role.VIEWER


class UserState(BaseModel):
    disabled: bool


def _public(user: User) -> dict[str, Any]:
    return {"user_id": user.user_id, "username": user.username, "role": user.role, "disabled": user.disabled,
            "created_at": user.created_at, "created_by": user.created_by}


async def _login(container, request: Request, username: str, password: str) -> dict[str, Any]:
    settings = container.settings
    if not settings.auth_enabled:
        raise AuthenticationError("Authentication is disabled on this server; no sign-in is needed")
    if settings.rate_limit_enabled:
        allowed, retry = await container.rate_limiter.hit(
            f"login:{client_address(request)}:{username.strip().lower()}", settings.login_rate_limit_per_minute)
        if not allowed:
            metrics.RATE_LIMITED.inc(scope="login")
            raise RateLimited("Too many sign-in attempts; try again later", details={"retry_after_s": retry})
    try:
        token, user = await container.auth.login(username, password)
    except AuthenticationError:
        metrics.AUTH_FAILURES.inc(reason="bad_credentials")
        raise
    return {"access_token": token, "token_type": "bearer", "expires_in": container.auth.tokens.ttl_s,
            "user": _public(user)}


@router.post("/login")
async def login(body: LoginBody, request: Request, container: ContainerDep) -> dict[str, Any]:
    """Sign in with a username and password; returns a bearer token."""
    return await _login(container, request, body.username, body.password)


@router.post("/token", include_in_schema=False)
async def token(form: Annotated[OAuth2PasswordRequestForm, Depends()], request: Request,
                container: ContainerDep) -> dict[str, Any]:
    """OAuth2 password flow, used by the Swagger UI's Authorize button."""
    return await _login(container, request, form.username, form.password)


@router.get("/me")
async def me(principal: ViewerDep) -> dict[str, Any]:
    return principal.model_dump(mode="json")


@router.get("/users")
async def list_users(_: AdminDep, container: ContainerDep) -> dict[str, Any]:
    return {"users": [_public(u) for u in await container.auth.list_users()]}


@router.post("/users", status_code=201)
async def create_user(body: NewUser, admin: AdminDep, container: ContainerDep) -> dict[str, Any]:
    user = await container.auth.create_user(body.username, body.password, body.role, created_by=admin.username)
    return {"user": _public(user)}


@router.post("/users/{username}/state")
async def set_user_state(username: str, body: UserState, admin: AdminDep, container: ContainerDep) -> dict[str, Any]:
    """Disable (or re-enable) an account. Takes effect on the user's next request."""
    if username.strip().lower() == admin.username and body.disabled:
        raise ValidationFailed("You cannot disable your own account")
    return {"user": _public(await container.auth.set_disabled(username, body.disabled))}
