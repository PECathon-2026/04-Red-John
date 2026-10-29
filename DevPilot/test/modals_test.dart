import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devpilot/theme/app_theme.dart';
import 'package:devpilot/models/models.dart';
import 'package:devpilot/services/telemetry_service.dart';
import 'package:devpilot/widgets/modals/approval_modal.dart';
import 'package:devpilot/widgets/modals/cli_sheet.dart';
import 'package:devpilot/widgets/modals/agent_dossier_modal.dart';
import 'package:devpilot/widgets/modals/parameter_modal.dart';

void main() {
  group('ApprovalModal Tests', () {
    testWidgets('ApprovalModal renders action title and approve/deny buttons', (
      tester,
    ) async {
      bool approved = false;
      bool denied = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ApprovalModal(
              actionTitle: 'Kill All Processes',
              details: 'This will terminate all running background tasks.',
              onApprove: () => approved = true,
              onDeny: () => denied = true,
            ),
          ),
        ),
      );

      expect(find.text('Kill All Processes'), findsOneWidget);
      expect(
        find.text('This will terminate all running background tasks.'),
        findsOneWidget,
      );
      expect(find.text('Approve Action'), findsOneWidget);
      expect(find.text('Deny'), findsOneWidget);
      expect(find.byIcon(Icons.fingerprint), findsOneWidget);

      await tester.tap(find.text('Approve Action'));
      await tester.pumpAndSettle();
      expect(approved, isTrue);

      await tester.tap(find.text('Deny'));
      await tester.pumpAndSettle();
      expect(denied, isTrue);
    });

    testWidgets('ApprovalModal renders risk level and biometric indicator', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ApprovalModal(
              actionTitle: 'Drop Database',
              details: 'Irreversible data loss.',
              riskLevel: 'CRITICAL',
              onApprove: () {},
              onDeny: () {},
            ),
          ),
        ),
      );

      expect(find.text('Drop Database'), findsOneWidget);
      expect(find.text('CRITICAL'), findsOneWidget);
    });

    testWidgets('ApprovalModal sliding gesture activates approval', (
      tester,
    ) async {
      bool approved = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ApprovalModal(
              actionTitle: 'Purge Redis Cache',
              details: 'Forces cache cold start.',
              onApprove: () => approved = true,
              onDeny: () {},
            ),
          ),
        ),
      );

      // Drag slider thumb horizontally
      await tester.drag(find.text('Approve Action'), const Offset(150, 0));
      await tester.pumpAndSettle();
      expect(approved, isTrue);
    });

    testWidgets('ApprovalModal.show displays dialog and handles response', (
      tester,
    ) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await ApprovalModal.show(
                    context,
                    actionTitle: 'Restart Cluster',
                    details: 'Rolling restart of all pods.',
                  );
                },
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Restart Cluster'), findsOneWidget);
      await tester.tap(find.text('Approve Action'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });

  group('CliSheet Tests', () {
    testWidgets(
      'CliSheet renders prompt, quick suggestions and executes commands',
      (tester) async {
        final service = TelemetryService(autoStart: false);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(body: CliSheet(service: service)),
          ),
        );

        // Monospace prompt
        expect(find.text('operator@devpilot:~\$ '), findsOneWidget);

        // Suggestions pills
        expect(find.text('flutter doctor'), findsOneWidget);
        expect(find.text('docker ps'), findsOneWidget);
        expect(find.text('git status'), findsOneWidget);
        expect(find.text('npm test'), findsOneWidget);

        // Tap suggestion pill and verify service received command
        final initialLogCount = service.logs.length;
        await tester.tap(find.text('flutter doctor'));
        await tester.pumpAndSettle();
        expect(service.logs.length, greaterThan(initialLogCount));
        expect(
          service.logs.any((l) => l.message.contains('> flutter doctor')),
          isTrue,
        );

        // Type custom command and send
        await tester.enterText(find.byType(TextField), 'uname -a');
        await tester.tap(find.byIcon(Icons.send_rounded));
        await tester.pumpAndSettle();

        expect(
          service.logs.any((l) => l.message.contains('> uname -a')),
          isTrue,
        );
      },
    );

    testWidgets('CliSheet.show opens bottom sheet modal', (tester) async {
      final service = TelemetryService(autoStart: false);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => CliSheet.show(context, service),
                child: const Text('Open CLI'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open CLI'));
      await tester.pumpAndSettle();

      expect(find.text('operator@devpilot:~\$ '), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.text('operator@devpilot:~\$ '), findsNothing);
    });
  });

  group('AgentDossierModal Tests', () {
    testWidgets(
      'AgentDossierModal renders agent details, badges, tools, and actions',
      (tester) async {
        const agent = AgentItem(
          id: 'agent-atlas',
          name: 'Atlas',
          team: 'Executive',
          clearance: 'AMBER',
          currentTask: 'Analyzing AST call-graph & orchestrating pipeline',
          status: 'Active',
          phase: 'Analysis',
          bio: 'The organizational brain. Interprets mission briefs and orchestrates compilers.',
          assignedTools: ['compiler', 'playwright', 'docker', 'rag_query'],
          subtaskChecklist: [
            'Parse syntax tree',
            'Map dependencies',
            'Audit circular calls',
          ],
          elapsed: '14m 22s',
        );

        bool closed = false;
        String? triggeredAction;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: AgentDossierModal(
                agent: agent,
                onClose: () => closed = true,
                onAction: (action) => triggeredAction = action,
              ),
            ),
          ),
        );

        expect(find.text('Atlas'), findsOneWidget);
        expect(find.text('Executive'), findsOneWidget);
        expect(find.text('AMBER'), findsOneWidget);
        expect(find.text('Analysis'), findsOneWidget);
        expect(
          find.text(
            'The organizational brain. Interprets mission briefs and orchestrates compilers.',
          ),
          findsOneWidget,
        );
        expect(
          find.text('Analyzing AST call-graph & orchestrating pipeline'),
          findsOneWidget,
        );

        // Tools chips
        expect(find.text('compiler'), findsOneWidget);
        expect(find.text('playwright'), findsOneWidget);
        expect(find.text('docker'), findsOneWidget);
        expect(find.text('rag_query'), findsOneWidget);

        // Subtasks
        expect(find.text('Parse syntax tree'), findsOneWidget);
        expect(find.text('14m 22s'), findsOneWidget);

        // Actions
        await tester.tap(find.text('Pause Agent'));
        await tester.pumpAndSettle();
        expect(triggeredAction, equals('pause'));

        await tester.tap(find.text('Reassign Agent'));
        await tester.pumpAndSettle();
        expect(triggeredAction, equals('reassign'));

        // Close button
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();
        expect(closed, isTrue);
      },
    );

    testWidgets('AgentDossierModal.show opens bottom sheet modal', (
      tester,
    ) async {
      const agent = AgentItem(
        id: 'agent-maya',
        name: 'Maya',
        team: 'Executive',
        clearance: 'GREEN',
        currentTask: 'Task force allocation',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AgentDossierModal.show(context, agent: agent),
                child: const Text('Open Dossier'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dossier'));
      await tester.pumpAndSettle();

      expect(find.text('Maya'), findsOneWidget);
      expect(find.text('GREEN'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Maya'), findsNothing);
    });
  });

  group('ParameterModal Tests', () {
    testWidgets(
      'ParameterModal renders sliders, switches, host field and modifies state',
      (tester) async {
        final service = TelemetryService(autoStart: false);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(body: ParameterModal(service: service)),
          ),
        );

        // Worker threads slider indicator
        expect(find.textContaining('8'), findsWidgets);
        expect(find.byType(Slider), findsOneWidget);

        // Verbose switch
        expect(find.text('--verbose'), findsOneWidget);
        expect(find.text('--no-cache'), findsOneWidget);

        // Host input
        expect(find.text('devpilot.lan'), findsOneWidget);

        // Toggle verbose
        expect(service.isVerbose, isFalse);
        final verboseSwitch = find.byKey(const Key('verbose_switch'));
        await tester.tap(verboseSwitch);
        await tester.pumpAndSettle();
        expect(service.isVerbose, isTrue);

        // Move slider
        await tester.drag(find.byType(Slider), const Offset(100, 0));
        await tester.pumpAndSettle();
        expect(service.workerThreads, isNot(8));

        // Toggle no-cache
        final nocacheSwitch = find.byKey(const Key('nocache_switch'));
        await tester.tap(nocacheSwitch);
        await tester.pumpAndSettle();
      },
    );

    testWidgets('ParameterModal.show opens and Save & Apply closes modal', (
      tester,
    ) async {
      final service = TelemetryService(autoStart: false);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ParameterModal.show(context, service),
                child: const Text('Open Settings'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Runtime Parameters'), findsOneWidget);
      await tester.tap(find.text('Save & Apply'));
      await tester.pumpAndSettle();
      expect(find.text('Runtime Parameters'), findsNothing);
    });
  });
}
