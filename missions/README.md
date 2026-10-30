# DevPilot evaluation scenarios

One small, realistic repository per PS-001 evaluation scenario. Each folder holds:

| Path | Who sees it | Purpose |
|---|---|---|
| `repo/` | the agents | the project to change — a mission's workspace is a copy of this folder |
| `scenario.json` | the harness | the request, the human's answer if the request is ambiguous, what success looks like |
| `checks/` | **only the harness** | hidden acceptance tests, run against the mission workspace after the run |
| `solution/` | only the tests | a reference fix, used to prove the hidden checks fail on the seeded repo and pass on a correct fix |

The hidden checks are the honest measure: they are not in the repository, so no agent can read, run, weaken or "satisfy" them. A run counts as a **verified success** only when the system says it succeeded *and* the hidden checks pass.

| Scenario | PS-001 case | What is planted |
|---|---|---|
| `01-feature-discounts` | Feature implementation | A cart without discounts; add `apply_discount()` / `total()` without changing `subtotal()` |
| `02-bug-pagination` | Bug investigation | An off-by-one that repeats the last item of each page; the existing tests do **not** catch it |
| `03-failing-test-durations` | Test-driven recovery | Minutes parsed as hours; two tests fail; the fix must not touch the tests |
| `04-vulnerability-accounts` | Security & code review | SQL built with an f-string and a hard-coded API token |
| `05-ambiguous-export` | Unexpected condition: ambiguity | "Make the export better" — the hidden checks encode the human's answer, so guessing fails |
| `06-no-tests-temperature` | Unexpected condition: unavailable tool | A conversion bug in a project with no test runner at all |

## Running them

```bash
cd backend_main
python -m app.evaluation --mode both --out ../docs/runs/my-eval          # all scenarios, guild + single-agent baseline
python -m app.evaluation --scenario 02-bug-pagination --mode guild
```

Each run writes `run.json` (mission, events, audit trail, evidence, agent messages) and `run.md` (outcome, hidden-check result, metrics, timeline, evidence report), plus a `summary.json` for the whole evaluation. `tests/test_evaluation.py` checks the scenarios themselves and the harness.
