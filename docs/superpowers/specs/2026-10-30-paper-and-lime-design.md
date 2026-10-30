# Paper & Lime Performance Mobile & Screen-Based Architecture Spec

## Intent & The Why
DevPilot is transitioning from tab-based switching to a screen-based editorial mobile application. The user has provided an exacting design system ("Paper & Lime Performance Mobile") and architectural requirement: **"use screens, instead of tabs, i want terminal and running agents inside the current running project"**.

In this architecture:
1. Navigation is purely screen-to-screen (`Navigator.push` / dedicated full views). There is no bottom tab bar switching views.
2. The current running project screen (Detail / Project screen) is the central command center: it houses the live color-coded terminal feed, the active agent roster (Atlas, Dev, Nisha), system hardware vitals, artifact stream previews, and the tactile macro deck.
3. The visual identity adopts the editorial "Paper & Lime Performance Mobile" aesthetic: warm off-white paper canvas, ink typography and dark feature cards, electric lime rationed accent, ember orange reserved for hero metrics/alerts, Space Grotesk geometric headings/numerals, Inter body and tracked-out (+0.18em) all-caps kickers, and 24px corner radii.

---

## 1. Design System: Paper & Lime Performance Mobile

### 1.1 Color Tokens & Tonal Layering
- `surface` (`#F4F2EC`): Warm paper — global scaffold/page background.
- `surface-alt` (`#EBE8E0`): Paper-alt — default card background for grouped data, stat tiles, and project preview cards.
- `surface-raised` (`#FFFFFF`): Pure white — list-row cards (such as goals and agent items) to "lift" off paper without drop shadows.
- `surface-inverse` (`#0E0F0C`): Ink — dark feature cards (console feed, schedule tile, tactile macro deck).
- `primary` (`#D7FE47`): Electric lime — strict accent only (active status pill, active chip, single metric accent). Never used as full page surface or > 25% viewport.
- `primary-deep` (`#C8F02A`): Pressed lime for interactive active tap states.
- `on-primary` (`#0E0F0C`): Ink on lime.
- `accent` (`#FF5A1F`): Ember orange — reserved strictly for hero metric numerals and alert notification dots (6px dot).
- `on-surface` (`#0E0F0C`): Ink — primary text.
- `on-surface-variant` (`#8A8A82`): Mute gray — metadata, kicker labels, inactive states.
- `on-inverse` (`#F4F2EC`): Warm paper text on ink surfaces.
- `border` (`#E3E0D7`): Hairline dividers (1px) — never card outlines.
- `border-strong` (`#DDDAD1`): Progress track fills.
- `neutral-soft` (`#C8C5BA`): De-emphasized data bar fill.

### 1.2 Hierarchy & Accent Rationing Rules
- **Lime Rationing:** Exactly one primary lime element per screen (e.g., active running task badge or active status pill).
- **Ember Rationing:** Exactly one ember element per screen (e.g., hero metric numeral or alert badge dot on top-bar notifications).
- **No Direct Contact:** Lime and ember never touch each other directly; always separated by ink, paper, or paper-alt.
- **Zero Drop Shadows:** Cards, buttons, and photos have no drop shadows. Depth is achieved purely through tonal layering (paper -> paper-alt -> white -> ink).

### 1.3 Typography Rules & Roles
- **Display Sans:** `Space Grotesk` (weights 600, 700 only; tight tracking -0.01em on headings, -0.04em on numerals; tabular figures enabled).
  - `display-xl`: 84px, w700, -0.04em (hero numerals, e.g. ember metric).
  - `display-md`: 34px, w700, -0.04em (stat tile numerals).
  - `numeral-md`: 26px, w700, -0.04em (data strip numerals).
  - `numeral-sm`: 22px, w700, -0.04em (secondary numerals).
  - `headline-md`: 17px, w600, -0.01em (top-bar greeting / primary screen titles).
  - `headline-sm`: 15px, w600, -0.01em (section anchors above lists).
  - `card-title`: 16px, w600, -0.01em (title in list-row cards).
- **Humanist Neutral Sans:** `Inter` (weights 400, 450, 500).
  - `body-md`: 13px, w450, 0em (paragraphs, descriptive copy).
  - `body-sm`: 12px, w400, 0em (secondary metadata).
  - `label-md`: 12px, w500, -0.01em (button and chip text).
  - `label-sm`: 11px, w500, +0.01em (chips, small badges).
  - `label-uppercase`: 10px, w500, **+0.18em** tracking (all-caps tracked-out kickers for every section eyebrow and metric label).
  - `caption`: 9px, w500, +0.15em (micro-ticks).
- **Tabular Numerals & Weight Shift:** Every number uses `font-variant-numeric: tabular-nums`. Active numerals use weight 700 with -0.04em; idle numerals use weight 500 with -0.02em.

### 1.4 Shapes & Corner Radii
- `rounded.sm` (8px): micro-progress bars, tiny inline chips.
- `rounded.md` (18px): photo thumbnails inside list rows.
- `rounded.lg` (24px): every card, tile, and grouped surface. **Default for all cards.**
- `rounded.full` (9999px): chips, buttons, avatars, badges, icon buttons.

---

## 2. Navigation & Screen Architecture

### 2.1 Pure Screen-Based Navigation
- Bottom tab bars and tab switching are removed.
- Screens navigate hierarchically:
  - `HomeScreen` (Overview, Projects, System Status, Quick Launch) -> `DetailScreen` (Project Command Center).
  - Push navigation with standard transitions (`Navigator.push` / `Navigator.pop`).

### 2.2 HomeScreen (Overview & Projects)
- **Top App Bar:**
  - Left: User avatar (`rounded.full`, 40px) + two-line greeting (Kicker: `DEV PILOT` in `label-uppercase`, Greeting: `Hello, Aryan` in `headline-md`).
  - Right: Utility icon buttons (`rounded.full`, 40px, `surface-alt` fill) for search/filter and notifications (featuring the 6px ember `#FF5A1F` alert dot).
- **Hero Performance Metric Tile / Strip:**
  - Space Grotesk display numeral (e.g., active pipeline duration or health score) with tracked-out kicker.
- **Section: "YOUR PROJECTS (3)":**
  - Section header: `label-uppercase` "WORKSPACE" + `headline-sm` "Your Projects (3)".
  - **Active Running Project Card (Hero Card):**
    - Sits prominently with `surface-alt` or dark ink accents, `rounded.lg` (24px).
    - Status pill with electric lime accent (`#D7FE47` text/pill) indicating "PIPELINE ACTIVE • T+08:42".
    - Displays project name ("Admin Dashboard"), active team avatars, run duration pill ("45 hours"), corner arrow icon (`↗`).
    - Tapping opens the **Project Screen** (`DetailScreen`).
  - **Secondary Project Cards:**
    - "Wallet Mobile", "Cloud Infrastructure" with pastel paper-alt styling, avatars, duration pills.
- **Floating Quick Action / Settings Pill:**
  - Round icon button or capsule at bottom for quick configuration (`ParameterModal`).

### 2.3 DetailScreen (Current Running Project Command Center)
Houses everything needed for the active project in one cohesive, scrollable performance view:
1. **Screen Header:**
   - Round icon back button (`button-icon` 40px circle in `surface-alt`).
   - Title: `Planning` / `Admin Dashboard` in `Space Grotesk` (`headline-md`).
   - Electric lime status pill: `T+08:42` (live timer).
   - "Done" button (`button-primary` ink pill).
2. **Session / Schedule & Host Tile:**
   - Dark feature card (`card-inverse` `#0E0F0C`, `rounded.lg` 24px).
   - Space Grotesk hero numeral `21` ("November, 10 AM").
   - LAN connection pill ("LAN E2EE • 192.168.1.104") with green/lime indicator.
   - Host share link button.
3. **Members Strip:**
   - Section kicker: `label-uppercase` "MEMBERS (6)".
   - Stacked circular avatars with member count and reminder pill.
4. **Goals & Milestones (White Raised List-Rows):**
   - Section kicker: `label-uppercase` "OBJECTIVES".
   - White cards (`surface-raised` `#FFFFFF`, `rounded.lg` 24px) with numbered badges (1, 2, 3), title in `Space Grotesk`, status pills.
5. **Active Agent Roster (Inside Current Project):**
   - Section kicker: `label-uppercase` "ACTIVE AGENT ROSTER (3)".
   - White raised cards (`card-raised` `#FFFFFF`, `rounded.lg` 24px) for running agents:
     - **Atlas (Lead Architect):** Clearance `GREEN`, status "Designing modular contracts", team `ENGINEERING`.
     - **Dev (Code Synthesis):** Clearance `AMBER`, status "Synthesizing test harness", team `RUNTIME`.
     - **Nisha (QA & Security):** Clearance `GREEN`, status "Auditing cryptographic primitives", team `SECURITY`.
     - Tapping any agent card opens `AgentDossierModal`.
6. **Live Terminal Feed (Inside Current Project):**
   - Section kicker: `label-uppercase` "LIVE TERMINAL FEED".
   - Ink dark container (`card-inverse` `#0E0F0C`, `rounded.lg` 24px).
   - Monospace scrolling logs color-coded (lime/green `#D7FE47` / `#22C55E`, yellow `#EAB308`, red `#EF4444`, cyan `#38BDF8`).
   - Quick action prompt button ("Run CLI Command...") that slides up `CliSheet`.
7. **Artifact Stream (Inside Current Project):**
   - Section kicker: `label-uppercase` "ARTIFACT STREAM".
   - Horizontal preview strip of generated files (`auth-flow.png`, `schema.sql`, `build-output.apk`).
8. **System Hardware Vitals & Tactile Macro Deck (Inside Current Project):**
   - Section kicker: `label-uppercase` "HOST VITALS & CONTROLS".
   - 4-column tabular data strip (`card-raised` `#FFFFFF` or `surface-alt` `#EBE8E0`):
     - CPU %, RAM %, Net I/O, Battery % with Space Grotesk tabular numerals.
   - Tactile Macro Deck (Deploy App, Run Tests, Restart Docker, Kill All).
   - "Kill All" invokes the `ApprovalModal` (Biometric approval gate).

---

## 3. Modals & Sheets (Consistent Paper & Lime Styling)
- **ApprovalModal:** Biometric Face ID / Fingerprint simulation gate with ember accent alert for high-risk operations.
- **CliSheet:** Monospace bottom drawer for executing bash commands with quick suggestions (`git status`, `docker ps`).
- **AgentDossierModal:** Deep inspection of agent clearance, active goals, system telemetry, and execution logs.
- **ParameterModal:** Runtime parameters (`--verbose` toggle, thread slider, target host).

---

## 4. Verification & Constraints
- Zero regressions in existing 58 unit and widget tests.
- 0 analyzer warnings (`flutter analyze`).
- All tests passing with `flutter test`.
- Real-time deployment verification on active Android emulator.
