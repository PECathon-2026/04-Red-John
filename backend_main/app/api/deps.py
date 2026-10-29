"""
FastAPI dependencies: the container, the current user, and role checks.

Every route declares the least role it needs (`ViewerDep`, `OperatorDep`,
`ApproverDep`, `AdminDep`); the dependency authenticates the bearer token,
loads the user (so disabled accounts and role changes apply immediately) and
refuses lower roles with 403.
"""
from __future__ import annotations

from typing import Annotated

from fastapi import Depends, Request, WebSocket
from fastapi.security import OAuth2PasswordBearer

from app.container import Container
from app.core import metrics
from app.core.errors import AuthenticationError, PermissionDenied
from app.domain.users import LOCAL_PRINCIPAL, Principal, Role

# tokenUrl lets the Swagger UI's "Authorize" button log in with a username and password.
bearer = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/token", auto_error=False)


def get_container(request: Request) -> Container:
    return request.app.state.container


def get_ws_container(websocket: WebSocket) -> Container:
    return websocket.app.state.container


ContainerDep = Annotated[Container, Depends(get_container)]
WsContainerDep = Annotated[Container, Depends(get_ws_container)]


async def authenticate(container: Container, token: str | None) -> Principal:
    if not container.settings.auth_enabled:
        return LOCAL_PRINCIPAL
    if not token:
        metrics.AUTH_FAILURES.inc(reason="missing_token")
        raise AuthenticationError("Sign in to use DevPilot (Authorization: Bearer <token>)")
    try:
        return await container.auth.principal(token)
    except AuthenticationError:
        metrics.AUTH_FAILURES.inc(reason="invalid_token")
        raise


async def current_principal(request: Request, token: Annotated[str | None, Depends(bearer)]) -> Principal:
    principal = await authenticate(get_container(request), token)
    request.state.principal = principal
    return principal


def require(role: Role):
    async def check(principal: Annotated[Principal, Depends(current_principal)]) -> Principal:
        if not principal.can(role):
            raise PermissionDenied(f"This needs the {role} role; you are {principal.role}")
        return principal

    return check


ViewerDep = Annotated[Principal, Depends(require(Role.VIEWER))]
OperatorDep = Annotated[Principal, Depends(require(Role.OPERATOR))]
ApproverDep = Annotated[Principal, Depends(require(Role.APPROVER))]
AdminDep = Annotated[Principal, Depends(require(Role.ADMIN))]
