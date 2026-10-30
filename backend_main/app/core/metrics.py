"""
Process-local metrics in the Prometheus text format (served at /metrics).

A deliberately small registry — counters and a latency summary — so there is
no extra dependency. Each process (API replica, worker) exposes its own
numbers; Prometheus aggregates across them.
"""
from __future__ import annotations

import threading
from collections import defaultdict


def _labels(values: dict[str, str]) -> str:
    if not values:
        return ""
    escaped = (f'{k}="{str(v).replace(chr(92), chr(92) * 2).replace(chr(34), chr(92) + chr(34))}"'
               for k, v in sorted(values.items()))
    return "{" + ",".join(escaped) + "}"


class Counter:
    def __init__(self, name: str, help_text: str) -> None:
        self.name, self.help = name, help_text
        self._values: dict[tuple, float] = defaultdict(float)
        self._lock = threading.Lock()

    def inc(self, amount: float = 1.0, **labels: str) -> None:
        with self._lock:
            self._values[tuple(sorted(labels.items()))] += amount

    def render(self) -> list[str]:
        lines = [f"# HELP {self.name} {self.help}", f"# TYPE {self.name} counter"]
        lines += [f"{self.name}{_labels(dict(key))} {value}" for key, value in sorted(self._values.items())]
        return lines

    def value(self, **labels: str) -> float:
        return self._values.get(tuple(sorted(labels.items())), 0.0)


class Summary:
    def __init__(self, name: str, help_text: str) -> None:
        self.name, self.help = name, help_text
        self._count: dict[tuple, int] = defaultdict(int)
        self._sum: dict[tuple, float] = defaultdict(float)
        self._lock = threading.Lock()

    def observe(self, value: float, **labels: str) -> None:
        key = tuple(sorted(labels.items()))
        with self._lock:
            self._count[key] += 1
            self._sum[key] += value

    def render(self) -> list[str]:
        lines = [f"# HELP {self.name} {self.help}", f"# TYPE {self.name} summary"]
        for key in sorted(self._count):
            lines.append(f"{self.name}_count{_labels(dict(key))} {self._count[key]}")
            lines.append(f"{self.name}_sum{_labels(dict(key))} {round(self._sum[key], 6)}")
        return lines


HTTP_REQUESTS = Counter("devpilot_http_requests_total", "HTTP requests by method, route and status.")
HTTP_LATENCY = Summary("devpilot_http_request_seconds", "HTTP request duration by method and route.")
EVENTS = Counter("devpilot_mission_events_total", "Mission events published, by kind.")
TOOL_CALLS = Counter("devpilot_tool_calls_total", "Governed tool calls, by tool and outcome.")
LLM_TOKENS = Counter("devpilot_llm_tokens_total", "LLM tokens used, by caller.")
LLM_CALLS = Counter("devpilot_llm_calls_total", "LLM calls, by provider and result.")
RATE_LIMITED = Counter("devpilot_rate_limited_total", "Requests refused by rate limits, by scope.")
AUTH_FAILURES = Counter("devpilot_auth_failures_total", "Failed authentications, by reason.")

ALL = (HTTP_REQUESTS, HTTP_LATENCY, EVENTS, TOOL_CALLS, LLM_TOKENS, LLM_CALLS, RATE_LIMITED, AUTH_FAILURES)


def render() -> str:
    return "\n".join(line for metric in ALL for line in metric.render()) + "\n"
