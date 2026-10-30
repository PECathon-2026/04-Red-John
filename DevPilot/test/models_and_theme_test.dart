import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:devpilot/theme/app_theme.dart';
import 'package:devpilot/models/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;

  group('Modern Light Theme Tokens & ThemeData', () {
    test('T & AppTheme define Modern Light Theme tokens', () {
      expect(T.background.toARGB32(), 0xFFF8FAFC);
      expect(T.surface.toARGB32(), 0xFFFFFFFF);
      expect(T.surfaceMuted.toARGB32(), 0xFFF1F5F9);
      expect(T.surfaceAlt.toARGB32(), 0xFFE2E8F0);
      expect(T.onSurface.toARGB32(), 0xFF0F172A);
      expect(T.onSurfaceVar.toARGB32(), 0xFF475569);
      expect(T.border.toARGB32(), 0xFFE2E8F0);
      expect(T.success.toARGB32(), 0xFF16A34A);
      expect(T.destructive.toARGB32(), 0xFFDC2626);

      // Backward compatibility aliases
      expect(AppTheme.surface, T.surface);
      expect(AppTheme.border, T.border);
      expect(AppTheme.onSurface, T.onSurface);
      expect(AppTheme.statusGreen, T.success);
    });

    test('T & AppTheme enforce rounded corner radii to break rigid contrast', () {
      expect(T.rSm, const BorderRadius.all(Radius.circular(8)));
      expect(T.rMd, const BorderRadius.all(Radius.circular(12)));
      expect(T.rLg, const BorderRadius.all(Radius.circular(16)));
      expect(T.rFull, const BorderRadius.all(Radius.circular(9999)));
      expect(T.badgeCircle, const BorderRadius.all(Radius.circular(9999)));

      final theme = T.theme;
      expect(theme.scaffoldBackgroundColor, T.background);
      expect(theme.cardTheme.elevation, 0);
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
    });

    test('T defines Montserrat typography hierarchy', () {
      expect(T.displayLg.fontSize, 40);
      expect(T.displayMd.fontSize, 32);
      expect(T.displaySm.fontSize, 26);
      expect(T.numeralXl.fontSize, 52);
      expect(T.headlineLg.fontSize, 22);
      expect(T.headlineMd.fontSize, 18);
      expect(T.headlineSm.fontSize, 15);

      expect(T.bodyMd.fontSize, 14);
      expect(T.bodySm.fontSize, 12);
      expect(T.labelUpMd.fontSize, 11);
      expect(T.labelUpSm.fontSize, 10);
      expect(T.labelUpXs.fontSize, 9);
      expect(T.eyebrowWide.fontSize, 10);
    });
  });

  group('Domain Models Unit Tests', () {
    test('GoalItem stores assignedAgent, stepNumber and category', () {
      final goal = GoalItem(
        id: 'goal-1',
        title: 'Implement OAuth Token Refresh',
        description: 'Rotate refresh tokens on auth expiration',
        status: GoalStatus.inProgress,
        stepNumber: 3,
        category: 'security',
        assignedAgent: 'Takeshi',
      );

      expect(goal.title, 'Implement OAuth Token Refresh');
      expect(goal.description, 'Rotate refresh tokens on auth expiration');
      expect(goal.status, GoalStatus.inProgress);
      expect(goal.stepNumber, 3);
      expect(goal.category, 'security');
      expect(goal.assignedAgent, 'Takeshi');
      expect(goal.isCompleted, isFalse);
    });

    test('PastExecutionItem stores project execution history', () {
      final past = PastExecutionItem(
        id: 'past-1',
        projectName: 'Feature Discounts 15%',
        completedAgo: '12M AGO',
        success: true,
      );

      expect(past.projectName, 'Feature Discounts 15%');
      expect(past.completedAgo, '12M AGO');
      expect(past.success, isTrue);
    });

    test('DiffFile and DiffLine models structure delta trees', () {
      const line = DiffLine(
        text: '+        self.default_discount_rate = 0.15',
        type: 'add',
        newLineNumber: 15,
      );

      expect(line.text, '+        self.default_discount_rate = 0.15');
      expect(line.type, 'add');
      expect(line.newLineNumber, 15);
      expect(line.oldLineNumber, isNull);

      const file = DiffFile(
        path: 'backend/services/discount_engine.py',
        status: 'modified',
        additions: 18,
        deletions: 4,
        lines: [line],
      );

      expect(file.path, 'backend/services/discount_engine.py');
      expect(file.status, 'modified');
      expect(file.additions, 18);
      expect(file.deletions, 4);
      expect(file.lines.length, 1);
    });

    test('AgentItem phase and clearance mapping', () {
      const agent = AgentItem(
        id: 'agent-1',
        name: 'Takeshi',
        team: 'Backend Core',
        phase: 'Implementation',
        currentTask: 'Writing token rotation handlers',
        clearance: 'L4_AUDIT',
      );

      expect(agent.name, 'Takeshi');
      expect(agent.team, 'Backend Core');
      expect(agent.phase, 'Implementation');
      expect(agent.currentTask, 'Writing token rotation handlers');
      expect(agent.clearance, 'L4_AUDIT');
      expect(agent.clearanceColor, isNotNull);
    });

    test('HardwareVitals percent calculations', () {
      final vitals = HardwareVitals(
        cpuPercent: 34.5,
        ramPercent: 62.0,
        networkMBps: 2.4,
        batteryPercent: 88.0,
      );

      expect(vitals.cpuPercent, 34.5);
      expect(vitals.ramPercent, 62.0);
      expect(vitals.networkMBps, 2.4);
      expect(vitals.batteryPercent, 88.0);
    });
  });
}
