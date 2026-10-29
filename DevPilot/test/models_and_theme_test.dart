import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:devpilot/theme/app_theme.dart';
import 'package:devpilot/models/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;

  group('Monochrome Editorial Theme Tokens & ThemeData', () {
    test('T & AppTheme define Monochrome Editorial Mobile tokens', () {
      // 7-step grayscale palette
      expect(T.background.toARGB32(), 0xFF121212);
      expect(T.surfaceMuted.toARGB32(), 0xFF1E1E1E);
      expect(T.surfaceAlt.toARGB32(), 0xFF242424);
      expect(T.onSurface.toARGB32(), 0xFFFAFAFA);
      expect(T.onSurfaceVar.toARGB32(), 0xFF8E8E8E);
      expect(T.border.toARGB32(), 0xFF2E2E2E);
      expect(T.success.toARGB32(), 0xFF22C55E);
      expect(T.destructive.toARGB32(), 0xFF7F1D1D);

      // Backward compatibility aliases
      expect(AppTheme.surface, T.background);
      expect(AppTheme.border, T.border);
      expect(AppTheme.onSurface, T.onSurface);
      expect(AppTheme.statusGreen, T.success);
    });

    test('T & AppTheme enforce Zero Radius rule everywhere except badgeCircle', () {
      expect(T.zero, BorderRadius.zero);
      expect(AppTheme.cardRadius, BorderRadius.zero);
      expect(AppTheme.thumbRadius, BorderRadius.zero);
      expect(AppTheme.pillRadius, BorderRadius.zero);

      final theme = T.theme;
      expect(theme.scaffoldBackgroundColor, T.background);
      expect(theme.cardTheme.elevation, 0);
      expect(theme.dividerTheme.color, Colors.transparent);
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.dark);
    });

    test('T defines Montserrat typography hierarchy', () {
      expect(T.displayLg.fontSize, 48);
      expect(T.displayMd.fontSize, 36);
      expect(T.displaySm.fontSize, 30);
      expect(T.numeralXl.fontSize, 60);
      expect(T.headlineLg.fontSize, 24);
      expect(T.headlineMd.fontSize, 20);
      expect(T.headlineSm.fontSize, 18);

      expect(T.bodyMd.fontSize, 14);
      expect(T.bodySm.fontSize, 12);
      expect(T.labelUpMd.fontSize, 11);
      expect(T.labelUpSm.fontSize, 10);
      expect(T.labelUpXs.fontSize, 9);
      expect(T.eyebrowWide.fontSize, 10);
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

    test('PastExecutionItem instantiates properly', () {
      const past = PastExecutionItem(
        id: 'pe-1',
        projectName: 'Discounts Engine',
        completedAgo: '22m ago',
        success: true,
      );

      expect(past.projectName, 'Discounts Engine');
      expect(past.completedAgo, '22m ago');
      expect(past.success, isTrue);
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

    test('GoalItem and GoalStatus work properly with assignedAgent', () {
      const goal = GoalItem(
        id: 'g1',
        stepNumber: 1,
        category: 'SECURITY',
        title: 'Verify Biometric Integrity',
        status: GoalStatus.completed,
        description: 'Ensure hardware enclave passes key exchange.',
        assignedAgent: 'Atlas',
      );

      expect(goal.stepNumber, 1);
      expect(goal.category, 'SECURITY');
      expect(goal.status, GoalStatus.completed);
      expect(goal.assignedAgent, 'Atlas');
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

      expect(logSuccess.logColor, AppTheme.statusGreen);
      expect(logError.logColor, AppTheme.statusRed);
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
