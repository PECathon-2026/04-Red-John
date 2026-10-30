# DevPilot Backend — Build Phases

`backend_main/` is the production backend for DevPilot. It is a new codebase: code from Mycel (`backend/`) and Jarvis (`jarvis/`) is **ported** into it and adapted, never imported at runtime. That keeps the old projects free to change or be deleted.

## Architecture rules (apply to every phase)

1. **Layers point inward.** `api` → `services` → `domain`. `infrastructure` implements interfaces declared next to the domain. Domain code never imports FastAPI, Mongo, Redis or an LLM SDK.
2. **Every external system sits behind an interface** with an in-memory implementation (local dev, tests) and a production one (MongoDB, Redis, a real LLM). The backend is picked in config, so one codebase runs as a single process on a laptop or as N API replicas plus M workers.
3. **The API is stateless.** Missions run in workers, events fan out over the bus, and approvals are stored, not held in a process-local dict. Any replica can serve any WebSocket.
4. **One composition root.** `app/container.py` builds every dependency once, at startup. Routes get them through `Depends`, and tests swap them out.
5. **Safe by construction.** Agents act only through the tool registry. The registry, not the model, decides whether a call runs, needs a human, or is refused.
6. **Evidence over claims.** Tool results that prove something (test runs, diffs, scans) are recorded as evidence with their real output.

```
backend_main/app/
├── main.py              app factory + lifespan
├── container.py         composition root (DI)
├── core/                config, logging, errors, ids, clock
├── api/v1/              HTTP + WebSocket routes, request/response schemas
├── domain/              pure models: events, mission, agents, evidence
├── services/            use cases: missions, hiring, orchestration       (Phase 4+)
├── agents/              agent runtime + guild definitions                (Phase 5+)
├── tools/               tool registry + built-in tools (fs, search, shell, git, tests, security)
├── security/            command/path policy, workspace sandbox, approval gate
└── infrastructure/      llm/ (providers + gateway), bus/ (memory, redis), storage/ (memory, mongo)
```

## Phases

| # | Phase | Delivers | Ported from |
|---|---|---|---|
| **0** | Foundation | Typed settings, structured logging, error model, app factory, lifespan, DI container, health and readiness probes, Dockerfile, docker-compose | Mycel `core/config.py`, `core/logger.py` |
| **1** | Infrastructure adapters | LLM gateway (OpenAI-compatible provider with key-pool rotation and cooldowns, Groq primary, Gemini fallback, concurrency limit, usage ledger). Event bus (in-memory, Redis pub/sub). Event store (in-memory, MongoDB). WebSocket stream with replay then live tail | Mycel `core/groq_engine.py`, `core/events.py`, `realtime/router.py` |
| **2** | Tooling and sandbox | Mission workspace (isolated copy of the target repo with a baseline git commit). Path jail. Command policy (argv only, no shell, allowlisted runners, destructive and network commands blocked, secrets scrubbed from env). Tool registry (schema-checked args with repair, risk assessment, timing, events). Tools: `read_file`, `write_file`, `edit_file`, `list_dir`, `find_files`, `search_text`, `run_command`, `run_tests`, `git_status`, `git_diff`, `git_log`, `secret_scan`, `static_scan` | Jarvis `tools/fs.py`, `tools/shell.py`, `tools/registry.py`, `safety/policy.py` |
| **3** | Governance | Approval gate (GREEN / AMBER / RED), stored approvals resolved over the bus so it works across replicas, timeouts that deny by default. Budgets (tool calls, tokens, wall clock). Loop detector for repeated identical failures. Audit trail of every tool call | Mycel `core/approval_gate.py`, `autonomy/loop_detector.py` |
| **4** | Mission core | Mission aggregate: objectives, acceptance criteria, task DAG, findings, decisions, open issues, evidence. Inter-agent messages (finding, handoff, critique, question). Mission repository (memory, Mongo). Snapshot reducer for the frontend | Mycel `realtime` snapshot reducer |
| **5** | Agent runtime | `Agent` base: tool-calling loop over the gateway, tool grants, per-agent iteration limits, structured outputs, inbox and outbox on the blackboard, status events for the pixel office | Mycel `teams/architecture/base.py` |
| **6** | Guild and hiring | Agent registry (16 definitions: skills, tool grants, prompts). Maya: deterministic skill scoring plus LLM-written mandates, hiring at mission start **and** mid-mission (for example, Daichi after repeated test failures, or Kaito when risky code changes) | Mycel `teams/executive/maya`, `hiring/` |
| **7** | Atlas orchestrator | Decision loop: observe → decide (continue, retry, reassign, replan, clarify, escalate, stop) → dispatch. Feedback loops: tests → developer, review → developer, dispute → arbiter → human. Success conditions and stop rules | Mycel `core/orchestrator.py` (replaced by a loop) |
| **8** | Mission API and workers | `POST /missions`, `GET /missions/{id}`, snapshot, clarification answers, approvals, apply-change-to-repo (AMBER). Job queue (memory, Redis Streams) and a separate worker process. Cancellation | Mycel `routes/project.py` |
| **9** | Evaluation | Five demo repos under `missions/` (feature, seeded bug, failing test, planted vulnerability, ambiguous / unavailable tool). Run-log export (JSON + Markdown). Single-agent baseline for comparison | — |
| **10** | Hardening | Auth (JWT), rate limits, CORS, request IDs, metrics, OpenAPI docs, README with architecture diagram, tool list and boundaries | Mycel `core/auth.py` |

**Status:** all phases 0–10 are built and tested (`backend_main/tests`, 176 tests; the Redis and MongoDB backends are tested against real servers when `DEVPILOT_TEST_REDIS_URL` / `DEVPILOT_TEST_MONGO_URL` are set). The production topology — API in queue mode + separate worker, MongoDB + Redis — also completed a live mission and applied it after human approval. A full mission also completed live on Groq — see `docs/runs/2026-10-30-live-billing-fix/`. Maya's hiring and mandates were checked live on Groq `gpt-oss-20b`; one agent was also verified live on Groq `gpt-oss-120b` (fixed a seeded bug with test evidence); the Gemini fallback is not yet verified. Remaining: the full live evaluation run and the frontend.
