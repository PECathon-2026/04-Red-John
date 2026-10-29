import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devpilot/theme/app_theme.dart';
import 'package:devpilot/models/models.dart';

void main() {
  group('AppTheme Tokens & ThemeData', () {
    test('AppTheme defines required color tokens', () {
      expect(AppTheme.bgMain.toARGB32(), 0xFFFAF8F5);
      expect(AppTheme.bgWarm.toARGB32(), 0xFFF6ECD9);
      expect(AppTheme.cardPeach.toARGB32(), 0xFFFCEAD2);
      expect(AppTheme.cardMint.toARGB32(), 0xFFD8EFE9);
      expect(AppTheme.cardLavender.toARGB32(), 0xFFE8E0F2);
      expect(AppTheme.darkPill.toARGB32(), 0xFF161618);
      expect(AppTheme.surfaceCard.toARGB32(), 0xFFFFFFFF);
      expect(AppTheme.accentOrange.toARGB32(), 0xFFE07A4C);
      expect(AppTheme.statusGreen.toARGB32(), 0xFF34C759);
      expect(AppTheme.statusAmber.toARGB32(), 0xFFFFB300);
      expect(AppTheme.statusRed.toARGB32(), 0xFFFF3B30);
    });

    test('AppTheme defines shapes and ThemeData', () {
      expect(AppTheme.cardRadius, BorderRadius.circular(28));
      expect(AppTheme.sheetRadius, BorderRadius.circular(32));
      expect(AppTheme.pillRadius, BorderRadius.circular(999));

      final theme = AppTheme.lightTheme;
      expect(theme.scaffoldBackgroundColor, AppTheme.bgMain);
      expect(theme.cardColor, AppTheme.surfaceCard);
      expect(theme.useMaterial3, isTrue);
    });
  });

  group('Domain Models', () {
    test('RunningTask formatted timer works', () {
      final task = RunningTask(
        id: 'task-1',
        pipelineName: 'Mobile Build',
        taskName: 'Compiling APK',
        startedAt: DateTime.now().subtract(
          const Duration(minutes: 4, seconds: 22),
        ),
        phase: TaskPhase.compiling,
      );
      expect(task.elapsedString, matches(r'T\+\d{2}:\d{2}'));
      expect(task.securityBadge, 'LAN E2EE');
      expect(task.isE2eeEncrypted, isTrue);
    });

    test('HardwareVitals formats gauges correctly', () {
      const vitals = HardwareVitals(
        cpuPercent: 42.0,
        ramPercent: 68.0,
        networkMBps: 12.4,
        batteryPercent: 88.0,
        isCharging: true,
      );

      expect(vitals.cpuPercent, 42.0);
      expect(vitals.ramPercent, 68.0);
      expect(vitals.cpuFormatted, '42%');
      expect(vitals.ramFormatted, '68%');
      expect(vitals.batteryFormatted, '88%');
      expect(vitals.networkFormatted, '12.4 MB/s');
    });

    test('ProjectItem and CardColorType resolve colors', () {
      final project = ProjectItem(
        id: 'p1',
        title: 'Planning',
        subtitle: 'November 18th, 2026',
        duration: '45 hours',
        colorType: CardColorType.peach,
      );

      expect(project.title, 'Planning');
      expect(project.duration, '45 hours');
      expect(project.colorType, CardColorType.peach);
      expect(project.backgroundColor, AppTheme.cardPeach);
    });

    test('AgentItem instantiates with dossier information', () {
      final agent = AgentItem(
        id: 'agent-1',
        name: 'Atlas',
        team: 'Core Orchestrator',
        avatarUrl: 'assets/avatars/atlas.png',
        clearance: 'GREEN',
        currentTask: 'Analyzing AST call-graph',
        status: 'Active',
        phase: 'Analysis',
        bio: 'Primary orchestrator for build pipelines.',
        assignedTools: const ['AST Parser', 'Docker Runner'],
        subtaskChecklist: const ['Parse syntax tree', 'Map dependencies'],
        elapsed: '14m',
      );

      expect(agent.name, 'Atlas');
      expect(agent.clearance, 'GREEN');
      expect(agent.assignedTools.length, 2);
    });

    test('GoalItem and GoalStatus work properly', () {
      const goal = GoalItem(
        id: 'g1',
        stepNumber: 1,
        category: 'SECURITY',
        title: 'Verify Biometric Integrity',
        status: GoalStatus.completed,
        description: 'Ensure hardware enclave passes key exchange.',
      );

      expect(goal.stepNumber, 1);
      expect(goal.category, 'SECURITY');
      expect(goal.status, GoalStatus.completed);
    });

    test('TerminalLog maps LogType to status colors', () {
      final logSuccess = TerminalLog(
        id: 'l1',
        timestamp: DateTime(2026, 10, 30, 10, 24, 0),
        message: 'Build finished successfully',
        type: LogType.success,
      );
      final logError = TerminalLog(
        id: 'l2',
        timestamp: DateTime(2026, 10, 30, 10, 24, 5),
        message: 'Process killed with SIGKILL',
        type: LogType.error,
      );
      final logWarning = TerminalLog(
        id: 'l3',
        timestamp: DateTime(2026, 10, 30, 10, 24, 10),
        message: 'Memory threshold reached 85%',
        type: LogType.warning,
      );
      final logCommand = TerminalLog(
        id: 'l4',
        timestamp: DateTime(2026, 10, 30, 10, 24, 15),
        message: 'flutter test',
        type: LogType.command,
      );

      expect(logSuccess.logColor, AppTheme.statusGreen);
      expect(logError.logColor, AppTheme.statusRed);
      expect(logWarning.logColor, AppTheme.statusAmber);
      expect(logCommand.logColor, AppTheme.accentOrange);
      expect(logSuccess.formattedTimestamp, '10:24:00');
    });

    test('ArtifactItem stores file details', () {
      final artifact = ArtifactItem(
        id: 'art-1',
        name: 'app-release.apk',
        size: '28.4 MB',
        type: ArtifactType.apk,
        timestamp: DateTime(2026, 10, 30, 10, 25, 0),
        path: '/build/outputs/apk/release/app-release.apk',
      );

      expect(artifact.name, 'app-release.apk');
      expect(artifact.type, ArtifactType.apk);
      expect(artifact.size, '28.4 MB');
    });
  });
}
