"""People who operate DevPilot, and what each may do."""
from __future__ import annotations

from enum import StrEnum

from pydantic import BaseModel, Field

from app.core.ids import new_id, now_ms


class Role(StrEnum):
    """Ordered: each role can do everything the roles below it can."""

    VIEWER = "viewer"        # watch missions, read reports, evidence and audit trails
    OPERATOR = "operator"    # create, run and stop missions; answer agents' questions; request apply
    APPROVER = "approver"    # approve or deny AMBER actions, including applying a change to a repository
    ADMIN = "admin"          # manage users


_RANK = {Role.VIEWER: 0, Role.OPERATOR: 1, Role.APPROVER: 2, Role.ADMIN: 3}


class User(BaseModel):
    user_id: str = Field(default_factory=lambda: new_id("usr"))
    username: str
    password_hash: str
    role: Role = Role.VIEWER
    disabled: bool = False
    created_at: int = Field(default_factory=now_ms)
    created_by: str = "system"


class Principal(BaseModel):
    """Who is making this request (the user record minus secrets)."""

    user_id: str
    username: str
    role: Role

    def can(self, role: Role) -> bool:
        return _RANK[self.role] >= _RANK[role]

    @classmethod
    def of(cls, user: User) -> Principal:
        return cls(user_id=user.user_id, username=user.username, role=user.role)


# Used when AUTH_ENABLED=false (local development only — refused in production).
LOCAL_PRINCIPAL = Principal(user_id="usr_local", username="local", role=Role.ADMIN)
