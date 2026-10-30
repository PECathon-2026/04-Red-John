"""
OpenAI-compatible chat provider with an API-key pool.

Ported from Mycel's `RobustGroqClient`: on a 429 the key is benched for the
time the provider asks for and the next healthy key is tried at once; dead
keys (401/403) are benched for a day. Works for Groq, Gemini's OpenAI
endpoint, OpenAI, or a local server — anything speaking /chat/completions.
"""
from __future__ import annotations

import asyncio
import json
import logging
import re
import time
from dataclasses import dataclass

import httpx

from app.core.errors import ExternalServiceError
from app.infrastructure.llm.types import ChatRequest, ChatResponse, ContextTooLarge, ToolCall, ToolCallRejected, Usage

log = logging.getLogger(__name__)

_RETRY_AFTER = re.compile(r"try again in (?:(\d+)m)?(\d+(?:\.\d+)?)s", re.I)
_THINK = re.compile(r"<think>.*?</think>", re.S)
# Groq's tool-use models sometimes append channel markers to tool names.
_TOOL_NAME_JUNK = re.compile(r"<\|.*$")


@dataclass
class _Key:
    secret: str
    cooldown_until: float = 0.0
    last_used: int = 0       # pick counter when this key was last handed out (0 = never)
    dead: bool = False       # rejected with 401/403 (benched for a day)

    @property
    def preview(self) -> str:
        return f"{self.secret[:6]}…"


class OpenAICompatibleProvider:
    def __init__(
        self,
        name: str,
        base_url: str,
        api_keys: list[str],
        *,
        timeout_s: float = 90.0,
        max_attempts: int = 12,
        server_error_bench_s: float = 10.0,
        max_key_wait_s: float = 2.0,
        max_total_wait_s: float = 10.0,
        auth_header: str = "Authorization",
        transport: httpx.AsyncBaseTransport | None = None,
    ) -> None:
        self.name = name
        # "Authorization" sends `Bearer <key>`; Azure OpenAI wants the raw key in an `api-key` header.
        self._auth_header = auth_header
        # Newer models (GPT-5 / o-series on Azure and OpenAI) refuse `max_tokens` and custom temperatures.
        # Learned from the first 400 that says so, then remembered for this provider.
        self._use_max_completion_tokens = False
        self._omit_temperature = False
        # A key that hit a 5xx or a network error sits out this long; the next key takes the request.
        self._server_error_bench_s = server_error_bench_s
        # Groq answers bursts with 429s that clear in well under a second; waiting that long beats failing a
        # whole task. Anything longer is an error right away.
        self._max_key_wait_s = max_key_wait_s
        self._max_total_wait_s = max_total_wait_s  # all such short waits together, per request
        self._keys = [_Key(k) for k in api_keys if k]
        self._picks = 0  # a counter, not a clock: Windows' monotonic clock is too coarse to order quick picks
        self._max_attempts = max_attempts
        self._http = httpx.AsyncClient(
            base_url=base_url.rstrip("/"), timeout=timeout_s, transport=transport
        )

    @property
    def available(self) -> bool:
        return bool(self._keys)

    async def aclose(self) -> None:
        await self._http.aclose()

    async def _next_key(self, deadline: float = 0.0) -> _Key:
        """The least recently used healthy key. With none left, wait only if one frees up within
        `max_key_wait_s`; otherwise fail at once so the gateway can move on and the caller sees why."""
        now = time.monotonic()
        healthy = [k for k in self._keys if k.cooldown_until <= now]
        if healthy:
            # Least recently used first: load spreads evenly over the pool, and concurrent agents each get a
            # different key because the pick is stamped before the request goes out.
            key = min(healthy, key=lambda k: k.last_used)
            self._picks += 1
            key.last_used = self._picks
            return key
        cooling = [k.cooldown_until - now for k in self._keys if not k.dead]
        if cooling and min(cooling) <= self._max_key_wait_s and now + min(cooling) <= deadline:
            await asyncio.sleep(min(cooling))
            return await self._next_key(deadline)
        status = self.key_status()
        free_in = f"; the first frees up in {min(cooling):.0f}s" if cooling else ""
        raise ExternalServiceError(
            f"{self.name}: no API key available ({status['cooling']} rate limited, {status['dead']} rejected, "
            f"of {status['total']}){free_in}",
            details={"keys": status},
        )

    def key_status(self) -> dict[str, int]:
        """Counts only, never key values: healthy (usable now), cooling (rate limited), dead (rejected)."""
        now = time.monotonic()
        dead = sum(1 for k in self._keys if k.dead and k.cooldown_until > now)
        cooling = sum(1 for k in self._keys if not k.dead and k.cooldown_until > now)
        return {"total": len(self._keys), "healthy": len(self._keys) - dead - cooling, "cooling": cooling, "dead": dead}

    @staticmethod
    def _retry_after(response: httpx.Response) -> float:
        header = response.headers.get("retry-after")
        if header:
            try:
                return float(header) + 0.5
            except ValueError:
                pass
        match = _RETRY_AFTER.search(response.text)
        if match:
            minutes = float(match.group(1) or 0)
            return minutes * 60 + float(match.group(2)) + 0.5
        return 10.0

    @staticmethod
    def _tool_call_rejection(response: httpx.Response) -> ToolCallRejected | None:
        if response.status_code != 400:
            return None
        try:
            body = response.json()
        except ValueError:
            return None
        # Gemini's OpenAI-compatible endpoint wraps its error in a list: [{"error": {...}}].
        if isinstance(body, list):
            body = body[0] if body else {}
        error = body.get("error") if isinstance(body, dict) else None
        if not isinstance(error, dict):
            return None
        # Both mean the model's own output was malformed, not the request: the agent should try again.
        if error.get("code") not in ("tool_use_failed", "output_parse_failed"):
            return None
        return ToolCallRejected(str(error.get("message", "tool call rejected"))[:800],
                                str(error.get("failed_generation", ""))[:800])

    def _payload(self, request: ChatRequest, model: str) -> dict:
        body: dict = {"model": model, "messages": request.messages}
        if not self._omit_temperature:
            body["temperature"] = request.temperature
        if request.tools:
            body["tools"] = request.tools
            body["tool_choice"] = request.tool_choice or "auto"
        if request.max_tokens:
            body["max_completion_tokens" if self._use_max_completion_tokens else "max_tokens"] = request.max_tokens
        if request.response_format:
            body["response_format"] = request.response_format
        return body

    @staticmethod
    def _parse(data: dict, provider: str, model: str) -> ChatResponse:
        choice = (data.get("choices") or [{}])[0]
        message = choice.get("message") or {}
        calls: list[ToolCall] = []
        for raw in message.get("tool_calls") or []:
            fn = raw.get("function") or {}
            args_text = fn.get("arguments") or "{}"
            try:
                args = json.loads(args_text) if isinstance(args_text, str) else dict(args_text)
                bad = None
            except ValueError:
                args, bad = {}, args_text
            calls.append(
                ToolCall(
                    id=raw.get("id") or f"call_{len(calls)}",
                    name=_TOOL_NAME_JUNK.sub("", fn.get("name", "")).strip(),
                    arguments=args if isinstance(args, dict) else {},
                    raw_arguments=bad,
                )
            )
        usage = data.get("usage") or {}
        return ChatResponse(
            content=_THINK.sub("", message.get("content") or "").strip(),
            tool_calls=calls,
            finish_reason=choice.get("finish_reason"),
            usage=Usage(
                prompt_tokens=usage.get("prompt_tokens", 0),
                completion_tokens=usage.get("completion_tokens", 0),
            ),
            provider=provider,
            model=data.get("model", model),
        )

    def _auth(self, key: _Key) -> dict[str, str]:
        if self._auth_header.lower() == "authorization":
            return {"Authorization": f"Bearer {key.secret}"}
        return {self._auth_header: key.secret}

    def _adapt_to_unsupported_param(self, response: httpx.Response) -> bool:
        """True if a 400 named a parameter this model refuses and the payload can drop or rename it."""
        if response.status_code != 400:
            return False
        text = response.text
        if "max_tokens" in text and "max_completion_tokens" in text and not self._use_max_completion_tokens:
            self._use_max_completion_tokens = True
        elif "temperature" in text and ("unsupported" in text.lower() or "does not support" in text)                 and not self._omit_temperature:
            self._omit_temperature = True
        else:
            return False
        log.info("[%s] model refused a parameter; adapting (max_completion_tokens=%s, omit_temperature=%s)",
                 self.name, self._use_max_completion_tokens, self._omit_temperature)
        return True

    async def complete(self, request: ChatRequest, model: str) -> ChatResponse:
        if not self._keys:
            raise ExternalServiceError(f"{self.name}: no API keys configured")
        payload = self._payload(request, model)
        last_error = ""
        # Every failure moves straight on to the next key; no sleeping. When no key is left, _next_key raises.
        # Rate limits do not count as attempts (each benches its key, so the loop ends when the pool is out).
        attempt, rate_limited = 0, 0
        deadline = time.monotonic() + self._max_total_wait_s
        while attempt < self._max_attempts:
            if rate_limited > max(40, 4 * len(self._keys)):
                raise ExternalServiceError(f"{self.name}: still rate limited after {rate_limited} tries across "
                                           f"{len(self._keys)} key(s)")
            key = await self._next_key(deadline)
            try:
                response = await self._http.post(
                    "/chat/completions",
                    json=payload,
                    headers=self._auth(key),
                )
            except httpx.TransportError as exc:
                attempt += 1
                key.cooldown_until = time.monotonic() + self._server_error_bench_s
                last_error = f"transport error: {exc}"
                log.warning("[%s] key %s: %s; trying the next key", self.name, key.preview, last_error)
                continue

            if response.status_code == 200:
                try:
                    data = response.json()
                except ValueError:
                    data = None
                if isinstance(data, dict):
                    return self._parse(data, self.name, model)
                # A 200 that isn't a completion (empty body, HTML from a wrong URL or a proxy) is a provider
                # fault: fail this route so the gateway can fall back instead of crashing the agent.
                raise ExternalServiceError(
                    f"{self.name} returned a non-JSON reply (HTTP 200, "
                    f"{response.headers.get('content-type', 'no content-type')}, {len(response.content)} bytes)",
                    details={"body": response.text[:300]},
                )
            if response.status_code == 429:
                wait = self._retry_after(response)
                key.cooldown_until = time.monotonic() + wait
                rate_limited += 1
                log.info("[%s] key %s rate limited; benched %.1fs, switching key", self.name, key.preview, wait)
                last_error = "rate limited"
                continue
            if self._adapt_to_unsupported_param(response):
                payload = self._payload(request, model)
                continue
            attempt += 1
            if response.status_code in (401, 403):
                key.cooldown_until = time.monotonic() + 86_400
                key.dead = True
                log.error("[%s] key %s rejected (%s); benched", self.name, key.preview, response.status_code)
                last_error = f"auth error {response.status_code}"
                continue
            if response.status_code >= 500:
                key.cooldown_until = time.monotonic() + self._server_error_bench_s
                last_error = f"server error {response.status_code}"
                log.warning("[%s] key %s: %s; trying the next key", self.name, key.preview, last_error)
                continue
            if response.status_code == 413 or "context_length_exceeded" in response.text:
                raise ContextTooLarge(f"{self.name}: request too large — {response.text[:300]}")
            rejected = self._tool_call_rejection(response)
            if rejected is not None:
                raise rejected
            # 400-class: the request itself is wrong; retrying will not help.
            raise ExternalServiceError(
                f"{self.name} rejected the request ({response.status_code})",
                details={"body": response.text[:1000]},
            )
        raise ExternalServiceError(
            f"{self.name}: gave up after {self._max_attempts} attempts ({last_error})"
        )
