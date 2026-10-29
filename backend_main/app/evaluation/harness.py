"""
Evaluation harness: run a scenario with the guild or the single-agent baseline, judge the result with
the hidden checks, and export a run log (JSON + Markdown) with the metrics PS-001 asks about.

When a guild mission pauses for a human, the harness answers clarification questions with the
scenario's `clarification_answer` — standing in for the person who made the request — and records
that it did so. Any other human escalation is left unanswered and ends the run.
"""
from __future__ import annotations

import json
import time
from collections import Counter
from pathlib import Path
from typing import Any

from pydantic import BaseModel, Field

from app.container import Container
from app.domain.agents import AgentRunResult, RunStatus
from app.domain.events import EventKind
from app.domain.mission import CriterionStatus, DecisionType, IssueKind, Mission, MissionStatus
from app.evaluation.baseline import SOLO
from app.evaluation.scenarios import CheckResult, Scenario, run_hidden_checks

HUMAN = "human (scenario answer, via the evaluation harness)"


class RunResult(BaseModel):
    scenario: str
    mode: str                       # guild | baseline
    mission_id: str
    outcome: str                    # guild: mission status; baseline: the agent's own verdict
    claimed_success: bool           # what the system says about itself
    hidden: CheckResult             # what independent checks say
    metrics: dict[str, Any] = Field(default_factory=dict)
    human_answers: list[str] = Field(default_factory=list)
    reason: str | None = None

    @property
    def verified_success(self) -> bool:
        return self.claimed_success and self.hidden.passed


def _tokens(container: Container) -> int:
    return container.llm.ledger.total_tokens


async def _metrics(container: Container, mission: Mission, started: float, tokens_before: int) -> dict[str, Any]:
    audit = await container.storage.audit.list(mission.mission_id, limit=5000)
    decisions = Counter(d.decision for d in mission.decisions)
    evidence = await container.board.evidence(mission.mission_id)
    runs = [e for e in evidence if e.kind == "test_run"]
    return {
        "duration_s": round(time.monotonic() - started, 1),
        "llm_tokens": _tokens(container) - tokens_before,
        "tool_calls": len(audit),
        "tool_outcomes": dict(Counter(str(a.outcome) for a in audit)),
        "agents": [h.agent for h in mission.hires] or sorted({a.agent for a in audit}),
        "tasks": len(mission.tasks),
        "feedback_loops": decisions.get(DecisionType.REPLAN, 0),
        "reassignments": decisions.get(DecisionType.REASSIGN, 0),
        "retries": decisions.get(DecisionType.RETRY, 0),
        "escalations": decisions.get(DecisionType.ESCALATE, 0),
        "clarifications": decisions.get(DecisionType.CLARIFY, 0),
        "messages": len(await container.board.messages(mission.mission_id)),
        "test_runs": len(runs),
        "test_runs_failed": sum(1 for e in runs if e.passed is False),
        "criteria_met": sum(1 for c in mission.acceptance_criteria if c.status == CriterionStatus.MET),
        "criteria_total": len(mission.acceptance_criteria),
        "findings": len(mission.findings),
    }


async def run_guild(container: Container, scenario: Scenario, *, max_answers: int = 2) -> RunResult:
    started, tokens_before = time.monotonic(), _tokens(container)
    mission = await container.board.create_mission(scenario.request, str(scenario.repo_dir), title=scenario.title)
    mid, answers = mission.mission_id, []
    while True:
        final = await container.orchestrator.run(mid)
        if final.status != MissionStatus.AWAITING_HUMAN or len(answers) >= max_answers:
            break
        questions = [i for i in final.open_issues if i.needs_human]
        clarifications = [i for i in questions if i.kind == IssueKind.CLARIFICATION]
        if not scenario.clarification_answer or not clarifications or len(clarifications) < len(questions):
            break  # an escalation (not a question about the request): a real human would have to step in
        for issue in clarifications:
            await container.board.resolve_issue(mid, issue.id, by=HUMAN, resolution=scenario.clarification_answer)
            answers.append(issue.text)
    workspace = container.workspaces.get(mid).root
    return RunResult(
        scenario=scenario.id, mode="guild", mission_id=mid, outcome=str(final.status),
        claimed_success=final.status == MissionStatus.COMPLETED, hidden=run_hidden_checks(scenario, workspace),
        metrics=await _metrics(container, final, started, tokens_before), human_answers=answers,
        reason=final.status_reason)


async def run_baseline(container: Container, scenario: Scenario) -> RunResult:
    started, tokens_before = time.monotonic(), _tokens(container)
    mission = await container.board.create_mission(scenario.request, str(scenario.repo_dir),
                                                   title=f"[baseline] {scenario.title}")
    mid = mission.mission_id
    governor = container.governor(mid)
    result: AgentRunResult = await container.runtime.run(SOLO, mid, governor,
                                                         instructions="You are working alone on this request.")
    await container.board.set_status(mid, MissionStatus.STOPPED, by="harness", reason="baseline run finished")
    final = await container.board.get(mid)
    workspace = container.workspaces.get(mid).root
    metrics = await _metrics(container, final, started, tokens_before)
    metrics["agents"] = ["Solo"]
    return RunResult(
        scenario=scenario.id, mode="baseline", mission_id=mid, outcome=str(result.status),
        claimed_success=result.status == RunStatus.DONE, hidden=run_hidden_checks(scenario, workspace),
        metrics=metrics, reason=result.stop_reason or result.summary[:300])


# ── export ─────────────────────────────────────────────────────────────────
async def export_run(container: Container, scenario: Scenario, result: RunResult, out_dir: Path) -> Path:
    """Write run.json (everything recorded) and run.md (readable run log) for one run."""
    out = out_dir / f"{scenario.id}-{result.mode}"
    out.mkdir(parents=True, exist_ok=True)
    mid = result.mission_id
    mission = await container.board.get(mid)
    events = await container.storage.events.list(mid)
    record = {
        "result": result.model_dump(mode="json") | {"verified_success": result.verified_success},
        "scenario": scenario.model_dump(mode="json", exclude={"root"}),
        "mission": mission.model_dump(mode="json"),
        "events": [e.model_dump(mode="json") for e in events],
        "audit": [a.model_dump(mode="json") for a in await container.storage.audit.list(mid, limit=5000)],
        "evidence": [e.model_dump(mode="json") for e in await container.board.evidence(mid)],
        "messages": [m.model_dump(mode="json") for m in await container.board.messages(mid)],
    }
    (out / "run.json").write_text(json.dumps(record, indent=1, default=str), encoding="utf-8")

    m = result.metrics
    lines = [
        f"# {scenario.title} — {result.mode}",
        "",
        f"**PS scenario:** {scenario.ps_scenario}",
        "",
        f"**Request:** {scenario.request}",
        "",
        "| | |",
        "|---|---|",
        f"| Outcome reported by the system | `{result.outcome}`{f' — {result.reason}' if result.reason else ''} |",
        f"| Hidden acceptance checks (independent) | **{'PASS' if result.hidden.passed else 'FAIL'}** "
        f"({result.hidden.tests_passed} passed, {result.hidden.tests_failed} failed) |",
        f"| Verified success (claimed and checked) | **{'yes' if result.verified_success else 'no'}** |",
        f"| Duration · LLM tokens · tool calls | {m.get('duration_s')}s · {m.get('llm_tokens'):,} · {m.get('tool_calls')} |",
        f"| Agents | {', '.join(m.get('agents', []))} |",
        f"| Feedback loops · reassignments · retries · escalations · clarifications | "
        f"{m.get('feedback_loops')} · {m.get('reassignments')} · {m.get('retries')} · {m.get('escalations')} · "
        f"{m.get('clarifications')} |",
        f"| Test runs (failed) · criteria met | {m.get('test_runs')} ({m.get('test_runs_failed')}) · "
        f"{m.get('criteria_met')}/{m.get('criteria_total')} |",
    ]
    if result.human_answers:
        lines += ["", "## Human answers (given by the harness from scenario.json)", ""]
        lines += [f"- Q: {q}\n  A: {scenario.clarification_answer}" for q in result.human_answers]
    lines += ["", "## Timeline", "", "```"]
    for event in events:
        if event.kind == EventKind.LOG:
            seconds = (event.at - mission.created_at) / 1000
            lines.append(f"{seconds:7.1f}s [{event.data.get('level', 'info'):7}] {str(event.data.get('text', ''))[:260]}")
    lines += ["```", "", "## Hidden check output (tail)", "", "```", result.hidden.output_tail.strip()[-1500:], "```"]
    if mission.report:
        lines += ["", "---", "", mission.report]
    (out / "run.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    return out
