import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devpilot/screens/home_screen.dart';
import 'package:devpilot/services/telemetry_service.dart';
import 'package:devpilot/models/models.dart';
import 'package:devpilot/widgets/dicebear_avatar.dart';

void main() {
  group('HomeScreen Tests - Monochrome Editorial Redesign', () {
    testWidgets(
      'HomeScreen renders editorial header without avatar, launch widget, projects, current agent, past executions, and system vitals',
      (tester) async {
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

        // 1. Verify Greeting Elements (no avatar, small hello, front name Aryan, single + button)
        expect(find.text('DEVPILOT'), findsOneWidget);
        expect(find.text('hello,'), findsOneWidget);
        expect(find.text('Aryan'), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
        // Ensure avatar is NOT present
        expect(find.byKey(const Key('header_avatar')), findsNothing);

        // 2. Verify Launch Mission Widget
        expect(find.text('LAUNCH NEW MISSION'), findsOneWidget);
        expect(find.text('Build something new →'), findsOneWidget);
        expect(find.text('START MISSION'), findsOneWidget);

        // 3. Verify Projects Section (no pill buttons)
        expect(find.text('PROJECTS'), findsOneWidget);
        expect(find.text('Admin Dashboard'), findsOneWidget);
        expect(find.text('Wallet Mobile'), findsOneWidget);

        // 4. Verify Current Execution Section (only running agent, no system stats)
        expect(find.text('CURRENT EXECUTION'), findsOneWidget);
        expect(find.byType(CuteAvatar), findsWidgets);
        expect(find.text('RUNNING'), findsWidgets);

        // 5. Verify Past Executions Section
        expect(find.text('PAST EXECUTIONS'), findsOneWidget);
        expect(find.text('View all →'), findsOneWidget);
        expect(find.text('Feature Discounts 15%'), findsOneWidget);

        // 6. Verify System Vitals Section
        expect(find.text('SYSTEM VITALS'), findsOneWidget);
        expect(find.text('CPU LOAD'), findsOneWidget);
        expect(find.text('RAM USAGE'), findsOneWidget);
        expect(find.text('NETWORK'), findsOneWidget);
        expect(find.text('BATTERY'), findsOneWidget);

        // Verify Project Tap
        await tester.tap(find.text('Admin Dashboard'));
        await tester.pumpAndSettle();
        expect(openedProject?.title, equals('Admin Dashboard'));
      },
    );

    testWidgets('Tapping running agent opens active project', (tester) async {
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

      // Tap on running execution card
      await tester.ensureVisible(find.text('CURRENT EXECUTION'));
      await tester.tap(find.text('RUNNING').first);
      await tester.pumpAndSettle();

      expect(openedProject?.title, equals('Admin Dashboard'));
    });
  });
}
