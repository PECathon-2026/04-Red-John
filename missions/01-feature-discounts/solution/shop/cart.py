"""Shopping cart for the storefront checkout."""
from __future__ import annotations

from dataclasses import dataclass, field

DISCOUNTS = {"SAVE10": ("percent", 10), "FLAT5": ("flat", 5.0)}


@dataclass
class LineItem:
    sku: str
    unit_price: float
    quantity: int = 1

    @property
    def total(self) -> float:
        return round(self.unit_price * self.quantity, 2)


@dataclass
class Cart:
    items: list[LineItem] = field(default_factory=list)
    discount_code: str | None = None

    def add(self, sku: str, unit_price: float, quantity: int = 1) -> LineItem:
        """Add a line to the cart. Quantity must be positive and the price non-negative."""
        if quantity < 1:
            raise ValueError("quantity must be at least 1")
        if unit_price < 0:
            raise ValueError("unit_price cannot be negative")
        item = LineItem(sku=sku, unit_price=unit_price, quantity=quantity)
        self.items.append(item)
        return item

    def subtotal(self) -> float:
        """Sum of all line totals, before any discount."""
        return round(sum(item.total for item in self.items), 2)

    def apply_discount(self, code: str) -> None:
        if code not in DISCOUNTS:
            raise ValueError(f"unknown discount code: {code}")
        self.discount_code = code

    def total(self) -> float:
        subtotal = self.subtotal()
        if self.discount_code is None:
            return subtotal
        kind, amount = DISCOUNTS[self.discount_code]
        discounted = subtotal * (1 - amount / 100) if kind == "percent" else subtotal - amount
        return round(max(0.0, discounted), 2)
