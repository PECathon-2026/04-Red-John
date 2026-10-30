import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devpilot/screens/detail_screen.dart';
import 'package:devpilot/screens/diff_screen.dart';
import 'package:devpilot/screens/full_terminal_screen.dart';
import 'package:devpilot/screens/artifact_list_screen.dart';
import 'package:devpilot/services/telemetry_service.dart';
import 'package:devpilot/models/models.dart';
import 'package:devpilot/widgets/dicebear_avatar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DetailScreen & Monochrome Editorial Tests', () {
    late TelemetryService service;
    late ProjectItem project;

    setUp(() {
      service = TelemetryService(autoStart: false);
      project = const ProjectItem(
        id: 'p3',
        title: 'Planning',
        subtitle: 'November 18th, 2026',
        duration: '45 hours',
        colorType: CardColorType.lavender,
      );
    });

    tearDown(() {
      service.dispose();
    });

    testWidgets(
      'DetailScreen renders title, back button, live execution pill with timer, 4-goal preview, 3-col team, terminal, and artifacts',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            home: DetailScreen(
              service: service,
              project: project,
              onBack: () {},
            ),
          ),
        );

        // 1. Top bar title & actions
        expect(find.text('Planning'), findsWidgets);
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
        expect(find.byIcon(Icons.difference_outlined), findsOneWidget);
        expect(find.byIcon(Icons.more_horiz), findsOneWidget);

        // 2. Live execution pill with timer (timer ONLY appears here)
        expect(find.text('LIVE EXECUTION'), findsOneWidget);
        expect(find.text('RUNNING'), findsWidgets);

        // 3. Goals Preview (4 goals: 1 old completed, 1 current, 2 future)
        expect(find.text('GOALS'), findsOneWidget);
        expect(find.textContaining('View all'), findsWidgets);
        expect(find.text('Container Isolation & Sandboxing'), findsOneWidget);
        expect(find.text('Compile Native Assets & Shaders'), findsOneWidget);

        // 4. Team 3-Column Grid with Cute Avatars
        expect(find.text('TEAM MEMBERS'), findsOneWidget);
        expect(find.byType(CuteAvatar), findsWidgets);
        expect(find.text('Takeshi'), findsWidgets);

        // 5. Terminal Console
        expect(find.text('TERMINAL CONSOLE'), findsOneWidget);
        expect(find.text('LIVE'), findsWidgets);

        // 6. Artifacts Row
        expect(find.text('ARTIFACTS'), findsOneWidget);
      },
    );

    testWidgets('Tapping back button triggers onBack callback', (tester) async {
      int backCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: DetailScreen(
            service: service,
            project: project,
            onBack: () => backCount++,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(backCount, 1);
    });

    testWidgets('Tapping View all goals opens goals bottom sheet with assigned agent', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: DetailScreen(
            service: service,
            project: project,
            onBack: () {},
          ),
        ),
      );

      final viewAllGoals = find.textContaining('View all').first;
      await tester.tap(viewAllGoals);
      await tester.pumpAndSettle();

      expect(find.text('PIPELINE GOALS'), findsOneWidget);
      expect(find.text('ASSIGNED AGENT'), findsWidgets);
      expect(find.text('Atlas'), findsWidgets);
      expect(find.text('Parse Blueprint AST & Requirements'), findsOneWidget);
    });

    testWidgets('Tapping team member opens agent dossier modal', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: DetailScreen(
            service: service,
            project: project,
            onBack: () {},
          ),
        ),
      );

      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('team_cell_Takeshi')), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('MISSION STATEMENT'), findsOneWidget);
      expect(find.text('TOOL GRANTS'), findsOneWidget);
    });

    testWidgets('Tapping terminal console opens FullTerminalScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: DetailScreen(
            service: service,
            project: project,
            onBack: () {},
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('terminal_console_card')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('terminal_console_card')));
      await tester.pumpAndSettle();

      expect(find.byType(FullTerminalScreen), findsOneWidget);
    });

    testWidgets('Tapping Difference icon opens DiffScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: DetailScreen(
            service: service,
            project: project,
            onBack: () {},
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.difference_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(DiffScreen), findsOneWidget);
      expect(find.text('DIFF REVIEW'), findsOneWidget);
    });

    testWidgets('Tapping artifacts View all opens ArtifactListScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: DetailScreen(
            service: service,
            project: project,
            onBack: () {},
          ),
        ),
      );

      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -1200));
      await tester.pumpAndSettle();
      final viewAllArtifacts = find.textContaining('View all').last;
      await tester.tap(viewAllArtifacts);
      await tester.pumpAndSettle();

      expect(find.byType(ArtifactListScreen), findsOneWidget);
      expect(find.text('ALL ARTIFACTS'), findsOneWidget);
    });
  });
}
