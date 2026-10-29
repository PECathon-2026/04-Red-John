"""
Evaluation scenarios (PS-001 "Evaluation Scenarios"), one folder each under `missions/`:

    <id>/repo/        the project the agents work on (all they ever see)
    <id>/checks/      hidden acceptance tests, run by the harness after the mission
    <id>/solution/    a reference fix, used only to prove the hidden checks are right
    <id>/scenario.json  request, the human's answer if the request is ambiguous, expectations
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from pydantic import BaseModel


class Scenario(BaseModel):
    id: str
    title: str
    ps_scenario: str
    request: str
    clarification_answer: str | None = None
    expect: str = ""
    root: Path

    @property
    def repo_dir(self) -> Path:
        return self.root / "repo"

    @property
    def checks_dir(self) -> Path:
        return self.root / "checks"

    @property
    def solution_dir(self) -> Path:
        return self.root / "solution"


class CheckResult(BaseModel):
    passed: bool
    tests_passed: int
    tests_failed: int
    exit_code: int
    output_tail: str


def load_scenario(folder: Path) -> Scenario:
    data = json.loads((folder / "scenario.json").read_text(encoding="utf-8"))
    return Scenario(**data, root=folder.resolve())


def list_scenarios(missions_root: Path) -> list[Scenario]:
    return [load_scenario(p) for p in sorted(missions_root.iterdir()) if (p / "scenario.json").is_file()]


def run_hidden_checks(scenario: Scenario, code_dir: Path, timeout_s: int = 120) -> CheckResult:
    """Run the hidden acceptance tests against `code_dir` (a mission workspace, or any copy of the repo).
    The checks are copied to a temporary folder so nothing is written into the scenario or the code."""
    with tempfile.TemporaryDirectory(prefix="devpilot-checks-") as tmp:
        checks = Path(tmp) / "checks"
        shutil.copytree(scenario.checks_dir, checks)
        env = {**os.environ, "PYTHONPATH": str(code_dir), "PYTHONDONTWRITEBYTECODE": "1", "NO_COLOR": "1"}
        proc = subprocess.run(
            [sys.executable, "-m", "pytest", str(checks), "-q", "-p", "no:cacheprovider", "--rootdir", tmp,
             "-o", "addopts=", "--no-header", "-rfE"],
            cwd=code_dir, env=env, capture_output=True, text=True, encoding="utf-8", errors="replace",
            timeout=timeout_s, stdin=subprocess.DEVNULL,
        )
    from app.tools.builtin.commands import summarize_test_output

    output = (proc.stdout or "") + (proc.stderr or "")
    summary = summarize_test_output(output, proc.returncode)
    return CheckResult(passed=proc.returncode == 0, tests_passed=summary["passed"],
                       tests_failed=summary["failed"] + summary["errors"], exit_code=proc.returncode,
                       output_tail=output[-2000:])


def overlay(scenario: Scenario, destination: Path, *, with_solution: bool) -> Path:
    """A copy of the scenario repo (optionally with the reference solution on top), for checking the checks."""
    shutil.copytree(scenario.repo_dir, destination)
    if with_solution and scenario.solution_dir.is_dir():
        shutil.copytree(scenario.solution_dir, destination, dirs_exist_ok=True)
    return destination
