"""Shopping cart for the storefront checkout."""
from __future__ import annotations

from dataclasses import dataclass, field


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
