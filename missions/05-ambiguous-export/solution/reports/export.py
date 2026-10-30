"""CSV export for the monthly sales report."""
from __future__ import annotations

import csv
import io

COLUMNS = ("region", "product", "units", "revenue")


def export_csv(rows: list[dict]) -> str:
    """Turn report rows into CSV text: a header row, then one line per row, quoted where needed."""
    buffer = io.StringIO()
    writer = csv.writer(buffer, lineterminator="\n")
    writer.writerow(COLUMNS)
    for row in rows:
        writer.writerow([row.get(column, "") for column in COLUMNS])
    return buffer.getvalue().rstrip("\n")
