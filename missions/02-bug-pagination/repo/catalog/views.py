"""Catalog listing used by the storefront."""
from __future__ import annotations

from catalog.pagination import page_count, paginate

PER_PAGE = 3


def listing(products: list[str], page: int) -> dict:
    """What the storefront renders for one page of the catalog."""
    return {
        "page": page,
        "pages": page_count(len(products), PER_PAGE),
        "products": paginate(products, page, PER_PAGE),
    }
