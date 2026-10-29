import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devpilot/screens/home_screen.dart';
import 'package:devpilot/services/telemetry_service.dart';
import 'package:devpilot/models/models.dart';
import 'package:devpilot/widgets/running_task_card.dart';

void main() {
  group('HomeScreen Tests', () {
    testWidgets(
      'HomeScreen renders editorial header, ember alert dot, metric strip, projects and running task',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final service = TelemetryService(autoStart: false);
        ProjectItem? openedProject;
        bool terminalOpened = false;
        bool settingsOpened = false;
        bool killTriggered = false;

        await tester.pumpWidget(
          MaterialApp(
            home: HomeScreen(
              service: service,
              onOpenProject: (p) => openedProject = p,
              onOpenTerminal: () => terminalOpened = true,
              onOpenSettings: () => settingsOpened = true,
              onKillTriggered: () => killTriggered = true,
            ),
          ),
        );

        // Verify Header Elements
        expect(find.text('Hello, Aryan'), findsOneWidget);
        expect(find.text('DEV PILOT'), findsOneWidget);
        expect(find.textContaining('Your Projects'), findsOneWidget);
        expect(find.byKey(const Key('header_avatar')), findsOneWidget);
        expect(find.byKey(const Key('header_grid_icon')), findsOneWidget);
        expect(find.byKey(const Key('ember_alert_dot')), findsOneWidget);

        // Verify Metric Strip
        expect(find.text('SYSTEM VITALS'), findsOneWidget);
        expect(find.text('PIPELINE HEALTH'), findsOneWidget);

        // Verify Workflow Cards
        expect(find.text('Admin Dashboard'), findsOneWidget);
        expect(find.text('Wallet Mobile'), findsOneWidget);
        expect(find.text('45 hours'), findsWidgets);
        expect(find.text('9 hours'), findsOneWidget);

        // Verify RunningTaskCard
        expect(find.byType(RunningTaskCard), findsOneWidget);
        expect(find.text('DevPilot Core Engine'), findsWidgets);
        expect(find.text('Compiling Shaders & AST'), findsOneWidget);
        expect(find.text('LAN E2EE'), findsOneWidget);

        // Verify Absence of bottom tabs
        expect(find.text('Agents'), findsNothing);
        expect(find.text('Terminal'), findsNothing);
        expect(find.byType(BottomNavigationBar), findsNothing);

        // Verify Project Card Tap
        await tester.tap(find.text('Admin Dashboard'));
        await tester.pumpAndSettle();
        expect(openedProject?.title, equals('Admin Dashboard'));

        // Verify Arrow Button Tap on Wallet Mobile
        await tester.tap(find.byIcon(Icons.arrow_outward_rounded).at(1));
        await tester.pumpAndSettle();
        expect(openedProject?.title, equals('Wallet Mobile'));

        // Verify Settings Button Tap
        await tester.tap(find.byKey(const Key('header_grid_icon')));
        await tester.pumpAndSettle();
        expect(settingsOpened, isTrue);

        // Verify Terminal Button Tap
        await tester.tap(find.byIcon(Icons.terminal_rounded));
        await tester.pumpAndSettle();
        expect(terminalOpened, isTrue);

        // Verify Macro Kill All Action triggers onKillTriggered
        await tester.ensureVisible(find.text('Kill All'));
        await tester.tap(find.text('Kill All'));
        await tester.pumpAndSettle();
        expect(killTriggered, isTrue);
      },
    );

    testWidgets('Tapping RunningTaskCard opens active project', (tester) async {
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

      await tester.ensureVisible(find.byType(RunningTaskCard));
      await tester.tap(find.byType(RunningTaskCard));
      await tester.pumpAndSettle();

      expect(openedProject?.title, equals('Admin Dashboard'));
    });
  });
}
