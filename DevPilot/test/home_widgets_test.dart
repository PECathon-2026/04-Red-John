import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devpilot/models/models.dart';
import 'package:devpilot/theme/app_theme.dart';
import 'package:devpilot/widgets/vitals_bar.dart';
import 'package:devpilot/widgets/macro_deck.dart';
import 'package:devpilot/widgets/running_task_card.dart';
import 'package:devpilot/widgets/agent_card.dart';

void main() {
  group('VitalsBar Widget', () {
    testWidgets('renders CPU, RAM, NET and Battery with charging indicator', (
      tester,
    ) async {
      const vitals = HardwareVitals(
        cpuPercent: 42,
        ramPercent: 68,
        networkMBps: 12.4,
        batteryPercent: 88,
        isCharging: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: VitalsBar(vitals: vitals)),
        ),
      );

      expect(find.textContaining('42%'), findsOneWidget);
      expect(find.textContaining('68%'), findsOneWidget);
      expect(find.textContaining('12.4 MB/s'), findsOneWidget);
      expect(find.textContaining('88%'), findsOneWidget);
      expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);
    });

    testWidgets(
      'renders battery without bolt when not charging and warning when low',
      (tester) async {
        const vitals = HardwareVitals(
          cpuPercent: 90,
          ramPercent: 75,
          networkMBps: 2.0,
          batteryPercent: 14,
          isCharging: false,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: VitalsBar(vitals: vitals, compact: true)),
          ),
        );

        expect(find.textContaining('14%'), findsOneWidget);
        expect(find.byIcon(Icons.bolt_rounded), findsNothing);
        expect(find.byIcon(Icons.battery_alert_rounded), findsOneWidget);
      },
    );
  });

  group('MacroDeck Widget', () {
    testWidgets('renders all 4 action pills and triggers callback on tap', (
      tester,
    ) async {
      String? clickedAction;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MacroDeck(
              onActionTriggered: (action) {
                clickedAction = action;
              },
            ),
          ),
        ),
      );

      expect(find.text('Deploy'), findsOneWidget);
      expect(find.text('Run Tests'), findsOneWidget);
      expect(find.text('Restart Docker'), findsOneWidget);
      expect(find.text('Kill All'), findsOneWidget);

      await tester.tap(find.text('Deploy'));
      await tester.pumpAndSettle();
      expect(clickedAction, equals('Deploy'));

      await tester.tap(find.text('Run Tests'));
      await tester.pumpAndSettle();
      expect(clickedAction, equals('Run Tests'));

      await tester.tap(find.text('Restart Docker'));
      await tester.pumpAndSettle();
      expect(clickedAction, equals('Restart Docker'));

      await tester.tap(find.text('Kill All'));
      await tester.pumpAndSettle();
      expect(clickedAction, equals('Kill All'));
    });

    testWidgets('Kill All is styled with destructive indicator', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MacroDeck(onActionTriggered: (_) {})),
        ),
      );

      final killText = tester.widget<Text>(find.text('Kill All'));
      expect(killText.style?.color, equals(AppTheme.statusRed));
    });
  });

  group('RunningTaskCard Widget', () {
    testWidgets(
      'renders pipeline title, task name, status chip, elapsed timer and badges',
      (tester) async {
        final task = RunningTask(
          id: 'task-101',
          pipelineName: 'DevPilot Mobile Release Build',
          taskName: 'Compiling Native APK & Assets',
          startedAt: DateTime.now().subtract(
            const Duration(minutes: 5, seconds: 12),
          ),
          phase: TaskPhase.compiling,
          progress: 0.55,
          securityBadge: 'LAN E2EE',
          customElapsed: const Duration(minutes: 5, seconds: 12),
        );

        const vitals = HardwareVitals(
          cpuPercent: 78,
          ramPercent: 82,
          networkMBps: 24.5,
          batteryPercent: 92,
          isCharging: true,
        );

        String? triggeredAction;
        bool cardTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RunningTaskCard(
                task: task,
                vitals: vitals,
                onMacroAction: (action) {
                  triggeredAction = action;
                },
                onTap: () {
                  cardTapped = true;
                },
              ),
            ),
          ),
        );

        expect(find.text('DevPilot Mobile Release Build'), findsOneWidget);
        expect(find.text('Compiling Native APK & Assets'), findsOneWidget);
        expect(find.text('Compiling'), findsOneWidget);
        expect(find.text('T+05:12'), findsOneWidget);
        expect(find.text('LAN E2EE'), findsOneWidget);
        expect(find.text('55%'), findsOneWidget);

        // Embedded VitalsBar check
        expect(find.textContaining('78%'), findsOneWidget);
        expect(find.textContaining('82%'), findsOneWidget);

        // Embedded MacroDeck check
        expect(find.text('Deploy'), findsOneWidget);
        await tester.tap(find.text('Deploy'));
        await tester.pumpAndSettle();
        expect(triggeredAction, equals('Deploy'));

        // Card tap check
        await tester.tap(find.text('DevPilot Mobile Release Build'));
        await tester.pumpAndSettle();
        expect(cardTapped, isTrue);
      },
    );

    testWidgets(
      'renders different TaskPhases properly (e.g. Success, Deploying)',
      (tester) async {
        final task = RunningTask(
          id: 'task-102',
          pipelineName: 'Fast Deployment Hook',
          taskName: 'Deploying Container to Cluster',
          startedAt: DateTime.now().subtract(const Duration(seconds: 45)),
          phase: TaskPhase.deploying,
          progress: 0.90,
        );

        const vitals = HardwareVitals();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RunningTaskCard(
                task: task,
                vitals: vitals,
                onMacroAction: (_) {},
              ),
            ),
          ),
        );

        expect(find.text('Deploying'), findsOneWidget);
        expect(find.text('90%'), findsOneWidget);
      },
    );
  });

  group('AgentCard Widget', () {
    testWidgets('renders agent details, team badge, clearance chip and timer', (
      tester,
    ) async {
      const agent = AgentItem(
        id: 'agent-1',
        name: 'AANYA',
        team: 'Architecture',
        clearance: 'GREEN',
        phase: 'Working',
        currentTask: 'Analyzing AST call-graph dependencies',
        elapsed: '04:15',
        bio: 'Chief System Architect',
      );

      bool agentTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AgentCard(
              agent: agent,
              onTap: () {
                agentTapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('AANYA'), findsOneWidget);
      expect(find.text('Architecture'), findsOneWidget);
      expect(find.text('GREEN'), findsOneWidget);
      expect(find.text('Working'), findsOneWidget);
      expect(
        find.text('Analyzing AST call-graph dependencies'),
        findsOneWidget,
      );
      expect(find.text('T+04:15'), findsOneWidget);

      await tester.tap(find.text('AANYA'));
      await tester.pumpAndSettle();
      expect(agentTapped, isTrue);
    });

    testWidgets('renders AMBER clearance and Resilience team badge correctly', (
      tester,
    ) async {
      const agent = AgentItem(
        id: 'agent-2',
        name: 'KABIR',
        team: 'Resilience',
        clearance: 'AMBER',
        phase: 'Done',
        currentTask: 'Circuit breaker verification passed',
        elapsed: '12:30',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AgentCard(agent: agent)),
        ),
      );

      expect(find.text('KABIR'), findsOneWidget);
      expect(find.text('Resilience'), findsOneWidget);
      expect(find.text('AMBER'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('T+12:30'), findsOneWidget);
    });
  });
}
