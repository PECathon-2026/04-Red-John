"""Parse and format human-friendly durations such as "1h30m" or "45s"."""
from __future__ import annotations

import re

_PART = re.compile(r"(\d+)([hms])")
_WHOLE = re.compile(r"(\d+[hms])+")
_UNITS = {"h": 3600, "m": 3600, "s": 1}


def parse_duration(text: str) -> int:
    """Return the number of seconds in a duration like "2h", "1h30m" or "90s"."""
    cleaned = text.strip().lower()
    if not cleaned or not _WHOLE.fullmatch(cleaned):
        raise ValueError(f"invalid duration: {text!r}")
    return sum(int(number) * _UNITS[unit] for number, unit in _PART.findall(cleaned))


def format_duration(seconds: int) -> str:
    """Inverse of parse_duration: 5400 -> "1h30m", 0 -> "0s"."""
    if seconds < 0:
        raise ValueError("seconds cannot be negative")
    hours, rest = divmod(seconds, 3600)
    minutes, secs = divmod(rest, 60)
    parts = [f"{hours}h" if hours else "", f"{minutes}m" if minutes else "", f"{secs}s" if secs else ""]
    return "".join(parts) or "0s"
