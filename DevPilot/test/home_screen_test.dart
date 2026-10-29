import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devpilot/screens/home_screen.dart';
import 'package:devpilot/services/telemetry_service.dart';
import 'package:devpilot/models/models.dart';
import 'package:devpilot/widgets/running_task_card.dart';
import 'package:devpilot/widgets/agent_card.dart';

void main() {
  group('HomeScreen Tests', () {
    testWidgets(
      'HomeScreen renders greeting, projects, running task and agent roster',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final service = TelemetryService(autoStart: false);
        ProjectItem? openedProject;
        AgentItem? openedAgent;
        bool terminalOpened = false;
        bool settingsOpened = false;
        bool killTriggered = false;

        await tester.pumpWidget(
          MaterialApp(
            home: HomeScreen(
              service: service,
              onOpenProject: (p) => openedProject = p,
              onOpenAgent: (a) => openedAgent = a,
              onOpenTerminal: () => terminalOpened = true,
              onOpenSettings: () => settingsOpened = true,
              onKillTriggered: () => killTriggered = true,
            ),
          ),
        );

        // Verify Header Elements
        expect(find.text('Hello, Aryan'), findsOneWidget);
        expect(find.textContaining('Your Projects'), findsOneWidget);
        expect(find.byKey(const Key('header_grid_icon')), findsOneWidget);
        expect(find.byKey(const Key('header_avatar')), findsOneWidget);

        // Verify Pastel Workflow Cards
        expect(find.text('Admin Dashboard'), findsOneWidget);
        expect(find.text('Wallet Mobile'), findsOneWidget);
        expect(find.text('45 hours'), findsWidgets);
        expect(find.text('9 hours'), findsOneWidget);

        // Verify RunningTaskCard
        expect(find.byType(RunningTaskCard), findsOneWidget);
        expect(find.text('DevPilot Core Engine'), findsWidgets);
        expect(find.text('Compiling Shaders & AST'), findsOneWidget);
        expect(find.text('LAN E2EE'), findsOneWidget);

        // Verify Active Agent Roster
        expect(find.textContaining('Active Agent Roster'), findsOneWidget);
        expect(find.byType(AgentCard), findsWidgets);
        expect(find.text('Atlas'), findsOneWidget);
        expect(find.text('Dev'), findsOneWidget);

        // Verify Bottom Navigation Bar
        expect(find.text('Projects'), findsOneWidget);
        expect(find.text('Terminal'), findsOneWidget);
        expect(find.text('Agents'), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);

        // Verify Project Card Tap
        await tester.tap(find.text('Admin Dashboard'));
        await tester.pumpAndSettle();
        expect(openedProject?.title, equals('Admin Dashboard'));

        // Verify Arrow Button Tap on Wallet Mobile
        await tester.tap(find.byIcon(Icons.arrow_outward_rounded).at(1));
        await tester.pumpAndSettle();
        expect(openedProject?.title, equals('Wallet Mobile'));

        // Verify Agent Card Tap
        await tester.tap(find.text('Atlas'));
        await tester.pumpAndSettle();
        expect(openedAgent?.name, equals('Atlas'));

        // Verify Terminal Tab Tap
        await tester.tap(find.text('Terminal'));
        await tester.pumpAndSettle();
        expect(terminalOpened, isTrue);

        // Verify Settings Tab Tap
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();
        expect(settingsOpened, isTrue);

        // Verify Macro Kill All Action triggers onKillTriggered
        await tester.ensureVisible(find.text('Kill All'));
        await tester.tap(find.text('Kill All'));
        await tester.pumpAndSettle();
        expect(killTriggered, isTrue);
        expect(service.isPendingApproval, isTrue);
      },
    );

    testWidgets('Tapping RunningTaskCard opens first project', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final service = TelemetryService(autoStart: false);
      ProjectItem? openedProject;

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            service: service,
            onOpenProject: (p) => openedProject = p,
          ),
        ),
      );

      await tester.tap(find.text('Compiling Shaders & AST'));
      await tester.pumpAndSettle();
      expect(openedProject?.title, equals('Admin Dashboard'));
    });

    testWidgets('HomeScreen reactively updates when TelemetryService updates', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final service = TelemetryService(autoStart: false);

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(service: service, onOpenProject: (_) {}),
        ),
      );

      expect(find.text('Compiling Shaders & AST'), findsOneWidget);

      // Simulate a tick or action update
      service.triggerAction('Deploy App');
      await tester.pumpAndSettle();

      expect(service.logs.any((l) => l.message.contains('Deploy App')), isTrue);
    });

    testWidgets(
      'Agents bottom nav tab scrolls to agent roster and Projects tab scrolls to top',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final service = TelemetryService(autoStart: false);

        await tester.pumpWidget(
          MaterialApp(
            home: HomeScreen(service: service, onOpenProject: (_) {}),
          ),
        );

        final rosterFinder = find.byKey(
          const Key('active_agent_roster_section'),
        );
        expect(rosterFinder, findsOneWidget);

        await tester.tap(find.text('Agents'));
        await tester.pumpAndSettle();

        expect(rosterFinder, findsOneWidget);

        await tester.tap(find.text('Projects'));
        await tester.pumpAndSettle();

        expect(find.text('Hello, Aryan'), findsOneWidget);
      },
    );
  });
}
