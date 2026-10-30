import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devpilot/main.dart';
import 'package:devpilot/screens/onboarding_screen.dart';
import 'package:devpilot/screens/auth_screen.dart';
import 'package:devpilot/screens/home_screen.dart';
import 'package:devpilot/services/telemetry_service.dart';

void main() {
  group('OnboardingScreen Widget Tests', () {
    testWidgets('Renders first slide, pages through carousel, and finishes', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool finished = false;
      bool navigatedToLogin = false;

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            onFinish: () => finished = true,
            onNavigateToLogin: () => navigatedToLogin = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header and Slide 0 content
      expect(find.text('DEVPILOT'), findsOneWidget);
      expect(find.text('SKIP'), findsOneWidget);
      expect(find.text('AUTONOMOUS SWARM'), findsOneWidget);
      expect(find.text('Multi-Agent Mission Control'), findsOneWidget);
      expect(find.text('CONTINUE'), findsOneWidget);

      // Tap CONTINUE to advance to Slide 1
      await tester.tap(find.text('CONTINUE'));
      await tester.pumpAndSettle();

      expect(find.text('REAL-TIME TELEMETRY'), findsOneWidget);
      expect(find.text('Sub-Millisecond Vitals & Sandboxes'), findsOneWidget);

      // Tap CONTINUE to advance to Slide 2
      await tester.tap(find.text('CONTINUE'));
      await tester.pumpAndSettle();

      expect(find.text('HUMAN-IN-THE-LOOP'), findsOneWidget);
      expect(find.text('Precision Verification Gates'), findsOneWidget);
      expect(find.text('GET STARTED'), findsOneWidget);

      // Tap GET STARTED to finish onboarding
      await tester.tap(find.text('GET STARTED'));
      await tester.pumpAndSettle();

      expect(finished, isTrue);

      // Tap SKIP link
      await tester.tap(find.text('SKIP'));
      await tester.pumpAndSettle();
      expect(navigatedToLogin, isTrue);
    });
  });

  group('AuthScreen Widget Tests', () {
    testWidgets('Switches tabs between Sign In and Create Account, validates inputs, and submits',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool success = false;
      bool backed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(
            onSuccess: () => success = true,
            onBack: () => backed = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check default Sign In state
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('SIGN IN'), findsOneWidget);
      expect(find.text('CREATE ACCOUNT'), findsOneWidget);
      expect(find.text('SIGN IN TO CONSOLE'), findsOneWidget);
      expect(find.text('Explore in Demo Mode'), findsOneWidget);

      // Switch to CREATE ACCOUNT tab
      await tester.tap(find.text('CREATE ACCOUNT'));
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('DEVELOPER NAME'), findsOneWidget);
      expect(find.text('INITIALIZE ACCOUNT'), findsOneWidget);

      // Switch back to SIGN IN tab
      await tester.tap(find.text('SIGN IN'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);

      // Tap Submit and verify success after brief simulated auth
      await tester.tap(find.text('SIGN IN TO CONSOLE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(success, isTrue);

      // Tap Back button
      await tester.tap(find.byKey(const Key('auth_back_button')));
      await tester.pumpAndSettle();
      expect(backed, isTrue);
    });

    testWidgets('Allows instantaneous Demo Mode bypass', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool demoPassed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(
            onSuccess: () => demoPassed = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('demo_mode_button')));
      await tester.pumpAndSettle();

      expect(demoPassed, isTrue);
    });
  });

  group('DevPilotApp Boot Routing Tests', () {
    testWidgets('DevPilotApp with showOnboarding=true transitions to Auth and Home',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final service = TelemetryService(autoStart: false);
      await tester.pumpWidget(
        DevPilotApp(
          service: service,
          showOnboarding: true,
        ),
      );
      await tester.pumpAndSettle();

      // Verify starts in OnboardingScreen
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('Multi-Agent Mission Control'), findsOneWidget);

      // Tap SKIP to go to AuthScreen
      await tester.tap(find.text('SKIP'));
      await tester.pumpAndSettle();

      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.text('Welcome back'), findsOneWidget);

      // Tap Explore in Demo Mode to enter Home
      await tester.tap(find.text('Explore in Demo Mode'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('hello,'), findsOneWidget);
      expect(find.text('Aryan'), findsOneWidget);
    });
  });
}
