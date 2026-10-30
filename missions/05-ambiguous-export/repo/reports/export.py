"""CSV export for the monthly sales report."""
from __future__ import annotations

COLUMNS = ("region", "product", "units", "revenue")


def export_csv(rows: list[dict]) -> str:
    """Turn report rows into CSV text, one line per row."""
    lines = []
    for row in rows:
        lines.append(",".join(str(row.get(column, "")) for column in COLUMNS))
    return "\n".join(lines)
