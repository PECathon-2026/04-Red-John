# DevPilot / MYCEL Mobile Frontend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a production-ready, pixel-perfect Flutter frontend (Android & iOS) for DevPilot / MYCEL featuring Image 1 (Home Screen with active projects, current running task, and agent roster) and Image 2 (Detail Screen with live terminal, vitals, goals, artifacts, and approval gates).

**Architecture:** Pure Flutter Material 3 reactive application powered by `ChangeNotifier` / `InheritedNotifier` (`TelemetryService`). State streams live hardware vitals, an elapsed `T+MM:SS` timer, color-coded terminal logs, and agent statuses. Includes biometric approval gates and slide-up CLI input drawers.

**Tech Stack:** Flutter 3.47.8 / Dart 3.13.7, Material 3, Cupertino Icons.

**Spec:** [`docs/superpowers/specs/2026-10-29-devpilot-mobile-frontend-design.md`](file:///Users/aryan/Documents/Fullstack%20Projects/devPolit/docs/superpowers/specs/2026-10-29-devpilot-mobile-frontend-design.md)

## Global Constraints
- Target workspace: `~/Documents/Fullstack Projects/devPolit/DevPilot`
- All code must pass `flutter analyze` with 0 warnings or errors.
- Visuals must adhere to Image 1 (warm cream `#FAF8F5`, pastel peach `#FCEAD2`, soft mint `#D8EFE9`, bold typography) and Image 2 (warm beige `#F6ECD9`, dark pill badges, white rounded sheet).
- Self-contained execution: The app must run out of the box with realistic live telemetry, timers, and logs on any Android emulator, iOS simulator, or desktop instance.

## Review Focus
1. Timer stability: Ensure the `T+MM:SS` elapsed timer ticks monotonically without memory leaks or race conditions across screen transitions.
2. Terminal autoscroll ergonomics: Scrolling the live console shouldn't violently jump when user is reading past logs.
3. Tactile button responses: Every macro button, approval slider, and card tap must give immediate visual/interactive feedback.
4. Screen responsiveness: Layout must adapt cleanly without RenderFlex overflow on various screen heights (e.g. Pixel 10 vs smaller iPhones).
5. State consistency: Triggering `[Kill All]` on Home must open the approval gate; ad-hoc CLI commands must immediately appear in the Live Terminal feed.

---

### Task 1: Design Tokens & Domain Data Models

**Files:**
- Create: `lib/theme/app_theme.dart`
- Create: `lib/models/models.dart`
- Test: `test/models_and_theme_test.dart`

**Interfaces:**
- Produces: `AppTheme` (colors: `bgMain`, `bgWarm`, `cardPeach`, `cardMint`, `darkPill`, `surfaceCard`, `accentOrange`, `statusGreen`, `statusAmber`, `statusRed`), `ThemeData`.
- Produces: `HardwareVitals`, `RunningTask`, `AgentItem`, `GoalItem`, `TerminalLog`, `ArtifactItem`.

- [ ] **Step 1: Write the failing test**

```dart
// test/models_and_theme_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:devpilot/theme/app_theme.dart';
import 'package:devpilot/models/models.dart';

void main() {
  test('AppTheme defines required color tokens', () {
    expect(AppTheme.bgMain.value, 0xFFFAF8F5);
    expect(AppTheme.cardPeach.value, 0xFFFCEAD2);
    expect(AppTheme.cardMint.value, 0xFFD8EFE9);
    expect(AppTheme.darkPill.value, 0xFF161618);
  });

  test('RunningTask formatted timer works', () {
    final task = RunningTask(
      id: 'task-1',
      pipelineName: 'Mobile Build',
      taskName: 'Compiling APK',
      startedAt: DateTime.now().subtract(const Duration(minutes: 4, seconds: 22)),
      phase: TaskPhase.compiling,
    );
    expect(task.elapsedString, matches(r'T\+\d{2}:\d{2}'));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd "$HOME/Documents/Fullstack Projects/devPolit/DevPilot" && flutter test test/models_and_theme_test.dart`
Expected: FAIL (files do not exist yet)

- [ ] **Step 3: Implement `lib/theme/app_theme.dart` and `lib/models/models.dart`**

Implement the design tokens, card shapes (`BorderRadius.circular(28)`), typography, and domain models with JSON-ready getters and helper formatters (`elapsedString`, `logColor`).

- [ ] **Step 4: Run test to verify it passes**

Run: `cd "$HOME/Documents/Fullstack Projects/devPolit/DevPilot" && flutter test test/models_and_theme_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/theme/app_theme.dart lib/models/models.dart test/models_and_theme_test.dart
git commit -m "feat: add design tokens and domain models"
```

---

### Task 2: Telemetry & Simulation Service

**Files:**
- Create: `lib/services/telemetry_service.dart`
- Test: `test/telemetry_service_test.dart`

**Interfaces:**
- Consumes: Models from `lib/models/models.dart`.
- Produces: `TelemetryService extends ChangeNotifier` exposing:
  - `RunningTask currentTask`
  - `HardwareVitals vitals`
  - `List<AgentItem> agents`
  - `List<GoalItem> goals`
  - `List<TerminalLog> logs`
  - `List<ArtifactItem> artifacts`
  - `void sendCliCommand(String command)`
  - `void triggerAction(String actionName)`
  - `void approvePendingGate()`
  - `void denyPendingGate()`

- [ ] **Step 1: Write the failing test**

```dart
// test/telemetry_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:devpilot/services/telemetry_service.dart';
import 'package:devpilot/models/models.dart';

void main() {
  test('TelemetryService initializes with mock agents and vitals', () {
    final service = TelemetryService(autoStart: false);
    expect(service.agents.isNotEmpty, true);
    expect(service.vitals.cpuPercent, inInclusiveRange(0, 100));
  });

  test('sendCliCommand appends input and simulated response to logs', () {
    final service = TelemetryService(autoStart: false);
    final initialCount = service.logs.length;
    service.sendCliCommand('flutter doctor');
    expect(service.logs.length, greaterThan(initialCount));
    expect(service.logs.last.message, contains('Doctor summary'));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd "$HOME/Documents/Fullstack Projects/devPolit/DevPilot" && flutter test test/telemetry_service_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement `lib/services/telemetry_service.dart`**

Implement periodic simulation ticker (`Timer.periodic`) that updates `currentTask.elapsedString`, gently fluctuates CPU/RAM vitals, periodically emits realistic logs, and provides command execution hooks.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd "$HOME/Documents/Fullstack Projects/devPolit/DevPilot" && flutter test test/telemetry_service_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/services/telemetry_service.dart test/telemetry_service_test.dart
git commit -m "feat: implement telemetry and real-time simulation service"
```

---

### Task 3: Home Screen Reusable Widgets (Running Task, Vitals & Agent Cards)

**Files:**
- Create: `lib/widgets/vitals_bar.dart`
- Create: `lib/widgets/macro_deck.dart`
- Create: `lib/widgets/running_task_card.dart`
- Create: `lib/widgets/agent_card.dart`
- Test: `test/home_widgets_test.dart`

**Interfaces:**
- Consumes: `TelemetryService`, `AppTheme`, models.
- Produces: Reusable tactile widgets matching Image 1 styling.

- [ ] **Step 1: Write the failing test**

```dart
// test/home_widgets_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devpilot/widgets/vitals_bar.dart';
import 'package:devpilot/models/models.dart';

void main() {
  testWidgets('VitalsBar renders CPU, RAM, NET and Battery', (tester) async {
    const vitals = HardwareVitals(
      cpuPercent: 42,
      ramPercent: 68,
      networkMBps: 12.4,
      batteryPercent: 88,
      isCharging: true,
    );
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: VitalsBar(vitals: vitals)),
    ));
    expect(find.textContaining('42%'), findsOneWidget);
    expect(find.textContaining('68%'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd "$HOME/Documents/Fullstack Projects/devPolit/DevPilot" && flutter test test/home_widgets_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement widgets**
- Implement `lib/widgets/vitals_bar.dart` (compact progress pills with icons).
- Implement `lib/widgets/macro_deck.dart` (4 tactile buttons: *Deploy*, *Run Tests*, *Restart Docker*, *Kill All*).
- Implement `lib/widgets/running_task_card.dart` (pulsing status chip, `T+MM:SS` timer, E2EE badge, vitals, macro deck).
- Implement `lib/widgets/agent_card.dart` (avatar, name, team badge, security clearance pill, current task).

- [ ] **Step 4: Run test to verify it passes**

Run: `cd "$HOME/Documents/Fullstack Projects/devPolit/DevPilot" && flutter test test/home_widgets_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/ test/home_widgets_test.dart
git commit -m "feat: add running task card, vitals bar, and agent cards"
```

---

### Task 4: Home Screen Assembly (Image 1 Aesthetic)

**Files:**
- Create: `lib/screens/home_screen.dart`
- Test: `test/home_screen_test.dart`

**Interfaces:**
- Consumes: `HomeScreen` takes `TelemetryService` and callback `onOpenProject(ProjectItem project)`.
- Produces: Full implementation of Image 1 (Header, greeting *"Hello, Wendy/Aryan"*, headline *"Your Projects (3)"*, peach & mint cards with ↗ arrow button, running task card directly below, agent roster carousel, and bottom navigation bar).

- [ ] **Step 1: Write the failing test**

```dart
// test/home_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devpilot/screens/home_screen.dart';
import 'package:devpilot/services/telemetry_service.dart';

void main() {
  testWidgets('HomeScreen renders greeting, projects, and running task', (tester) async {
    final service = TelemetryService(autoStart: false);
    await tester.pumpWidget(MaterialApp(
      home: HomeScreen(service: service, onOpenProject: (_) {}),
    ));
    expect(find.textContaining('Your Projects'), findsOneWidget);
    expect(find.text('Admin Dashboard'), findsOneWidget);
    expect(find.text('Wallet Mobile'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd "$HOME/Documents/Fullstack Projects/devPolit/DevPilot" && flutter test test/home_screen_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement `lib/screens/home_screen.dart`**

Assemble the complete Image 1 screen layout with custom curved pastel cards, smooth navigation to detail view, responsive scroll physics, and bottom navigation bar.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd "$HOME/Documents/Fullstack Projects/devPolit/DevPilot" && flutter test test/home_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/screens/home_screen.dart test/home_screen_test.dart
git commit -m "feat: assemble Image 1 home screen with projects and running task"
```

---

### Task 5: Detail & Pipeline Screen (Image 2 Aesthetic & Live Telemetry)

**Files:**
- Create: `lib/widgets/terminal_feed.dart`
- Create: `lib/widgets/artifact_stream.dart`
- Create: `lib/screens/detail_screen.dart`
- Test: `test/detail_screen_test.dart`

**Interfaces:**
- Consumes: `DetailScreen` takes `TelemetryService`, `ProjectItem`, and `onBack`.
- Produces: Full implementation of Image 2 (Warm beige background, `< Back` and `Done` buttons, title *"Planning & Pipeline"*, dark date/session card, share link pill, `Members (4)` row, and white rounded goals card containing goals, Live Terminal Feed, and Artifact Stream).

- [ ] **Step 1: Write the failing test**

```dart
// test/detail_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devpilot/screens/detail_screen.dart';
import 'package:devpilot/services/telemetry_service.dart';
import 'package:devpilot/models/models.dart';

void main() {
  testWidgets('DetailScreen renders planning header and goal steps', (tester) async {
    final service = TelemetryService(autoStart: false);
    final project = ProjectItem(
      id: 'p1',
      title: 'Planning',
      subtitle: 'November 18th, 2026',
      duration: '45 hours',
      colorType: CardColorType.peach,
    );
    await tester.pumpWidget(MaterialApp(
      home: DetailScreen(service: service, project: project, onBack: () {}),
    ));
    expect(find.text('Planning'), findsOneWidget);
    expect(find.textContaining('Goals'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd "$HOME/Documents/Fullstack Projects/devPolit/DevPilot" && flutter test test/detail_screen_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement `lib/widgets/terminal_feed.dart`, `lib/widgets/artifact_stream.dart`, and `lib/screens/detail_screen.dart`**

Build the live auto-scrolling terminal console, artifact preview carousel, and the Image 2 curved bottom card.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd "$HOME/Documents/Fullstack Projects/devPolit/DevPilot" && flutter test test/detail_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/terminal_feed.dart lib/widgets/artifact_stream.dart lib/screens/detail_screen.dart test/detail_screen_test.dart
git commit -m "feat: assemble Image 2 detail screen with terminal and artifacts"
```

---

### Task 6: Interactive Modals & Controls (Approval Gate, CLI Drawer, Agent Dossier)

**Files:**
- Create: `lib/widgets/modals/approval_modal.dart`
- Create: `lib/widgets/modals/cli_sheet.dart`
- Create: `lib/widgets/modals/agent_dossier_modal.dart`
- Create: `lib/widgets/modals/parameter_modal.dart`
- Test: `test/modals_test.dart`

**Interfaces:**
- Consumes: `TelemetryService`.
- Produces:
  - `ApprovalModal`: Biometric approval gate for AMBER security events.
  - `CliSheet`: Monospace slide-up drawer for ad-hoc command entry.
  - `AgentDossierModal`: MYCEL-inspired full dossier popup.
  - `ParameterModal`: Sliders and toggles for runtime arguments.

- [ ] **Step 1: Write the failing test**

```dart
// test/modals_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devpilot/widgets/modals/approval_modal.dart';

void main() {
  testWidgets('ApprovalModal renders action title and approve/deny buttons', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ApprovalModal(
          actionTitle: 'Kill All Processes',
          details: 'This will terminate all running background tasks.',
          onApprove: () {},
          onDeny: () {},
        ),
      ),
    ));
    expect(find.text('Kill All Processes'), findsOneWidget);
    expect(find.text('Approve Action'), findsOneWidget);
    expect(find.text('Deny'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd "$HOME/Documents/Fullstack Projects/devPolit/DevPilot" && flutter test test/modals_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement modals in `lib/widgets/modals/`**

Implement the 4 modal widgets with haptic feedback, slide-to-confirm, and rich MYCEL dossier details.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd "$HOME/Documents/Fullstack Projects/devPolit/DevPilot" && flutter test test/modals_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/modals/ test/modals_test.dart
git commit -m "feat: add approval gate, CLI drawer, agent dossier, and parameter modals"
```

---

### Task 7: App Wiring, Full Suite Verification & Live Emulator Deploy

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Connects `TelemetryService` provider at app root, connects `HomeScreen` to `DetailScreen`, wires up bottom navigation, macro triggers, and approval dialogs.

- [ ] **Step 1: Update `lib/main.dart` and `test/widget_test.dart`**
- [ ] **Step 2: Run full test suite & analyzer**

```bash
cd "$HOME/Documents/Fullstack Projects/devPolit/DevPilot"
flutter analyze
flutter test
```
Expected: 0 errors, all tests pass.

- [ ] **Step 3: Hot-restart & verify app on the active Android Emulator**

Deploy to `emulator-5554` and verify the live app running on screen.

- [ ] **Step 4: Commit**

```bash
git add lib/main.dart test/widget_test.dart
git commit -m "feat: wire DevPilot app, verify test suite, and deploy to emulator"
```
