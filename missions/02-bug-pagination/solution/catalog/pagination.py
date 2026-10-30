"""Paging helpers for the product catalog."""
from __future__ import annotations

from collections.abc import Sequence
from typing import TypeVar

T = TypeVar("T")


def page_count(total: int, per_page: int) -> int:
    """Number of pages needed to show `total` items, at least one."""
    if per_page < 1:
        raise ValueError("per_page must be at least 1")
    return max(1, -(-total // per_page))


def paginate(items: Sequence[T], page: int, per_page: int) -> list[T]:
    """Return the items shown on `page` (1-based), `per_page` items per page."""
    if page < 1 or per_page < 1:
        raise ValueError("page and per_page must be at least 1")
    start = (page - 1) * per_page
    end = start + per_page
    return list(items[start:end])
