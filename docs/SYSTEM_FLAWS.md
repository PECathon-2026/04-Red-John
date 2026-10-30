# DevPilot — Fragility Review

_What makes the system break, and what makes it hard to work on. Written 2026-10-30 from the code in this repo and from what actually failed during testing today._

Each flaw lists **where** it lives, **what it does to you**, and **the fix**. Severity:

- 🔴 **Critical**: stops missions or loses work, regularly
- 🟠 **High**: frequent pain or a real risk
- 🟡 **Medium**: friction, confusion, or a slow-burning problem

---

## The short version

Most of the pain today came from five things:

1. 🔴 **Everything depends on free LLM tiers that are near their limits.** Groq caps each request at 8k tokens and the 25 keys get rate-limited together. Gemini is the only fallback and has never been verified. When the model is down, agents can't do anything.
2. 🔴 **An LLM outage looks like a mission problem.** Atlas spends task attempts on it, then asks *you* a "blocker" question you can't answer. Nobody can type their way out of a provider outage.
3. 🔴 **All state lives in memory, inside the API process.** Restarting the backend (including `--reload` after any code edit) kills running missions, deletes every mission, and logs everyone out.
4. 🟠 **Three clients each carry their own copy of the agent roster, team names and statuses.** They drift apart. Today's merge conflict was mostly that.
5. 🟠 **The mobile app shows fake data next to real data.** Sample projects, fake terminal output and "biometric" approval messages make it hard to tell whether the backend is actually working.

---

## 1. LLM layer (the main source of failures)

### 1.1 🔴 Free-tier ceilings shape the whole design
- **Where:** `backend_main/app/core/config.py`. `LLM_MAX_REQUEST_TOKENS=7800` exists because Groq's on-demand tier rejects any request over 8,000 tokens.
- **Impact:**
  - Tool schemas alone take about 3k tokens per agent, so an agent has roughly 4k tokens for the task, the files and its history.
  - Agents forget their own earlier work and repeat it. The runtime already needs a "digest" workaround for this.
  - Big files or big diffs can't fit, so agents work blind on anything non-trivial.
- **Fix:** add at least one paid provider with a large context window (OpenAI, Anthropic, or Azure on a non-student subscription). Then raise `LLM_MAX_REQUEST_TOKENS` to 30k or more.

### 1.2 🔴 Fallback chain is unverified and partly dead
- **Where:** `app/container.py` `build_llm_gateway`. Groq first, then `gemini-3.8-flash`.
- **Evidence:**
  - Gemini returned `503 overloaded` in earlier live tests (project notes).
  - About 4 of the 25 Groq keys return `401` (dead).
  - Today's probe took about 3 minutes to get one answer because keys were cooling down.
- **Impact:** "fallback" mostly means "wait longer, then fail anyway".
- **Fix:**
  - Run a startup self-test that makes one tiny call per route and marks failing routes unhealthy. Show the result on `/health/ready` and in both UIs.
  - Drop dead keys automatically after one `401` (they're currently only benched for 24h in memory, so every restart tries them again).

### 1.3 🔴 Providers that reply "200 OK" with garbage crashed agents *(fixed today)*
- **Where:** `app/infrastructure/llm/openai_compat.py`.
- **What happened:** `models.github.ai` answers every request with the plain-text body `OK`, even with no token. The code called `response.json()` without checking, so Kenji, Hana and Ryo crashed with `JSONDecodeError`. The crash counted as an ordinary agent failure, so Maya started reassigning work.
- **Status:** fixed. A non-JSON `200` now counts as that provider failing, and the gateway moves to the next one.
- **Remaining lesson:** any new provider needs a live smoke test before going into the chain (see 9.3).

### 1.4 🟠 Model quirks are handled by one-off patches
- **Where:** `app/agents/runtime.py`, `app/tools/registry.py`. These cover `nullable_optionals`, finish calls written as JSON text, hallucinated tool names (`repo_browser.*`), `failed_generation` salvage, and `<think>` stripping.
- **Impact:**
  - Each quirk belongs to one model (`gpt-oss-120b` on Groq). Switching models brings new quirks that nothing handles.
  - The patches are spread through the runtime, so they're hard to reason about.
  - The scripted-LLM unit tests can't catch any of them.
- **Fix:** put the per-model fixes behind a small "model profile" (one place that says: tolerates nulls, puts finish in text, max context, temperature allowed). Add a live smoke test per profile.

### 1.5 🟡 Waiting is opaque
- **Impact:** a rate-limited call can wait up to 90s (`rate_limit_budget_s`) with up to 12 attempts, and the UI shows nothing. Users think it's frozen and click Stop or Resume, which makes things worse.
- **Fix:** publish a `log` event when the gateway is waiting ("Groq keys cooling down, retrying in 40s").

---

## 2. Mission execution

### 2.1 🔴 Outages become "human blockers"
- **Where:** `app/services/orchestrator.py` (`llm_unavailable` branch).
- **What it does:** each outage spends one of the task's 3 attempts. After 3, Atlas escalates with *"failed 3 time(s): the language model is unavailable"* and the mission goes to `awaiting_human`.
- **Impact:**
  - The human can't fix a provider outage by answering a question.
  - Attempts meant for "the agent got it wrong" are spent on infrastructure.
  - You saw this today: the "Needs your answer" box had nothing sensible to type.
- **Fix:**
  - Don't spend task attempts on `llm_unavailable`.
  - Pause the mission with a distinct status (e.g. `paused_llm_unavailable`) and an automatic retry timer.
  - Show "Waiting for the AI provider" instead of a question box.

### 2.2 🔴 Missions run inside the API process
- **Where:** `EXECUTION_MODE=inline` (default) → `InlineRunner` in `app/services/runner.py`.
- **Impact:**
  - `uvicorn --reload` restarts the process on every `.py` save, which cancels every running mission mid-task. You run it this way, so any code edit during a demo kills the demo.
  - A slow tool call or a stuck LLM request competes with API requests on the same event loop.
- **Fix:**
  - For demos, run *without* `--reload`.
  - Long term, use `EXECUTION_MODE=queue` with a separate worker process (`python -m app.worker`, already built) and Redis.

### 2.3 🟠 Every mission copies the whole repository
- **Where:** `app/security/sandbox.py` `WorkspaceManager._create_sync` (`shutil.copytree` plus `git init`/`add`/`commit`).
- **Impact:**
  - Creating a mission takes as long as copying the repo. On a real project with assets that can be seconds to minutes, and the API waits.
  - `var/workspaces/` grows with every mission. Nothing cleans it up except a failed create.
- **Fix:**
  - Use `git worktree add` (instant) when the source is a git repo.
  - Add a cleanup job that deletes workspaces of terminal missions older than N days.

### 2.4 🟠 Agents can't see the real project until Apply
- **What it does:** agents work in a copy. The user's folder only changes after Patch review, Apply, and a human approval.
- **Impact:**
  - It's safe, but nobody can see this from the UI. You asked today to "give terminal access", which the agents already have.
  - Users don't know where the files are (`backend_main/var/workspaces/<mission_id>/`) or that they have to click Apply.
- **Fix:** show the workspace path and an "Open folder" link on the mission page. After completion, show "Changes are ready, review and apply" as the next step.

### 2.5 🟡 Approvals expire silently
- **Where:** `APPROVAL_TIMEOUT_S=300`. Unanswered approvals become "denied".
- **Impact:** step away for 5 minutes and the agent's command gets denied. The task then fails or retries without explanation.
- **Fix:** keep the timeout, but pause the task instead of denying it, and send a push notification to the mobile app (it already has an approval modal).

### 2.6 🟡 The orchestration round cap fails long missions
- **Where:** `orchestrator_max_rounds=60`.
- **Impact:** a slow mission with many retries ends as `failed` because it hit a counter, even though nothing actually broke.

---

## 3. State, persistence and sessions

### 3.1 🔴 In-memory storage by default
- **Where:** `STORAGE_BACKEND=memory`, `BUS_BACKEND=memory` (config defaults). The backend log today confirmed `storage=memory, bus=memory`.
- **Impact:** a restart deletes every mission, approval, event, user created via the API, and the audit trail. Combined with 2.2, every code edit wipes the board.
- **Fix:**
  - Use Mongo and Redis via `docker-compose.yml` (already in `backend_main/`).
  - If Docker is too heavy, add a SQLite or JSON-file storage backend for development.

### 3.2 🔴 Logins die on every restart
- **Where:** `app/container.py` `build_auth`. Without `JWT_SECRET` (32+ chars), a random secret is generated per process.
- **Impact:** every backend restart invalidates every token. The web app bounces to `/login`, and the mobile app drops to its sign-in screen.
- **Fix:** set `JWT_SECRET` in `.env` (a one-line fix). Consider making startup refuse to run without it unless `AUTH_ENABLED=false`.

### 3.3 🟠 Web sessions live in `sessionStorage`
- **Where:** `frontend_main/lib/api.ts`.
- **Impact:** each new tab, or closing the tab, needs a new login. That's annoying during a demo with several tabs.
- **Fix:** use `localStorage`, or better, an httpOnly cookie set by the backend.

---

## 4. Contracts between backend and clients

### 4.1 🟠 The agent roster is duplicated in three places
- **Where:**
  - Backend: `app/agents/guild.py` (source of truth, served at `/agents`).
  - Web: `frontend_main/lib/simulation/map-data.ts` (desk positions plus hardcoded names and roles) and `lib/agents.ts`.
  - Mobile: `BackendModelConverters.guild16` in `DevPilot/lib/models/models.dart`.
- **Impact:**
  - Renaming a role or a team means editing three codebases.
  - Today's merge was largely two branches disagreeing on this list: team names (`Intelligence/Network/...` vs `Planning/Forge/...`), plus 21 old agents still in the incoming branch.
- **Fix:** clients fetch `/api/v1/agents` and keep only *layout* data (desk positions, sprite index) locally, keyed by `agent_id`.

### 4.2 🟠 The snapshot carries two shapes in one payload
- **Where:** `app/services/snapshot.py` returns both the old "Mycel" shape (`clock`, `logs`, `hires`, `agents`, `complete`, `pendingApprovals`) and the DevPilot shape (`mission`, `tasks`, `acceptanceCriteria`, ...).
- **Impact:**
  - Clients read some fields from each, inconsistently.
  - Field names mix camelCase and snake_case.
  - No schema is published, so a backend change breaks clients silently.
- **Fix:**
  - Define one versioned snapshot model in Pydantic and export it through OpenAPI.
  - Generate TypeScript types (e.g. `openapi-typescript`) for the web app.
  - Write the matching Dart models for mobile.

### 4.3 🟡 Event kinds aren't handled the same way everywhere
- **Impact:** the web app handles most kinds. Mobile handled only 7 until today, so it showed stale task lists. A new `EventKind` added to the backend is silently ignored by both clients.
- **Fix:** keep the shared event list next to the snapshot schema (4.2), and add a client test that fails on unknown kinds.

---

## 5. Web frontend (`frontend_main/`)

### 5.1 🟠 Two people are refactoring the same files in parallel
- **Evidence:** today's merge had 18 conflicted files, including whole-file rewrites of `lib/mission-sim.ts`, `lib/agents.ts` and `lib/auth.ts` from both sides. One side added real backend integration; the other added UI polish *on top of the old mock layer*. One side's `blueprint-tab.tsx` depended on files the other side deleted.
- **Impact:** every merge is a manual reconciliation, and UI work keeps being built on code that no longer exists.
- **Fix:** split ownership (one person on `lib/`, one on `components/`), make short-lived branches, and merge daily (see 9.1).

### 5.2 🟡 Leftover names from the mock era
- **Where:** `lib/mission-sim.ts` is the *real* backend client but is still named "sim". `useMissionSim` and `useMission` both existed across branches.
- **Impact:** new contributors build on the wrong module.
- **Fix:** rename it to `lib/mission-client.ts` and delete the remaining mock helpers.

### 5.3 🟡 Ports and config are easy to trip over
- **Where:**
  - The web dev server is pinned to `--port 3001` while backend CORS defaults list 3000 and 3001.
  - Another project (`D:\PPTS\devPolit_ppt`) also runs on port 3000.
  - The API URL comes from `NEXT_PUBLIC_API_URL`, which is baked in at build time.
- **Fix:** document the ports in the README. Read the API URL at runtime in production builds.

---

## 6. Mobile app (`DevPilot/`)

### 6.1 🟠 Fake data shown as if it were real
- **Where:** `lib/services/telemetry_service.dart` `_initializeDefaultState` and `sendCliCommand`:
  - Sample projects ("Admin Dashboard", "Wallet Mobile"), invented past executions, and a fake `.apk` artifact.
  - Fake hardware "vitals".
  - A terminal that answers `git status` and `docker ps` with hardcoded text.
  - Approval logs claiming "biometric authorization".
  - A "Dev" agent with supply-chain wording that isn't in the backend guild.
- **Impact:** when the backend is down, the app still looks alive, so you can't tell real from fake. That makes debugging nearly impossible, and it's risky in front of judges.
- **Fix:** show sample data only in Demo Mode, with a visible "DEMO" badge. With a backend connected, start empty and fill from the API.

### 6.2 🟠 The toolchain doesn't match the machine
- **Evidence:**
  - `pubspec.yaml` needs Dart `^3.13.7` and `google_fonts ^9`.
  - The installed Flutter is 3.44.4 with Dart 3.12.2, so `flutter pub get` fails.
  - `pubspec.lock` doesn't include the new `shared_preferences`.
  - Only `android/` and `ios/` folders exist (no web or windows), and no emulator is set up.
  - Today's run needed a scratch copy with relaxed constraints.
- **Fix:** either upgrade Flutter to 3.47 or newer, or pin the constraints to the team's SDK. Commit the lockfile. Add `web/` so anyone can run it with `flutter run -d chrome`.

### 6.3 🟡 Polling and WebSocket overlap
- **Where:** `TelemetryService` polls `/health` and `/missions` every 6s and also fetches the snapshot every 6s, *while* a WebSocket is open.
- **Impact:** wasted requests and battery. Two sources of truth can flicker.
- **Fix:** poll only the mission list. Rely on the WebSocket for the active mission, and fall back to polling only when the socket is closed.

### 6.4 🟡 Approval handling overwrites local state
- **Where:** `approvePendingGate()` resets the current task to `idle, progress 0.0` after approving.
- **Impact:** after approving, the progress bar jumps to 0 until the next snapshot arrives.

---

## 7. Security and operations

### 7.1 🟠 Shared key pool with dead keys and no ownership
- **Evidence:** 25 Groq keys inherited from Mycel's `GROQ_EXTREME_POOL`, 4 or more dead, nobody knows who owns them. Keys sit in a plain `.env`.
- **Impact:** a key that gets revoked or abused fails without warning, and nobody can rotate it.
- **Fix:** list who owns each key, rotate them, and keep a smaller set of known-good keys.

### 7.2 🟡 Unknown client hitting the backend
- **Evidence:** the backend logs `POST /api/activity/ingest/bulk -> 413` every minute. That route doesn't exist in DevPilot.
- **Impact:** something on this machine (probably another tool or project) talks to port 8000. It's harmless now, but it clutters logs, eats rate-limit budget, and would be confusing in production.
- **Fix:** find the sender (check `D:\PPTS\devPolit_ppt` or a browser extension), or move DevPilot to a less common port.

### 7.3 🟡 Backend listens only on localhost by default
- **Impact:** a phone can't reach `127.0.0.1:8000`. You must start uvicorn with `--host 0.0.0.0` and enter the LAN IP in the app.
- **Fix:** put this in the start scripts and README (done in `DevPilot/README.md`). Optionally, show the server's LAN URL as a QR code in the web app for the phone to scan.

---

## 8. Observability

### 8.1 🟠 Errors only reach the backend console
- **Impact:** today's crash traces (JSONDecodeError, provider failures) were only visible in the uvicorn terminal. The UI showed "failed 3 time(s)" with no cause.
- **Fix:** turn provider and runtime failures into `log` events at `error` level with a one-line cause, so both UIs show them. The plumbing already exists (`events.log`).

### 8.2 🟡 No health view of the LLM routes
- **Impact:** `/health/ready` reports `llm_configured: true` even when every route is failing.
- **Fix:** see 1.2. Report the last success and failure time per route.

---

## 9. Development workflow

### 9.1 🟠 No CI
- **Evidence:** there's no `.github/workflows/`. The backend tests (173) and Flutter tests (75) only run when someone remembers.
- **Fix:** add one GitHub Actions workflow that runs `pytest`, `npx tsc --noEmit` plus `next build`, and `flutter analyze` plus `flutter test` on every push.

### 9.2 🟠 Long-lived divergent branches on `main`
- **Evidence:** today's merge was `main` against `origin/main`, with 2 commits each side, touching about 30 files and including whole-file rewrites.
- **Fix:** use feature branches with PRs, and pull `origin/main` before starting work each day.

### 9.3 🟡 Tests can't see the failures that actually happen
- **Impact:** the scripted-LLM tests pass while live runs fail on provider behaviour (1.3, 1.4). Today's GitHub Models problem would have been caught in seconds by a live probe.
- **Fix:** add a `scripts/llm_smoke.py`, a short version of the probe used today. It makes one call per route plus one tiny agent task, and should be run before demos and after provider or prompt changes.

### 9.4 🟡 Uncommitted work piles up
- **Evidence:** as of writing, the merge, the mobile auth integration, the Azure/GitHub provider support and the CORS change are all uncommitted in one working tree.
- **Fix:** commit after each working step.

---

## Fix order (best payoff first)

| # | Fix | Effort | Removes |
|---|-----|--------|---------|
| 1 | Set `JWT_SECRET` in `.env`; run the backend **without** `--reload` for demos | 2 min | 2.2 (demo kills), 3.2 |
| 2 | Pause instead of escalating on `llm_unavailable`; show "waiting for AI provider" | ½ day | 2.1, 8.1 |
| 3 | One paid, large-context provider first in the chain; raise the token budget | ½ day + cost | 1.1, 1.2, most mission failures |
| 4 | Persistent storage (Mongo/Redis via docker-compose, or SQLite for development) | ½–1 day | 3.1 |
| 5 | LLM route self-test on `/health/ready` plus a `llm_smoke.py` script | ½ day | 1.2, 8.2, 9.3 |
| 6 | CI workflow for all three projects | ½ day | 9.1 |
| 7 | Clients fetch the roster from `/agents`; one typed snapshot schema | 1–2 days | 4.1, 4.2, 4.3 |
| 8 | Mobile: sample data only in Demo Mode; drop the polling overlap | ½ day | 6.1, 6.3 |
| 9 | `git worktree` workspaces plus cleanup | ½ day | 2.3 |
| 10 | Fix the Flutter SDK/lockfile mismatch; add the web platform | 1 hr | 6.2 |
