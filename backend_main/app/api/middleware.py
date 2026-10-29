"""
HTTP middleware, outermost first:

- `RequestIdMiddleware`: every request gets an id (echoed back, attached to logs) and is counted and timed.
- `SecurityMiddleware`: rejects oversized bodies, applies the per-client rate limit, and adds security headers.
"""
from __future__ import annotations

import logging
import time
import uuid

from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.requests import Request
from starlette.responses import JSONResponse, Response

from app.core import metrics
from app.core.logging import request_id_var

log = logging.getLogger("devpilot.access")

_SECURITY_HEADERS = {
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "Referrer-Policy": "no-referrer",
    "Cross-Origin-Resource-Policy": "same-site",
}
# The interactive docs load their own scripts; everything else is JSON.
_API_CSP = "default-src 'none'; frame-ancestors 'none'"
_UNLIMITED_PATHS = ("/health/", "/metrics")


def client_address(request: Request) -> str:
    return request.client.host if request.client else "unknown"


class RequestIdMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next: RequestResponseEndpoint) -> Response:
        request_id = request.headers.get("x-request-id") or uuid.uuid4().hex[:16]
        token = request_id_var.set(request_id)
        started = time.perf_counter()
        try:
            response = await call_next(request)
        finally:
            request_id_var.reset(token)
        elapsed = time.perf_counter() - started
        route = request.scope.get("route")
        template = getattr(route, "path", "unmatched")  # route templates keep metric labels bounded
        metrics.HTTP_REQUESTS.inc(method=request.method, route=template, status=str(response.status_code))
        metrics.HTTP_LATENCY.observe(elapsed, method=request.method, route=template)
        response.headers["x-request-id"] = request_id
        log.info("%s %s -> %s (%.1f ms)", request.method, request.url.path, response.status_code, elapsed * 1000)
        return response


class SecurityMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next: RequestResponseEndpoint) -> Response:
        container = getattr(request.app.state, "container", None)
        settings = container.settings if container is not None else None

        if settings is not None:
            length = request.headers.get("content-length")
            if length and length.isdigit() and int(length) > settings.max_request_bytes:
                return self._error(413, "payload_too_large",
                                   f"Request body is larger than {settings.max_request_bytes} bytes")
            path = request.url.path
            if settings.rate_limit_enabled and not any(p in path for p in _UNLIMITED_PATHS):
                allowed, retry = await container.rate_limiter.hit(
                    f"ip:{client_address(request)}", settings.rate_limit_per_minute)
                if not allowed:
                    metrics.RATE_LIMITED.inc(scope="client")
                    response = self._error(429, "rate_limited", "Too many requests; slow down")
                    response.headers["Retry-After"] = str(retry)
                    return response

        response = await call_next(request)
        for name, value in _SECURITY_HEADERS.items():
            response.headers.setdefault(name, value)
        if not request.url.path.startswith(("/docs", "/redoc", "/openapi")):
            response.headers.setdefault("Content-Security-Policy", _API_CSP)
        if settings is not None and settings.is_production:
            response.headers.setdefault("Strict-Transport-Security", "max-age=31536000; includeSubDomains")
        return response

    @staticmethod
    def _error(status: int, code: str, message: str) -> JSONResponse:
        return JSONResponse(status_code=status, content={"error": {"code": code, "message": message, "details": {}}})
