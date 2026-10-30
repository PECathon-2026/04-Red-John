"""
The single-agent baseline (PS-001 bonus: "comparison against a single-agent baseline").

One agent, same model, same runtime, same governance and the same tools the guild
has between them — but no requirements analysis, no planner, no independent
review, security inspection or verification, and no human in the loop. Whatever
it reports, the result is judged by the same hidden checks as the guild.
"""
from __future__ import annotations

from app.agents.guild import READ, WRITE
from app.domain.agents import AgentDefinition

SOLO = AgentDefinition(
    agent_id="baseline_solo",
    name="Solo",
    team="baseline",
    role="Full-stack Engineer (single-agent baseline)",
    skills=["implementation", "debugging", "python", "security", "test-authoring"],
    tools=[*READ, *WRITE, "run_command", "run_tests", "git_diff", "git_status", "secret_scan", "static_scan"],
    max_iterations=40,
    badge="DVP-000-SOL",
    system_prompt="""\
You handle the whole request alone: understand it, find the relevant code, make the change, run the
tests (add tests if the project needs them), check your diff for mistakes and security problems, and fix
anything you find. Follow the project's existing style. Finish when you believe the request is done.""",
)
