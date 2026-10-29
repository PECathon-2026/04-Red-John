"""
Activity Ingestion Router
Accepts bulk activity log entries from agents, the monitor, or any internal subsystem
and persists them to MongoDB for later querying / audit trails.

POST /api/activity/ingest/bulk  — batch-ingest activity records
GET  /api/activity              — list recent activity (optional filters)
"""

from __future__ import annotations

import datetime
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field

from core.mongodb import mongodb_connection
from core.logger import logger

router = APIRouter()

COLLECTION = "activity_logs"


# ──────────────────────────────────────────────
# Schema
# ──────────────────────────────────────────────

class ActivityEntry(BaseModel):
    """A single activity record emitted by an agent or subsystem."""

    # Who / what produced this entry
    source: str = Field(..., description="Originator: agent_id, team slug, or subsystem name")
    actor: Optional[str] = Field(None, description="Human-readable actor name (e.g. 'Ravi', 'Monitor')")

    # What happened
    event_type: str = Field(..., description="Short event type slug (e.g. 'tool_call', 'status_update', 'alert')")
    summary: str = Field(..., description="One-line human-readable description of the activity")

    # Optional context
    project_id: Optional[str] = None
    session_id: Optional[str] = None
    payload: Optional[Dict[str, Any]] = Field(default_factory=dict, description="Arbitrary structured context")

    # Timestamp — client-supplied; falls back to server time if omitted
    timestamp: Optional[datetime.datetime] = None


class BulkIngestRequest(BaseModel):
    entries: List[ActivityEntry] = Field(..., min_length=1, max_length=500)


class BulkIngestResponse(BaseModel):
    accepted: int
    rejected: int
    message: str


# ──────────────────────────────────────────────
# Routes
# ──────────────────────────────────────────────

@router.post("/ingest/bulk", response_model=BulkIngestResponse)
async def bulk_ingest_activity(body: BulkIngestRequest):
    """
    Batch-ingest activity log entries.

    Accepts up to 500 entries per call.  Each entry is stamped with the
    server-side received_at time and written to the ``activity_logs`` collection.
    Unknown / extra fields in the payload dict are preserved as-is.
    """
    db = mongodb_connection.db
    if db is None:
        raise HTTPException(status_code=503, detail="Database not available")

    now = datetime.datetime.utcnow()
    docs: List[Dict[str, Any]] = []

    for entry in body.entries:
        docs.append({
            "source": entry.source,
            "actor": entry.actor,
            "event_type": entry.event_type,
            "summary": entry.summary,
            "project_id": entry.project_id,
            "session_id": entry.session_id,
            "payload": entry.payload or {},
            "timestamp": entry.timestamp or now,
            "received_at": now,
        })

    accepted = 0
    rejected = 0

    try:
        if docs:
            result = await db[COLLECTION].insert_many(docs, ordered=False)
            accepted = len(result.inserted_ids)
            rejected = len(docs) - accepted
    except Exception as exc:
        logger.error(f"activity/ingest/bulk: partial failure — {exc}")
        # Best-effort: report what we know
        rejected = len(docs)

    logger.info(f"activity/ingest/bulk: accepted={accepted} rejected={rejected}")

    return BulkIngestResponse(
        accepted=accepted,
        rejected=rejected,
        message=f"Ingested {accepted} of {len(docs)} activity entries.",
    )


@router.get("")
async def list_activity(
    project_id: Optional[str] = Query(None),
    source: Optional[str] = Query(None),
    event_type: Optional[str] = Query(None),
    limit: int = Query(50, ge=1, le=500),
):
    """
    Return recent activity log entries, newest first.
    Supports optional filtering by project_id, source, and event_type.
    """
    db = mongodb_connection.db
    if db is None:
        raise HTTPException(status_code=503, detail="Database not available")

    query: Dict[str, Any] = {}
    if project_id:
        query["project_id"] = project_id
    if source:
        query["source"] = source
    if event_type:
        query["event_type"] = event_type

    cursor = db[COLLECTION].find(query, {"_id": 0}).sort("received_at", -1).limit(limit)
    entries = await cursor.to_list(length=limit)
    return {"entries": entries, "count": len(entries)}
