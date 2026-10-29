# DevPilot — Architecture Plan

> **Superseded.** This was the original plan. The system as built is described in [ARCHITECTURE.md](ARCHITECTURE.md); it differs in places (e.g. Atlas is a rule-based orchestrator, Scribe is optional, and the backend lives in `backend_main/`).

> PS-001 · *Plan like a Shogun. Build like a Samurai. Test like a Sentinel. Adapt until the mission is complete.*
>
> DevPilot turns a natural-language request into a working, tested, reviewed change on a small local repository.
> It reuses Mycel's hierarchy (Atlas orchestrates, Maya hires), Mycel's control-room frontend, and Jarvis's tools and safety policy.

---

## 1. What we carry over

| Source | What we reuse | What changes |
|---|---|---|
| **Mycel backend** | `core/groq_engine.py` (Groq key pool + failover), `core/events.py` (event publisher → WebSocket), `core/approval_gate.py` (GREEN / AMBER / RED gate + human approval), `api/v1/routes/realtime/*` (WS + approvals), auth, Maya's `query_available_agents` / `hire_team` tools, `autonomy/loop_detector.py` idea | Supply-chain teams are replaced. Maya hires **during** the mission, not just once. The fixed 4-phase `MasterOrchestrator` becomes an event-driven loop. |
| **Mycel frontend** | Control room, pixel office, Atlas log, hire cards, agent roster, approval modal, `mission-sim.ts` WebSocket state | Setup wizard becomes a **Mission Intake** (repo + request). Blueprint tab becomes a **Mission Board** (tasks, diffs, test evidence, review findings). Roster in `lib/agents.ts` becomes the DevPilot guild. |
| **Jarvis** | `tools/fs.py` (read / edit / write / list / find / search), `tools/shell.py` (run with timeout, failure summaries), `safety/policy.py` (risk levels, destructive-binary detection, git danger list), `tools/registry.py` (schema-checked tool calls with argument repair) | Ported to Windows + Linux, and every path is jailed to the mission workspace. macOS, voice, media and PIM tools are dropped. |

## 2. The Guild — 2 core agents + 4 teams (16 agents)

Every agent has a **skill set** (what Maya matches on) and a **tool grant** (what the registry lets it call).
Maya only hires the agents the mission needs, and can hire more mid-mission when new evidence demands it.

### Executive (always on)
| Agent | Role | Skills | Tools |
|---|---|---|---|
| **Atlas** | Mission Orchestrator (the Shogun) | orchestration, replanning, escalation | `mission_state`, `assign_task`, `request_hire`, `ask_human`, `stop_mission` |
| **Maya** | Guild HR / Hiring Engine | capability matching | `query_available_agents`, `hire_agent`, `release_agent` |

### A · Shogun's Council — Planning
| Agent | Role | Skills | Tools |
|---|---|---|---|
| **Kenji** | Requirements Analyst | requirement analysis, acceptance criteria, ambiguity detection | `read_file`, `search_text`, `ask_clarification` |
| **Hana** | Codebase Scout | repo reconnaissance, conventions, test-command discovery, risk spotting | `list_dir`, `find_files`, `search_text`, `read_file`, `git_log` |
| **Ryo** | Task Planner | decomposition, dependency DAG, replanning on blockers | `mission_state`, `write_plan` |

### B · Samurai Forge — Implementation
| Agent | Role | Skills | Tools |
|---|---|---|---|
| **Takeshi** | Backend Engineer | Python, APIs, data logic | read / search / `edit_file` / `write_file` / `run_command` |
| **Yuki** | Frontend Engineer | JS / TS, React, HTML / CSS | same as Takeshi |
| **Daichi** | Debugger | failure triage, stack traces, root-cause analysis | read / search / `run_command` / `edit_file` |
| **Sora** | Refactor & Style Keeper | idiomatic code, project conventions, lint fixes | read / search / `edit_file` / `run_lint` |

### C · Sentinel Dojo — Testing & Verification
| Agent | Role | Skills | Tools |
|---|---|---|---|
| **Aiko** | Test Runner | running tests / build / lint, parsing results | `run_tests`, `run_lint`, `run_build` |
| **Riku** | Test Author | writing regression and feature tests | read / search / `write_file` / `run_tests` |
| **Mei** | Independent Verifier | checks acceptance criteria against **evidence only**, read-only | `read_file`, `git_diff`, `run_tests` |

### D · Shadow Council — Review & Security
| Agent | Role | Skills | Tools |
|---|---|---|---|
| **Haruto** | Code Reviewer | correctness, readability, consistency, regressions | `git_diff`, `read_file`, `search_text` |
| **Kaito** | Security Inspector | secrets, injection, unsafe operations | `secret_scan`, `static_scan`, `git_diff`, `read_file` |
| **Emi** | Arbiter | settles developer vs reviewer disputes by evidence, else escalates to a human | `mission_state`, `run_tests`, `ask_human` |

### Support
| Agent | Role |
|---|---|
| **Scribe** | Writes the run log and final evidence report (what changed, what passed, what is unresolved, verified vs. claimed) |

## 3. How a mission runs (not a fixed pipeline)

```
 User request + repo ─► Atlas opens Mission ─► Maya hires Kenji + Hana
                                                   │
         ┌─────────────────── Shared Mission State (blackboard) ───────────────────┐
         │ objectives · acceptance criteria · tasks(DAG) · findings · decisions ·   │
         │ open issues · tool calls · test runs (with real output) · diffs · budget │
         └──────────────────────────────────────────────────────────────────────────┘
              ▲ read/write            ▲ messages (finding / handoff / critique)
   ┌──────────┴─────────┐   ┌────────┴────────┐   ┌──────────────┐   ┌─────────────┐
   │ Planning (Kenji,   │──►│ Forge (devs)    │──►│ Sentinel     │──►│ Shadow      │
   │ Hana, Ryo)         │   │                 │◄──│ (Aiko, Mei)  │◄──│ (Haruto,    │
   └────────────────────┘   └─────────────────┘   └──────────────┘   │ Kaito, Emi) │
            ▲                        ▲  test failure → Daichi hired   └─────┬───────┘
            └──── replan on blocker ─┴──── review / security finding ──────┘
                                                   │
                       Mei verifies ACs ─► Scribe report ─► HUMAN APPROVAL ─► apply to repo
```

Atlas runs a loop: **observe state → choose next action → (Maya hires if no agent has the skill) → agent works → results land on the blackboard → Atlas re-evaluates.** Choices are `continue`, `retry`, `reassign`, `replan`, `ask_clarification`, `escalate`, `stop`.

Feedback loops required by the PS:
- **Test failure** → Aiko posts the real failure output → Atlas routes it to the developer (or Maya hires Daichi after 2 failed fixes) → re-run.
- **Review / security finding** → Haruto or Kaito posts a critique to the developer → fix → re-review. If the developer disputes it, Emi decides from evidence or escalates to a human.
- **New recon evidence** (for example, Hana finds there is no test runner) → Ryo replans.

## 4. Bounded autonomy and safety

- **Workspace jail:** each mission works on a copy (git worktree) of the target repo. Every path is resolved and must stay inside it.
- **Command policy** (from Jarvis `safety/policy.py`): allowlisted test / lint / build runners; `rm`, `del`, `format`, `git push/reset/clean`, network tools, `sudo` and installs are blocked. Every tool call is classified GREEN / AMBER / RED (Mycel's gate).
- **Limits:** max iterations per agent, max fix attempts per task, global tool-call and token budget, wall-clock timeout. A loop detector stops repeated identical failures.
- **Human approval (AMBER):** applying the change to the real repo, adding dependencies, and unresolved disputes.
- **Evidence-based completion:** a criterion is only "met" when it is linked to a real test run or diff. The report separates **verified** from **claimed**.

## 5. Infrastructure (lean, for the hackathon)

- **Backend:** FastAPI + WebSocket (Mycel). New package `backend/devpilot/` holds the guild, tools, mission state and orchestrator. Existing Mycel-only code (supply chain, real estate, creative) is left out of the import path.
- **LLM:** Groq pool (existing `GROQ_EXTREME_POOL`) with Gemini fallback.
- **State:** in-process event bus (asyncio) instead of RabbitMQ. MongoDB is optional; missions also persist to a local JSON run log so the demo works offline.
- **Demo repos:** `missions/` holds five small seeded repos for the PS scenarios: feature, seeded bug, failing test, planted vulnerability, ambiguous request / unavailable tool.

## 6. Build order

1. Tool layer: port Jarvis fs / shell / policy with workspace jail, plus `git_diff`, `run_tests`, `secret_scan`.
2. Mission state + event bus + agent base (tool loop, messages, budgets).
3. Guild registry (16 agents) + Maya's dynamic hiring.
4. Atlas orchestrator loop + feedback loops + approval gate.
5. Demo repos + an end-to-end run log with a feedback loop.
6. Frontend: Mission Intake, roster, Mission Board, live log, approval modal.
7. README (architecture diagram, tools, boundaries, setup) + single-agent baseline comparison (bonus).
