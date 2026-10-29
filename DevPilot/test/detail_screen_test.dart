import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devpilot/screens/detail_screen.dart';
import 'package:devpilot/widgets/terminal_feed.dart';
import 'package:devpilot/widgets/artifact_stream.dart';
import 'package:devpilot/widgets/agent_card.dart';
import 'package:devpilot/widgets/vitals_bar.dart';
import 'package:devpilot/widgets/macro_deck.dart';
import 'package:devpilot/services/telemetry_service.dart';
import 'package:devpilot/models/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DetailScreen & Image 2 Aesthetic Tests', () {
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
      'DetailScreen renders planning header, session pills, members and goals',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: DetailScreen(
              service: service,
              project: project,
              onBack: () {},
            ),
          ),
        );

        // Title & Subtitle
        expect(find.text('Planning'), findsWidgets);
        expect(find.text('November 18th, 2026'), findsOneWidget);

        // Top bar actions
        expect(find.text('Done'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);

        // Session pills
        expect(find.text('21'), findsOneWidget);
        expect(find.text('devpilot.lan'), findsOneWidget);
        expect(find.textContaining('Share link'), findsOneWidget);

        // Members / Agents section
        expect(find.textContaining('Members'), findsOneWidget);
        expect(find.textContaining('Send telemetry reminder'), findsOneWidget);

        // White sheet with Goals
        expect(find.textContaining('Goals'), findsOneWidget);
        expect(find.text('Parse Blueprint AST & Requirements'), findsOneWidget);

        // Embedded Terminal Feed and Artifact Stream
        expect(find.byType(TerminalFeed), findsOneWidget);
        expect(find.byType(ArtifactStream), findsOneWidget);

        // Embedded Active Agent Roster and Host Vitals/Macros inside project screen
        expect(find.byType(AgentCard), findsWidgets);
        expect(find.text('Atlas'), findsOneWidget);
        expect(find.text('Dev'), findsOneWidget);
        expect(find.byType(VitalsBar), findsOneWidget);
        expect(find.byType(MacroDeck), findsOneWidget);

        // Open CLI terminal button
        expect(find.text('Open CLI Terminal'), findsOneWidget);
      },
    );

    testWidgets('Tapping Back and Done triggers onBack callback', (
      tester,
    ) async {
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
      await tester.pump(const Duration(milliseconds: 200));
      expect(backCount, 1);

      await tester.tap(find.text('Done'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(backCount, 2);
    });

    testWidgets('Tapping Share Link copies to clipboard and shows SnackBar', (
      tester,
    ) async {
      final List<MethodCall> log = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (
            MethodCall methodCall,
          ) async {
            log.add(methodCall);
            return null;
          });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DetailScreen(
              service: service,
              project: project,
              onBack: () {},
            ),
          ),
        ),
      );

      final shareBtn = find.textContaining('Share link');
      expect(shareBtn, findsOneWidget);
      await tester.tap(shareBtn);
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('copied to clipboard'), findsOneWidget);
    });

    testWidgets('Tapping Open CLI Terminal triggers onOpenCli', (tester) async {
      bool cliOpened = false;
      await tester.pumpWidget(
        MaterialApp(
          home: DetailScreen(
            service: service,
            project: project,
            onBack: () {},
            onOpenCli: () => cliOpened = true,
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Open CLI Terminal'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Open CLI Terminal'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(cliOpened, isTrue);
    });

    testWidgets('DetailScreen updates reactively when service emits new log', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DetailScreen(service: service, project: project, onBack: () {}),
        ),
      );

      expect(
        find.textContaining('Custom reactive telemetry line'),
        findsNothing,
      );

      service.sendCliCommand('Custom reactive telemetry line');
      await tester.pump();

      expect(
        find.textContaining('Custom reactive telemetry line'),
        findsOneWidget,
      );
    });
  });

  group('TerminalFeed Component Tests', () {
    testWidgets(
      'TerminalFeed renders monospace logs, live indicator, and clear button',
      (tester) async {
        final logs = [
          TerminalLog(
            id: '1',
            timestamp: DateTime.now(),
            message: '[BOOT] System loaded successfully',
            type: LogType.success,
          ),
          TerminalLog(
            id: '2',
            timestamp: DateTime.now(),
            message: '[ERR] Null pointer detected in runner',
            type: LogType.error,
          ),
        ];

        bool cleared = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TerminalFeed(logs: logs, onClear: () => cleared = true),
            ),
          ),
        );

        expect(
          find.textContaining('[BOOT] System loaded successfully'),
          findsOneWidget,
        );
        expect(
          find.textContaining('[ERR] Null pointer detected in runner'),
          findsOneWidget,
        );
        expect(find.textContaining('2 entries'), findsOneWidget);

        // Clear button
        final clearBtn = find.byIcon(Icons.delete_outline_rounded);
        expect(clearBtn, findsOneWidget);
        await tester.tap(clearBtn);
        await tester.pump();
        expect(cleared, isTrue);
      },
    );
  });

  group('ArtifactStream Component Tests', () {
    testWidgets(
      'ArtifactStream renders horizontal cards with icons and triggers onArtifactTap',
      (tester) async {
        final artifacts = [
          ArtifactItem(
            id: 'a1',
            name: 'release.apk',
            size: '28.4 MB',
            type: ArtifactType.apk,
            timestamp: DateTime.now(),
          ),
          ArtifactItem(
            id: 'a2',
            name: 'benchmark.pdf',
            size: '840 KB',
            type: ArtifactType.document,
            timestamp: DateTime.now(),
          ),
        ];

        ArtifactItem? tappedArtifact;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ArtifactStream(
                artifacts: artifacts,
                onArtifactTap: (art) => tappedArtifact = art,
              ),
            ),
          ),
        );

        expect(find.text('release.apk'), findsOneWidget);
        expect(find.text('28.4 MB'), findsOneWidget);
        expect(find.text('benchmark.pdf'), findsOneWidget);
        expect(find.text('840 KB'), findsOneWidget);

        await tester.tap(find.text('release.apk'));
        await tester.pump();
        expect(tappedArtifact?.name, 'release.apk');
      },
    );
  });
}
