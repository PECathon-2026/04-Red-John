# Paper & Lime Redesign & Screen Architecture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign DevPilot to the editorial "Paper & Lime Performance Mobile" aesthetic and transition to a pure screen-based navigation model where the terminal and active agent roster live directly inside the active project command center screen.

**Architecture:** Replace legacy pastel tokens with warm paper `#F4F2EC`, paper-alt `#EBE8E0`, white `#FFFFFF`, ink `#0E0F0C`, electric lime `#D7FE47` (accent only), and ember `#FF5A1F` (alerts/hero metrics). Eliminate bottom navigation tabs; `HomeScreen` pushes `DetailScreen` via `Navigator.push`. `DetailScreen` consolidates project goals, active agent roster, live terminal feed, artifact previews, and host vitals/macros in one scrollable command center.

**Tech Stack:** Flutter 3.13.7 (Dart 3.13.7), Google Fonts (`google_fonts` 9.0.0 for Space Grotesk & Inter), Material 3, Android SDK 35/17.

**Spec:** [docs/superpowers/specs/2026-10-30-paper-and-lime-design.md](file:///Users/aryan/Documents/Fullstack%20Projects/devPolit/docs/superpowers/specs/2026-10-30-paper-and-lime-design.md)

## Global Constraints
- Canvas: Warm paper `#F4F2EC`. Never used as card fill against itself.
- Cards: Paper-alt `#EBE8E0` (default cards), White `#FFFFFF` (raised list rows), Ink `#0E0F0C` (dark feature cards).
- Accents: Electric lime `#D7FE47` used strictly once per screen as accent; Ember `#FF5A1F` reserved strictly for hero numerals and alert dots. Lime and ember never touch directly.
- Radii: 24px (`rounded.lg`) default for cards/tiles; 18px (`rounded.md`) for photos/thumbs; 9999px (`rounded.full`) for chips/pills/buttons/avatars.
- Zero drop shadows on cards, buttons, or photos (flat surfaces, tonal layering).
- Space Grotesk 600/700 for all numerals and headings with `tabular-nums`. Inter for body, labels, and 10px uppercase kickers with `letterSpacing: 1.8` (+0.18em).
- No bottom navigation tabs. Navigation is purely screen-to-screen.

## Review Focus
- Tabular numeral alignment: All live timers, stats, and counters must use `FontFeature.tabularFigures()`.
- Active vs. idle weight shift: Active stats use w700 (-0.04em); idle stats use w500 (-0.02em).
- Accent rationing: Ensure electric lime is never used as page surface and ember is strictly reserved for alerts/hero metric.
- Screen navigation ergonomics: Back navigation from `DetailScreen` to `HomeScreen` must be seamless with no dangling routes.
- Biometric approval gate integrity: High-risk macros (Kill All) must trigger `ApprovalModal` before dispatch.

---

### Task 1: Paper & Lime Design Tokens, Google Fonts & Theme Configuration

**Files:**
- Modify: `DevPilot/lib/theme/app_theme.dart`
- Modify: `DevPilot/test/models_and_theme_test.dart`

**Interfaces:**
- Consumes: `google_fonts` package.
- Produces: `AppTheme` class providing:
  - Colors: `surface` (`0xFFF4F2EC`), `surfaceAlt` (`0xFFEBE8E0`), `surfaceRaised` (`0xFFFFFFFF`), `surfaceInverse` (`0xFF0E0F0C`), `primary` (`0xFFD7FE47`), `primaryDeep` (`0xFFC8F02A`), `onPrimary` (`0xFF0E0F0C`), `accent` (`0xFFFF5A1F`), `onSurface` (`0xFF0E0F0C`), `onSurfaceVariant` (`0xFF8A8A82`), `onInverse` (`0xFFF4F2EC`), `border` (`0xFFE3E0D7`), `borderStrong` (`0xFFDDDAD1`), `neutralSoft` (`0xFFC8C5BA`).
  - Shapes: `cardRadius` (BorderRadius.circular(24)), `thumbRadius` (BorderRadius.circular(18)), `pillRadius` (BorderRadius.circular(9999)).
  - Typography: `displayXl`, `displayMd`, `numeralMd`, `numeralSm`, `headlineMd`, `headlineSm`, `cardTitle`, `bodyMd`, `bodySm`, `labelMd`, `labelSm`, `labelUppercase` (letterSpacing 1.8), `caption`.
  - Theme: `AppTheme.themeData` with zero card elevation, transparent divider, and warm paper scaffold.

- [ ] **Step 1: Write failing theme test in `DevPilot/test/models_and_theme_test.dart`**
  Assert the new Paper & Lime tokens (`surface`, `surfaceAlt`, `primary`, `accent`, `surfaceInverse`, `cardRadius = 24`, etc.).

- [ ] **Step 2: Run test to verify it fails**
  Run: `cd "DevPilot" && flutter test test/models_and_theme_test.dart`
  Expected: FAIL with missing or mismatched token definitions.

- [ ] **Step 3: Implement Paper & Lime tokens and typography in `DevPilot/lib/theme/app_theme.dart`**
  Implement colors, radii, Space Grotesk / Inter typography styles with tabular figures, and Material 3 theme configuration.

- [ ] **Step 4: Run test to verify it passes**
  Run: `cd "DevPilot" && flutter test test/models_and_theme_test.dart`
  Expected: PASS

- [ ] **Step 5: Commit**
  Run: `git add lib/theme/app_theme.dart test/models_and_theme_test.dart && git commit -m "feat: implement Paper & Lime design tokens, typography, and theme"`

---

### Task 2: Reusable Tactile Widgets in Paper & Lime Language

**Files:**
- Modify: `DevPilot/lib/widgets/vitals_bar.dart`
- Modify: `DevPilot/lib/widgets/macro_deck.dart`
- Modify: `DevPilot/lib/widgets/running_task_card.dart`
- Modify: `DevPilot/lib/widgets/agent_card.dart`
- Modify: `DevPilot/lib/widgets/terminal_feed.dart`
- Modify: `DevPilot/lib/widgets/artifact_stream.dart`
- Modify: `DevPilot/test/home_widgets_test.dart`

**Interfaces:**
- Consumes: `AppTheme` tokens and domain models (`models.dart`).
- Produces:
  - `VitalsBar(vitals: HardwareVitals)`: 4-column tabular strip in `surfaceAlt` with `labelUppercase` kickers and Space Grotesk numerals.
  - `MacroDeck(onAction: Function(String), isPending: bool)`: Tactile ink pills (`rounded.full`, 44px height).
  - `RunningTaskCard(task: RunningTask, onTap: VoidCallback)`: 24px card with lime status chip, `T+MM:SS` timer, and LAN E2EE badge.
  - `AgentCard(agent: AgentItem, onTap: VoidCallback)`: White raised list card (`card-raised` 24px) with clearance indicator and tracked-out team kicker.
  - `TerminalFeed(logs: List<TerminalLog>, onClear: VoidCallback)`: Dark ink card (`surfaceInverse` 24px) with color-coded monospace logs.
  - `ArtifactStream(artifacts: List<ArtifactItem>, onArtifactTap: Function(ArtifactItem))`: 24px preview cards.

- [ ] **Step 1: Write failing widget test in `DevPilot/test/home_widgets_test.dart`**
  Test `VitalsBar`, `MacroDeck`, `RunningTaskCard`, and `AgentCard` with Paper & Lime styling assertions.

- [ ] **Step 2: Run test to verify it fails**
  Run: `cd "DevPilot" && flutter test test/home_widgets_test.dart`
  Expected: FAIL on styling/token differences.

- [ ] **Step 3: Update widgets to Paper & Lime language**
  Update `VitalsBar`, `MacroDeck`, `RunningTaskCard`, `AgentCard`, `TerminalFeed`, and `ArtifactStream` to use 24px radii, Space Grotesk numerals, Inter kickers, and tonal layering.

- [ ] **Step 4: Run test to verify it passes**
  Run: `cd "DevPilot" && flutter test test/home_widgets_test.dart`
  Expected: PASS

- [ ] **Step 5: Commit**
  Run: `git add lib/widgets/ test/home_widgets_test.dart && git commit -m "feat: re-skin reusable tactile widgets to Paper & Lime language"`

---

### Task 3: Redesign HomeScreen with Pure Screen Navigation (No Bottom Tabs)

**Files:**
- Modify: `DevPilot/lib/screens/home_screen.dart`
- Modify: `DevPilot/test/home_screen_test.dart`

**Interfaces:**
- Consumes: `TelemetryService`, `RunningTaskCard`, `AppTheme`.
- Produces: `HomeScreen` widget:
  - Top app bar: 40px user avatar + `DEV PILOT` kicker / `Hello, Aryan` heading on left; utility buttons in `surfaceAlt` with 6px ember alert dot on right.
  - Hero Metric Strip: Tabular numeral + tracked-out kicker.
  - "YOUR PROJECTS (3)" Section:
    - Active Running Project Card (Hero): Electric lime status pill, live `T+MM:SS` counter, duration pill, and tapping triggers `onOpenProject(project)`.
    - Secondary Project Cards: "Wallet Mobile", "Cloud Infrastructure" in `surfaceAlt`.
  - Floating Quick Action / Settings Capsule at bottom triggering `onOpenSettings`.
  - No bottom navigation tabs.

- [ ] **Step 1: Write failing test in `DevPilot/test/home_screen_test.dart`**
  Verify `HomeScreen` renders top app bar with ember alert dot, project cards, hero running task card, and tapping opens project. Assert absence of bottom navigation tabs.

- [ ] **Step 2: Run test to verify it fails**
  Run: `cd "DevPilot" && flutter test test/home_screen_test.dart`
  Expected: FAIL (tab bar assertions / missing Paper & Lime layout).

- [ ] **Step 3: Implement screen-based `HomeScreen` in `DevPilot/lib/screens/home_screen.dart`**
  Remove bottom navigation bar; assemble editorial header, hero project card with lime pill, secondary cards, and bottom utility pill.

- [ ] **Step 4: Run test to verify it passes**
  Run: `cd "DevPilot" && flutter test test/home_screen_test.dart`
  Expected: PASS

- [ ] **Step 5: Commit**
  Run: `git add lib/screens/home_screen.dart test/home_screen_test.dart && git commit -m "feat: build editorial HomeScreen with screen-based navigation"`

---

### Task 4: Overhaul DetailScreen (Command Center Housing Terminal, Agents, Vitals, and Macros)

**Files:**
- Modify: `DevPilot/lib/screens/detail_screen.dart`
- Modify: `DevPilot/test/detail_screen_test.dart`

**Interfaces:**
- Consumes: `TelemetryService`, `ProjectItem`, `TerminalFeed`, `ArtifactStream`, `AgentCard`, `VitalsBar`, `MacroDeck`.
- Produces: `DetailScreen` widget:
  - Top navigation bar: Round 40px icon back button (`onBack`), project title in Space Grotesk, live `T+MM:SS` lime pill, and "Done" ink pill button.
  - Session / Schedule card in `surfaceInverse` (`#0E0F0C`, 24px radius) with Space Grotesk display numeral "21", host share button, and LAN E2EE pill.
  - Members row with tracked-out kicker `MEMBERS (6)`.
  - Goals checklist in white raised cards (`surfaceRaised` `#FFFFFF`, 24px radius).
  - **Active Agent Roster (inside current project)**: Section kicker `ACTIVE AGENT ROSTER (3)` with `AgentCard`s (Atlas, Dev, Nisha). Tapping calls `onOpenAgent(agent)`.
  - **Live Terminal Feed (inside current project)**: Section kicker `LIVE TERMINAL FEED` with `TerminalFeed` and "Open CLI Terminal" button (`onOpenCli`).
  - **Artifact Stream (inside current project)**: Section kicker `ARTIFACT STREAM` with `ArtifactStream`.
  - **Host Vitals & Tactical Macro Deck (inside current project)**: Section kicker `HOST VITALS & CONTROLS` with `VitalsBar` and `MacroDeck`.

- [ ] **Step 1: Write failing test in `DevPilot/test/detail_screen_test.dart`**
  Test `DetailScreen` renders planning header, schedule card, goals, active agent roster, terminal feed, artifact stream, and vitals bar.

- [ ] **Step 2: Run test to verify it fails**
  Run: `cd "DevPilot" && flutter test test/detail_screen_test.dart`
  Expected: FAIL on missing agent roster, vitals, or styling tokens.

- [ ] **Step 3: Implement consolidated Project Command Center in `DevPilot/lib/screens/detail_screen.dart`**
  Assemble all sections into a smooth scrollable view using Paper & Lime tokens and 24px rounded surfaces.

- [ ] **Step 4: Run test to verify it passes**
  Run: `cd "DevPilot" && flutter test test/detail_screen_test.dart`
  Expected: PASS

- [ ] **Step 5: Commit**
  Run: `git add lib/screens/detail_screen.dart test/detail_screen_test.dart && git commit -m "feat: house terminal, running agents, vitals, and macro deck inside DetailScreen"`

---

### Task 5: Modals Styling, Root App Navigation Wiring & Full Suite Verification

**Files:**
- Modify: `DevPilot/lib/widgets/modals/approval_modal.dart`
- Modify: `DevPilot/lib/widgets/modals/cli_sheet.dart`
- Modify: `DevPilot/lib/widgets/modals/agent_dossier_modal.dart`
- Modify: `DevPilot/lib/widgets/modals/parameter_modal.dart`
- Modify: `DevPilot/lib/main.dart`
- Modify: `DevPilot/test/modals_test.dart`
- Modify: `DevPilot/test/widget_test.dart`

**Interfaces:**
- Consumes: All updated screens, widgets, modals, and `TelemetryService`.
- Produces: Fully integrated `DevPilotApp` with screen-based navigation and consistent Paper & Lime modals.

- [ ] **Step 1: Update modals to Paper & Lime tokens**
  Update `ApprovalModal` (ember alert), `CliSheet`, `AgentDossierModal`, and `ParameterModal` to warm paper background, 24px sheets, ink pills, and Space Grotesk typography.

- [ ] **Step 2: Wire `DevPilotApp` root navigation in `DevPilot/lib/main.dart`**
  Ensure `HomeScreen` is root, project taps navigate to `DetailScreen` via `Navigator.push`, back button navigates back via `Navigator.pop`, and macro approval gates work seamlessly.

- [ ] **Step 3: Update root widget and modal tests in `test/modals_test.dart` and `test/widget_test.dart`**
  Test screen push navigation, modal triggers, and biometric gate flow.

- [ ] **Step 4: Run full test suite to verify 100% pass**
  Run: `cd "DevPilot" && flutter analyze && flutter test`
  Expected: 0 issues, all tests passing.

- [ ] **Step 5: Commit**
  Run: `git add lib/ test/ && git commit -m "feat: complete Paper & Lime modals styling, screen navigation wiring, and test verification"`

---

### Task 6: Android Emulator Deployment & Local Graphify Synchronization

**Files:**
- Output: Debug APK deployment to `emulator-5554`
- Local Graphify: `graphify update .`

- [ ] **Step 1: Build debug APK and deploy to active Android emulator**
  Run: `cd "DevPilot" && flutter run -d emulator-5554`
  Verify app boots and screen navigation is responsive on emulator.

- [ ] **Step 2: Capture emulator screenshot for visual verification**
  Run: `adb exec-out screencap -p > /tmp/emulator_redesign.png`
  Verify visual aesthetics (warm paper, electric lime accent, Space Grotesk headings, ink cards).

- [ ] **Step 3: Update local knowledge graph**
  Run: `cd "/Users/aryan/Documents/Fullstack Projects/devPolit" && graphify update .`
  Verify graph reflects updated code.
