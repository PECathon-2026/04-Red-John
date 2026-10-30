"""
Authentication: password hashing, JWT access tokens, login and user management.

- Passwords are hashed with scrypt from the standard library (memory-hard, no
  native dependency), each with its own salt, and compared in constant time.
- Access tokens are short-lived HS256 JWTs carrying only the user id. Roles
  and the disabled flag are read from the user record on every request, so
  changing or revoking access takes effect immediately.
- Login does the same work whether or not the user exists, so response times
  do not reveal which usernames are valid.
"""
from __future__ import annotations

import base64
import hashlib
import hmac
import logging
import os
import secrets
import time

import jwt

from app.core.errors import AuthenticationError, ConflictError, NotFoundError, ValidationFailed
from app.domain.users import Principal, Role, User
from app.infrastructure.storage.base import UserRepository

log = logging.getLogger(__name__)

_SCRYPT = {"n": 2**14, "r": 8, "p": 1}
MIN_PASSWORD_LENGTH = 10


def hash_password(password: str) -> str:
    salt = os.urandom(16)
    digest = hashlib.scrypt(password.encode(), salt=salt, dklen=32, **_SCRYPT)
    return "scrypt${n}${r}${p}${salt}${digest}".format(
        **_SCRYPT, salt=base64.b64encode(salt).decode(), digest=base64.b64encode(digest).decode())


def verify_password(password: str, stored: str) -> bool:
    try:
        scheme, n, r, p, salt, digest = stored.split("$")
        if scheme != "scrypt":
            return False
        expected = base64.b64decode(digest)
        actual = hashlib.scrypt(password.encode(), salt=base64.b64decode(salt), dklen=len(expected),
                                n=int(n), r=int(r), p=int(p))
    except (ValueError, TypeError):
        return False
    return hmac.compare_digest(actual, expected)


# A real hash to check against when the user does not exist (equal timing either way).
_DUMMY_HASH = hash_password(secrets.token_urlsafe(16))


class TokenService:
    def __init__(self, secret: str, ttl_minutes: int, issuer: str = "devpilot") -> None:
        if len(secret) < 32:
            raise ValueError("JWT secret must be at least 32 characters")
        self._secret = secret
        self._ttl_s = ttl_minutes * 60
        self._issuer = issuer

    @property
    def ttl_s(self) -> int:
        return self._ttl_s

    def issue(self, user: User) -> str:
        now = int(time.time())
        claims = {"sub": user.user_id, "iss": self._issuer, "iat": now, "exp": now + self._ttl_s,
                  "jti": secrets.token_hex(8)}
        return jwt.encode(claims, self._secret, algorithm="HS256")

    def subject(self, token: str) -> str:
        try:
            claims = jwt.decode(token, self._secret, algorithms=["HS256"], issuer=self._issuer,
                                options={"require": ["sub", "exp", "iat"]})
        except jwt.ExpiredSignatureError:
            raise AuthenticationError("Token expired; log in again") from None
        except jwt.PyJWTError:
            raise AuthenticationError("Invalid token") from None
        return str(claims["sub"])


class AuthService:
    def __init__(self, users: UserRepository, tokens: TokenService) -> None:
        self._users = users
        self.tokens = tokens

    async def login(self, username: str, password: str) -> tuple[str, User]:
        user = await self._users.get_by_username(username.strip().lower())
        valid = verify_password(password, user.password_hash if user else _DUMMY_HASH)
        if user is None or not valid or user.disabled:
            raise AuthenticationError("Wrong username or password")
        return self.tokens.issue(user), user

    async def principal(self, token: str) -> Principal:
        user = await self._users.get(self.tokens.subject(token))
        if user is None or user.disabled:
            raise AuthenticationError("This account no longer has access")
        return Principal.of(user)

    async def create_user(self, username: str, password: str, role: Role, *, created_by: str) -> User:
        name = username.strip().lower()
        if not name or not name.replace("-", "").replace("_", "").replace(".", "").isalnum():
            raise ValidationFailed("Usernames may contain letters, digits, '.', '-' and '_'")
        if len(password) < MIN_PASSWORD_LENGTH:
            raise ValidationFailed(f"Passwords must be at least {MIN_PASSWORD_LENGTH} characters")
        if await self._users.get_by_username(name):
            raise ConflictError(f"User {name} already exists")
        user = User(username=name, password_hash=hash_password(password), role=role, created_by=created_by)
        await self._users.create(user)
        log.info("user %s created with role %s by %s", name, role, created_by)
        return user

    async def set_disabled(self, username: str, disabled: bool) -> User:
        user = await self._users.get_by_username(username.strip().lower())
        if user is None:
            raise NotFoundError(f"No user {username}")
        updated = user.model_copy(update={"disabled": disabled})
        await self._users.update(updated)
        return updated

    async def list_users(self) -> list[User]:
        return await self._users.list()

    async def ensure_admin(self, username: str, password: str) -> None:
        """Create the bootstrap admin if it does not exist yet (never overwrites an existing account)."""
        if not username or not password:
            return
        if await self._users.get_by_username(username.strip().lower()) is None:
            await self.create_user(username, password, Role.ADMIN, created_by="bootstrap")
