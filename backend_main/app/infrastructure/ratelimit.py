"""
Fixed-window rate limiting. In memory for one process; Redis when several API
replicas must share the same counters (BUS_BACKEND=redis).
"""
from __future__ import annotations

import time
from typing import Protocol

from redis.asyncio import Redis


class RateLimiter(Protocol):
    async def start(self) -> None: ...

    async def stop(self) -> None: ...

    async def hit(self, key: str, limit: int, window_s: int = 60) -> tuple[bool, int]:
        """Count one request for `key`. Returns (allowed, seconds until the window resets)."""
        ...


class InMemoryRateLimiter:
    def __init__(self, max_keys: int = 50_000) -> None:
        self._windows: dict[str, tuple[int, int]] = {}  # key -> (window start, count)
        self._max_keys = max_keys

    async def start(self) -> None:
        return None

    async def stop(self) -> None:
        return None

    async def hit(self, key: str, limit: int, window_s: int = 60) -> tuple[bool, int]:
        now = int(time.time())
        window = now - now % window_s
        start, count = self._windows.get(key, (window, 0))
        if start != window:
            start, count = window, 0
        count += 1
        if len(self._windows) >= self._max_keys and key not in self._windows:
            self._windows.clear()  # bounded memory: dropping counters only ever lets traffic through
        self._windows[key] = (start, count)
        return count <= limit, start + window_s - now


class RedisRateLimiter:
    def __init__(self, url: str, prefix: str = "devpilot:rl:") -> None:
        self._url = url
        self._prefix = prefix
        self._redis: Redis | None = None

    async def start(self) -> None:
        self._redis = Redis.from_url(self._url, decode_responses=True)

    async def stop(self) -> None:
        if self._redis is not None:
            await self._redis.aclose()
            self._redis = None

    async def hit(self, key: str, limit: int, window_s: int = 60) -> tuple[bool, int]:
        now = int(time.time())
        window = now - now % window_s
        name = f"{self._prefix}{key}:{window}"
        async with self._redis.pipeline(transaction=True) as pipe:
            pipe.incr(name)
            pipe.expire(name, window_s + 1)
            count, _ = await pipe.execute()
        return int(count) <= limit, window + window_s - now
