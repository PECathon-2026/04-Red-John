"""
Error model. Services raise `DevPilotError` subclasses; the API layer maps
them to HTTP responses in one place, so no route builds error JSON by hand.
"""
from __future__ import annotations

import logging

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

log = logging.getLogger(__name__)


class DevPilotError(Exception):
    status_code = 500
    code = "internal_error"

    def __init__(self, message: str, *, details: dict | None = None) -> None:
        super().__init__(message)
        self.message = message
        self.details = details or {}


class NotFoundError(DevPilotError):
    status_code = 404
    code = "not_found"


class ValidationFailed(DevPilotError):
    status_code = 422
    code = "validation_failed"


class ConflictError(DevPilotError):
    status_code = 409
    code = "conflict"


class PolicyViolation(DevPilotError):
    """An action was refused by the sandbox or the command policy."""

    status_code = 403
    code = "policy_violation"


class AuthenticationError(DevPilotError):
    """No valid credentials (missing, wrong, expired, or the user is disabled)."""

    status_code = 401
    code = "unauthenticated"


class PermissionDenied(DevPilotError):
    """Authenticated, but the user's role does not allow this."""

    status_code = 403
    code = "forbidden"


class RateLimited(DevPilotError):
    status_code = 429
    code = "rate_limited"


class ExternalServiceError(DevPilotError):
    """An upstream dependency (LLM provider, database, broker) failed."""

    status_code = 502
    code = "upstream_error"


def install_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(DevPilotError)
    async def _devpilot_error(_: Request, exc: DevPilotError) -> JSONResponse:
        if exc.status_code >= 500:
            log.error("%s: %s", exc.code, exc.message, extra={"details": exc.details})
        headers = {}
        if isinstance(exc, AuthenticationError):
            headers["WWW-Authenticate"] = "Bearer"
        if isinstance(exc, RateLimited) and exc.details.get("retry_after_s"):
            headers["Retry-After"] = str(int(exc.details["retry_after_s"]))
        return JSONResponse(
            status_code=exc.status_code,
            content={"error": {"code": exc.code, "message": exc.message, "details": exc.details}},
            headers=headers,
        )

    @app.exception_handler(Exception)
    async def _unhandled(_: Request, exc: Exception) -> JSONResponse:
        log.exception("unhandled error")
        return JSONResponse(
            status_code=500,
            content={"error": {"code": "internal_error", "message": "Internal server error"}},
        )
