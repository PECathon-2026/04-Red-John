import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devpilot/main.dart';
import 'package:devpilot/screens/home_screen.dart';
import 'package:devpilot/screens/detail_screen.dart';
import 'package:devpilot/screens/full_terminal_screen.dart';
import 'package:devpilot/screens/artifact_list_screen.dart';
import 'package:devpilot/services/telemetry_service.dart';
import 'package:devpilot/widgets/bottom_nav.dart';
import 'package:devpilot/widgets/modals/parameter_modal.dart';

void main() {
  group('DevPilotApp Root Wiring & Navigation Tests', () {
    testWidgets(
      'DevPilotApp loads with Monochrome Editorial header, launch widget, projects, and bottom nav',
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

        // Verify Greeting & Header (no avatar, small hello, front name Aryan)
        expect(find.text('DEVPILOT'), findsOneWidget);
        expect(find.text('hello,'), findsOneWidget);
        expect(find.text('Aryan'), findsOneWidget);
        expect(find.byKey(const Key('header_avatar')), findsNothing);

        // Verify Launch Mission Widget
        expect(find.text('LAUNCH NEW MISSION'), findsOneWidget);

        // Verify Projects Section
        expect(find.text('PROJECTS'), findsWidgets);
        expect(find.text('Admin Dashboard'), findsOneWidget);

        // Verify 5-item Bottom Navigation Bar
        expect(find.byType(AppBottomNav), findsOneWidget);
        expect(find.text('HOME'), findsOneWidget);
        expect(find.text('PROJECTS'), findsWidgets);
        expect(find.text('TERMINAL'), findsOneWidget);
        expect(find.text('ARTIFACTS'), findsOneWidget);
        expect(find.text('SETTINGS'), findsOneWidget);
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

        // Tap project card to navigate to DetailScreen
        await tester.tap(find.text('Admin Dashboard'));
        await tester.pumpAndSettle();

        // Verify DetailScreen is shown
        expect(find.byType(DetailScreen), findsOneWidget);
        expect(find.text('Admin Dashboard'), findsWidgets);

        // Tap back arrow icon to return to HomeScreen
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        // Verify back on HomeScreen
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.text('hello,'), findsOneWidget);
      },
    );

    testWidgets('DevPilotApp switches tabs via AppBottomNav', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final service = TelemetryService(autoStart: false);
      await tester.pumpWidget(DevPilotApp(service: service));
      await tester.pumpAndSettle();

      // Tap TERMINAL tab in bottom navigation
      await tester.tap(find.text('TERMINAL'));
      await tester.pumpAndSettle();
      expect(find.byType(FullTerminalScreen), findsOneWidget);

      // Tap ARTIFACTS tab in bottom navigation
      await tester.tap(find.text('ARTIFACTS'));
      await tester.pumpAndSettle();
      expect(find.byType(ArtifactListScreen), findsOneWidget);

      // Tap SETTINGS tab in bottom navigation (opens ParameterModal)
      await tester.tap(find.text('SETTINGS'));
      await tester.pumpAndSettle();
      expect(find.byType(ParameterModal), findsOneWidget);

      // Close modal
      await tester.tap(find.text('Save & Apply'));
      await tester.pumpAndSettle();

      // Return to HOME tab
      await tester.tap(find.text('HOME'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('DevPilotApp default constructor loads with MyApp alias', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Test MyApp alias and default service instantiation
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.text('hello,'), findsOneWidget);
      expect(find.text('Aryan'), findsOneWidget);
    });
  });
}
