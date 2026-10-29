import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:devpilot/theme/app_theme.dart';
import 'package:devpilot/models/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;

  group('AppTheme Tokens & ThemeData', () {
    test('AppTheme defines Paper & Lime color tokens and aliases', () {
      // Paper & Lime Core Tokens
      expect(AppTheme.surface.toARGB32(), 0xFFF4F2EC);
      expect(AppTheme.surfaceAlt.toARGB32(), 0xFFEBE8E0);
      expect(AppTheme.surfaceRaised.toARGB32(), 0xFFFFFFFF);
      expect(AppTheme.surfaceInverse.toARGB32(), 0xFF0E0F0C);
      expect(AppTheme.primary.toARGB32(), 0xFFD7FE47);
      expect(AppTheme.primaryDeep.toARGB32(), 0xFFC8F02A);
      expect(AppTheme.onPrimary.toARGB32(), 0xFF0E0F0C);
      expect(AppTheme.accent.toARGB32(), 0xFFFF5A1F);
      expect(AppTheme.onSurface.toARGB32(), 0xFF0E0F0C);
      expect(AppTheme.onSurfaceVariant.toARGB32(), 0xFF8A8A82);
      expect(AppTheme.onInverse.toARGB32(), 0xFFF4F2EC);
      expect(AppTheme.border.toARGB32(), 0xFFE3E0D7);
      expect(AppTheme.borderStrong.toARGB32(), 0xFFDDDAD1);
      expect(AppTheme.neutralSoft.toARGB32(), 0xFFC8C5BA);

      // Backward compatibility aliases
      expect(AppTheme.bgMain, AppTheme.surface);
      expect(AppTheme.surfaceCard, AppTheme.surfaceRaised);
      expect(AppTheme.darkPill, AppTheme.surfaceInverse);
      expect(AppTheme.statusGreen, AppTheme.primaryDeep);
      expect(AppTheme.accentOrange, AppTheme.accent);
    });

    test('AppTheme defines Paper & Lime shapes and ThemeData', () {
      expect(AppTheme.cardRadius, BorderRadius.circular(24));
      expect(AppTheme.thumbRadius, BorderRadius.circular(18));
      expect(AppTheme.pillRadius, BorderRadius.circular(9999));

      final theme = AppTheme.themeData;
      expect(theme.scaffoldBackgroundColor, AppTheme.surface);
      expect(theme.cardTheme.elevation, 0);
      expect(theme.dividerTheme.color, Colors.transparent);
      expect(theme.useMaterial3, isTrue);
    });

    test('AppTheme defines Space Grotesk and Inter typography hierarchy', () {
      // Space Grotesk (Display & Numerals)
      expect(AppTheme.displayXl.fontSize, 84);
      expect(AppTheme.displayXl.fontWeight, FontWeight.w700);

      expect(AppTheme.displayMd.fontSize, 34);
      expect(AppTheme.displayMd.fontWeight, FontWeight.w700);

      expect(AppTheme.numeralMd.fontSize, 26);
      expect(AppTheme.numeralMd.fontWeight, FontWeight.w700);

      expect(AppTheme.numeralSm.fontSize, 22);
      expect(AppTheme.numeralSm.fontWeight, FontWeight.w700);

      expect(AppTheme.headlineMd.fontSize, 17);
      expect(AppTheme.headlineMd.fontWeight, FontWeight.w600);

      expect(AppTheme.headlineSm.fontSize, 15);
      expect(AppTheme.headlineSm.fontWeight, FontWeight.w600);

      expect(AppTheme.cardTitle.fontSize, 16);
      expect(AppTheme.cardTitle.fontWeight, FontWeight.w600);

      // Inter (Body, Labels, Uppercase kickers)
      expect(AppTheme.bodyMd.fontSize, 13);
      expect(AppTheme.bodySm.fontSize, 12);
      expect(AppTheme.labelMd.fontSize, 12);
      expect(AppTheme.labelSm.fontSize, 11);
      expect(AppTheme.labelUppercase.fontSize, 10);
      expect(AppTheme.labelUppercase.letterSpacing, 1.8);
      expect(AppTheme.caption.fontSize, 9);
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
