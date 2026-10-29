import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devpilot/main.dart';
import 'package:devpilot/screens/home_screen.dart';
import 'package:devpilot/screens/detail_screen.dart';
import 'package:devpilot/services/telemetry_service.dart';
import 'package:devpilot/widgets/running_task_card.dart';
import 'package:devpilot/widgets/agent_card.dart';
import 'package:devpilot/widgets/terminal_feed.dart';
import 'package:devpilot/widgets/artifact_stream.dart';
import 'package:devpilot/widgets/modals/approval_modal.dart';
import 'package:devpilot/widgets/modals/cli_sheet.dart';
import 'package:devpilot/widgets/modals/parameter_modal.dart';
import 'package:devpilot/widgets/modals/agent_dossier_modal.dart';

void main() {
  group('DevPilotApp Root Wiring & Screen Navigation Tests', () {
    testWidgets(
      'DevPilotApp loads, renders greeting, projects, and running task',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final service = TelemetryService(autoStart: false);
        await tester.pumpWidget(DevPilotApp(service: service));
        await tester.pumpAndSettle();

        // Verify Greeting & Header
        expect(find.text('Hello, Aryan'), findsOneWidget);
        expect(find.text('DEV PILOT'), findsOneWidget);
        expect(find.textContaining('Your Projects'), findsOneWidget);

        // Verify Projects
        expect(find.text('Admin Dashboard'), findsOneWidget);
        expect(find.text('Wallet Mobile'), findsOneWidget);

        // Verify Running Task
        expect(find.byType(RunningTaskCard), findsOneWidget);
        expect(find.text('DevPilot Core Engine'), findsWidgets);

        // Verify absence of bottom navigation tabs
        expect(find.byType(BottomNavigationBar), findsNothing);
      },
    );

    testWidgets(
      'DevPilotApp navigates to DetailScreen and returns successfully',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final service = TelemetryService(autoStart: false);
        await tester.pumpWidget(DevPilotApp(service: service));
        await tester.pumpAndSettle();

        // Tap project card to navigate to DetailScreen
        await tester.tap(find.text('Admin Dashboard'));
        await tester.pumpAndSettle();

        // Verify DetailScreen is shown
        expect(find.byType(DetailScreen), findsOneWidget);
        expect(find.text('Admin Dashboard'), findsWidgets);
        expect(find.text('Done'), findsOneWidget);

        // Verify agents, terminal, and artifacts inside project screen
        expect(find.byType(AgentCard), findsWidgets);
        expect(find.byType(TerminalFeed), findsOneWidget);
        expect(find.byType(ArtifactStream), findsOneWidget);

        // Tap 'Done' to return to HomeScreen
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();

        // Verify back on HomeScreen
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.text('Hello, Aryan'), findsOneWidget);
      },
    );

    testWidgets(
      'DevPilotApp navigates to DetailScreen and returns via back icon',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final service = TelemetryService(autoStart: false);
        await tester.pumpWidget(DevPilotApp(service: service));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Admin Dashboard'));
        await tester.pumpAndSettle();

        expect(find.byType(DetailScreen), findsOneWidget);

        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.text('Hello, Aryan'), findsOneWidget);
      },
    );

    testWidgets('DevPilotApp opens CliSheet from quick bar and closes it', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final service = TelemetryService(autoStart: false);
      await tester.pumpWidget(DevPilotApp(service: service));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.terminal_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(CliSheet), findsOneWidget);
      expect(find.text('operator@devpilot:~\$ '), findsOneWidget);
      expect(find.text('flutter doctor'), findsOneWidget);

      // Close sheet
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(CliSheet), findsNothing);
    });

    testWidgets(
      'DevPilotApp opens ParameterModal from header icon and closes it',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final service = TelemetryService(autoStart: false);
        await tester.pumpWidget(DevPilotApp(service: service));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('header_grid_icon')));
        await tester.pumpAndSettle();

        expect(find.byType(ParameterModal), findsOneWidget);
        expect(find.text('Runtime Parameters'), findsOneWidget);

        // Tap Save & Apply
        await tester.tap(find.text('Save & Apply'));
        await tester.pumpAndSettle();

        expect(find.byType(ParameterModal), findsNothing);
      },
    );

    testWidgets(
      'DevPilotApp opens AgentDossierModal from agent card inside DetailScreen',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final service = TelemetryService(autoStart: false);
        await tester.pumpWidget(DevPilotApp(service: service));
        await tester.pumpAndSettle();

        // Navigate to DetailScreen where agents live
        await tester.tap(find.text('Admin Dashboard'));
        await tester.pumpAndSettle();

        // Ensure visible and tap Atlas AgentCard
        await tester.ensureVisible(find.byType(AgentCard).first);
        await tester.tap(find.byType(AgentCard).first);
        await tester.pumpAndSettle();

        expect(find.byType(AgentDossierModal), findsOneWidget);
        expect(find.byIcon(Icons.close_rounded), findsOneWidget);

        // Close dossier modal
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        expect(find.byType(AgentDossierModal), findsNothing);
      },
    );

    testWidgets(
      'DevPilotApp opens ApprovalModal on Kill All macro action and handles deny & approve',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final service = TelemetryService(autoStart: false);
        await tester.pumpWidget(DevPilotApp(service: service));
        await tester.pumpAndSettle();

        // Tap 'Kill All' on HomeScreen
        await tester.ensureVisible(find.text('Kill All'));
        await tester.tap(find.text('Kill All'));
        await tester.pumpAndSettle();

        // ApprovalModal should pop up
        expect(find.byType(ApprovalModal), findsOneWidget);
        expect(find.text('SECURITY CLEARANCE GATE'), findsOneWidget);
        expect(service.isPendingApproval, isTrue);

        // Tap Deny
        await tester.tap(find.text('Deny'));
        await tester.pumpAndSettle();

        expect(find.byType(ApprovalModal), findsNothing);
        expect(service.isPendingApproval, isFalse);
      },
    );

    testWidgets('DevPilotApp DetailScreen can trigger CliSheet modal', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final service = TelemetryService(autoStart: false);
      await tester.pumpWidget(DevPilotApp(service: service));
      await tester.pumpAndSettle();

      // Navigate to DetailScreen
      await tester.tap(find.text('Admin Dashboard'));
      await tester.pumpAndSettle();

      // Tap 'Open CLI Terminal' button
      await tester.ensureVisible(find.text('Open CLI Terminal'));
      await tester.tap(find.text('Open CLI Terminal'));
      await tester.pumpAndSettle();

      expect(find.byType(CliSheet), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(CliSheet), findsNothing);
    });

    testWidgets('DevPilotApp default constructor loads with MyApp alias', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Test MyApp alias and default service instantiation
      await tester.pumpWidget(const MyApp());
      await tester.pump();

      expect(find.text('Hello, Aryan'), findsOneWidget);
    });
  });
}
