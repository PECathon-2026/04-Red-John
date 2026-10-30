"""
Mission endpoints: create, run and inspect missions, read the board (messages,
evidence), answer clarification questions, and stop a mission.
"""
from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Query, Request, status
from fastapi.responses import PlainTextResponse
from pydantic import BaseModel, Field

from app.api.deps import ApproverDep, ContainerDep, OperatorDep, ViewerDep
from app.core import metrics
from app.core.errors import ConflictError, RateLimited
from app.domain.governance import ApprovalStatus
from app.domain.mission import MissionStatus
from app.services.snapshot import build_snapshot

router = APIRouter(tags=["missions"])


class CreateMission(BaseModel):
    request: str = Field(min_length=3, max_length=20_000, description="What should be built or fixed, in plain language")
    repo_path: str = Field(min_length=1, description="Local path of the repository to work on")
    title: str | None = Field(default=None, max_length=200)
    start: bool = Field(default=False, description="Start the guild on the mission right away")


class ResolveIssue(BaseModel):
    resolution: str = Field(min_length=1, max_length=5000)


class StopMission(BaseModel):
    reason: str = Field(default="stopped by operator", max_length=1000)


@router.post("/missions", status_code=status.HTTP_201_CREATED)
async def create_mission(body: CreateMission, user: OperatorDep, container: ContainerDep) -> dict[str, Any]:
    settings = container.settings
    if settings.rate_limit_enabled:
        allowed, retry = await container.rate_limiter.hit(f"missions:{user.user_id}", settings.mission_rate_limit_per_minute)
        if not allowed:
            metrics.RATE_LIMITED.inc(scope="missions")
            raise RateLimited("Too many missions created; try again shortly", details={"retry_after_s": retry})
    mission = await container.board.create_mission(body.request, body.repo_path, title=body.title,
                                                   created_by=user.username)
    if body.start:
        await container.runner.start(mission.mission_id)
    return {"mission": mission.model_dump(mode="json"), "running": body.start,
            "stream": f"{container.settings.api_prefix}/realtime/missions/{mission.mission_id}"}


@router.post("/projects/create", status_code=status.HTTP_201_CREATED, include_in_schema=False)
async def create_project_compat(request: Request, container: ContainerDep) -> dict[str, Any]:
    """Compatibility endpoint for setup wizard calling /projects/create."""
    try:
        data = await request.json()
    except Exception:
        data = {}
    title = data.get("title") or data.get("productDescription") or "DevPilot Mission"
    req_text = data.get("request") or data.get("priorities") or data.get("productDescription") or "Autonomous development mission"
    repo_path = data.get("repo_path") or "missions/01-feature-discounts/repo"
    start = bool(data.get("start", True))
    mission = await container.board.create_mission(str(req_text), str(repo_path), title=str(title)[:200])
    if start:
        await container.runner.start(mission.mission_id)
    return {
        "project_id": mission.mission_id,
        "mission_id": mission.mission_id,
        "status": "created",
        "mission": mission.model_dump(mode="json"),
        "running": start,
    }


@router.get("/projects/{project_id}", include_in_schema=False)
async def get_project_compat(project_id: str, container: ContainerDep) -> dict[str, Any]:
    mission = await container.board.get(project_id)
    return {"project_id": mission.mission_id, "mission": mission.model_dump(mode="json"), "progress": mission.progress()}


@router.get("/missions")
async def list_missions(
    _: ViewerDep, container: ContainerDep, status: MissionStatus | None = None,
    limit: int = Query(50, ge=1, le=200),
) -> dict[str, Any]:
    missions = await container.board.list(status=status, limit=limit)
    return {"missions": [
        {"mission_id": m.mission_id, "title": m.title, "status": m.status, "created_at": m.created_at,
         "updated_at": m.updated_at, "progress": m.progress()}
        for m in missions
    ]}


@router.get("/missions/{mission_id}")
async def get_mission(mission_id: str, _: ViewerDep, container: ContainerDep) -> dict[str, Any]:
    mission = await container.board.get(mission_id)
    return {"mission": mission.model_dump(mode="json"), "progress": mission.progress(),
            "ready_tasks": [t.id for t in mission.ready_tasks()]}


@router.get("/missions/{mission_id}/snapshot")
@router.get("/realtime/snapshot/{mission_id}", include_in_schema=False)  # Mycel control-room path
async def mission_snapshot(mission_id: str, _: ViewerDep, container: ContainerDep) -> dict[str, Any]:
    mission = await container.board.get(mission_id)
    events = await container.storage.events.list(mission_id)
    pending = await container.storage.approvals.list(mission_id, status=ApprovalStatus.PENDING)
    evidence = await container.board.evidence(mission_id)
    return build_snapshot(mission, events, pending, evidence)


@router.get("/missions/{mission_id}/messages")
async def mission_messages(
    mission_id: str, _: ViewerDep, container: ContainerDep, agent: str | None = None,
    after_seq: int = 0, limit: int = Query(500, ge=1, le=2000),
) -> dict[str, Any]:
    await container.board.get(mission_id)
    if agent:
        messages = await container.board.inbox(mission_id, agent, after_seq=after_seq, limit=limit)
    else:
        messages = await container.board.messages(mission_id, after_seq=after_seq, limit=limit)
    return {"mission_id": mission_id, "messages": [m.model_dump(mode="json") for m in messages]}


@router.get("/missions/{mission_id}/evidence")
async def mission_evidence(
    mission_id: str, _: ViewerDep, container: ContainerDep, kind: str | None = None, task_id: str | None = None
) -> dict[str, Any]:
    await container.board.get(mission_id)
    evidence = await container.board.evidence(mission_id, kind=kind, task_id=task_id)
    return {"mission_id": mission_id, "evidence": [e.model_dump(mode="json") for e in evidence]}


@router.post("/missions/{mission_id}/issues/{issue_id}/resolve")
async def resolve_issue(
    mission_id: str, issue_id: str, body: ResolveIssue, user: OperatorDep, container: ContainerDep
) -> dict[str, Any]:
    """A human answers a clarification question or settles a dispute."""
    issue = await container.board.resolve_issue(mission_id, issue_id, by=user.username, resolution=body.resolution)
    mission = await container.board.get(mission_id)
    resumed = False
    if (mission.status == MissionStatus.AWAITING_HUMAN and not any(i.needs_human for i in mission.open_issues)
            and not await container.runner.is_running(mission_id)):
        await container.runner.start(mission_id)  # every question answered: Atlas picks the mission back up
        resumed = True
    return {"issue": issue.model_dump(mode="json"), "resumed": resumed}


@router.post("/missions/{mission_id}/run", status_code=status.HTTP_202_ACCEPTED)
async def run_mission(mission_id: str, _: OperatorDep, container: ContainerDep) -> dict[str, Any]:
    """Start (or resume) the guild on a mission. Returns at once; follow progress on the event stream."""
    mission = await container.board.get(mission_id)
    if mission.is_terminal:
        raise ConflictError(f"Mission {mission_id} is {mission.status}")
    await container.runner.start(mission_id)
    return {"mission_id": mission_id, "running": True, "mode": container.settings.execution_mode}


@router.get("/missions/{mission_id}/patch", response_class=PlainTextResponse)
async def mission_patch(mission_id: str, _: ViewerDep, container: ContainerDep) -> str:
    """The mission's full change as a unified diff — what a human reviews before approving the apply."""
    return await container.apply.patch(mission_id)


@router.post("/missions/{mission_id}/apply", status_code=status.HTTP_202_ACCEPTED)
async def request_apply(mission_id: str, user: OperatorDep, container: ContainerDep) -> dict[str, Any]:
    """Ask to apply a completed mission to the real repository. A human must approve it
    (POST /approvals/{approval_id}/respond); only then are files written."""
    approval = await container.apply.request(mission_id, by=user.username)
    return {"approval": approval.model_dump(mode="json"),
            "respond": f"{container.settings.api_prefix}/approvals/{approval.approval_id}/respond"}


@router.post("/missions/{mission_id}/stop")
async def stop_mission(mission_id: str, body: StopMission, user: OperatorDep, container: ContainerDep) -> dict[str, Any]:
    mission = await container.board.set_status(mission_id, MissionStatus.STOPPED, by=user.username, reason=body.reason)
    expired = await container.approvals.expire_pending(mission_id, body.reason)
    return {"mission": mission.model_dump(mode="json"), "expired_approvals": expired}
