import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:devpilot/models/models.dart';
import 'package:devpilot/services/api_client.dart';
import 'package:devpilot/services/telemetry_service.dart';
import 'package:devpilot/widgets/modals/create_mission_modal.dart';
import 'package:devpilot/widgets/modals/evidence_modal.dart';
import 'package:devpilot/widgets/modals/issue_resolver_modal.dart';
import 'package:devpilot/widgets/modals/patch_review_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DevPilotApiClient Unit & Contract Tests', () {
    test('defaultBaseUrl handles Android vs iOS/Desktop endpoints', () {
      final client = DevPilotApiClient();
      expect(client.baseUrl, isNotEmpty);
      expect(client.baseUrl.startsWith('http://'), isTrue);

      client.setBaseUrl('http://192.168.1.100:8000/');
      expect(client.baseUrl, 'http://192.168.1.100:8000');
    });

    test('checkHealth returns parsed readiness payload', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/health/ready');
        return http.Response(
          jsonEncode({
            'status': 'ok',
            'checks': {
              'storage': true,
              'event_bus': true,
              'llm_configured': true,
            },
            'llm_routes': {'planner': 'claude-3-5-sonnet', 'coder': 'gpt-4o'}
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final api = DevPilotApiClient(
        baseUrl: 'http://127.0.0.1:8000',
        httpClient: mockClient,
      );
      final res = await api.checkHealth();
      expect(res['status'], 'ok');
      expect(res['checks']['storage'], true);
    });

    test('listMissions, createMission, getMissionSnapshot flow', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'GET' && request.url.path == '/api/v1/missions') {
          return http.Response(
            jsonEncode({
              'missions': [
                {
                  'mission_id': 'mission-alpha-123',
                  'request': 'Build login screen',
                  'status': 'running',
                  'created_at': 1730000000.0,
                  'hired_agents': ['Atlas', 'Takeshi', 'Mei'],
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        if (request.method == 'POST' && request.url.path == '/api/v1/missions') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['request'], 'Fix security CVE');
          return http.Response(
            jsonEncode({
              'mission_id': 'mission-cve-456',
              'status': 'created',
            }),
            201,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        if (request.method == 'GET' &&
            request.url.path == '/api/v1/missions/mission-alpha-123/snapshot') {
          return http.Response(
            jsonEncode({
              'mission': {
                'mission_id': 'mission-alpha-123',
                'request': 'Build login screen',
                'status': 'running',
                'created_at': 1730000000.0,
                'hired_agents': ['Atlas', 'Takeshi', 'Mei'],
              },
              'criteria': [
                {
                  'id': 'crit-1',
                  'text': 'Implement biometric passkey login',
                  'status': 'MET',
                  'evidence_ids': ['ev-101'],
                }
              ],
              'issues': [
                {
                  'id': 'iss-1',
                  'text': 'Should we allow fallback to PIN?',
                  'blocking': true,
                  'resolution': null,
                }
              ],
              'approvals': [
                {
                  'id': 'appr-99',
                  'action': 'write_file',
                  'risk_level': 'AMBER',
                  'status': 'PENDING',
                  'tool': 'forge_writer',
                  'justification': 'Modifying security auth provider',
                }
              ],
              'evidence': [
                {
                  'id': 'ev-101',
                  'kind': 'test_run',
                  'task_id': 'task-login',
                  'verifiable_hash': 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
                  'created_at': 1730000100.0,
                  'metadata': {'exit_code': 0, 'tests_passed': 4},
                }
              ],
              'agents': {
                'Takeshi': {'phase': 'Coding', 'task': 'Writing auth_provider.dart'}
              },
              'logs': [
                {'id': 1, 'text': 'Mission initialized', 'level': 'info'},
                {'id': 2, 'text': 'Atlas drafted criteria', 'level': 'success'},
              ],
              'lastSeq': 2,
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        if (request.method == 'POST' &&
            request.url.path == '/api/v1/approvals/appr-99/respond') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['approved'], true);
          return http.Response(
            jsonEncode({'status': 'ok'}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        if (request.method == 'POST' &&
            request.url.path == '/api/v1/missions/mission-alpha-123/issues/iss-1/resolve') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['resolution'], 'Yes, allow PIN fallback.');
          return http.Response(
            jsonEncode({'status': 'resolved'}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        if (request.method == 'GET' &&
            request.url.path == '/api/v1/missions/mission-alpha-123/patch') {
          return http.Response(
            '--- a/lib/auth.dart\n+++ b/lib/auth.dart\n@@ -1,3 +1,4 @@\n+import "passkey.dart";\n',
            200,
            headers: {'content-type': 'text/plain; charset=utf-8'},
          );
        }

        if (request.method == 'GET' && request.url.path == '/api/v1/agents') {
          return http.Response(
            jsonEncode({
              'agents': [
                {
                  'agent_id': 'ag-atlas',
                  'name': 'Atlas',
                  'team': 'executive',
                  'role': 'Guild Lead',
                  'skills': ['architecture', 'delegation'],
                  'tools': ['board_update'],
                  'badge': 'crown',
                  'char_idx': 0,
                  'always_on': true,
                  'clearance': 'ORANGE',
                  'default_mandate': 'Decompose goals into DAG',
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        return http.Response('Not Found', 404);
      });

      final api = DevPilotApiClient(
        baseUrl: 'http://127.0.0.1:8000',
        httpClient: mockClient,
      );

      final missions = await api.listMissions();
      expect(missions.length, 1);
      expect(missions.first['mission_id'], 'mission-alpha-123');

      final newMission = await api.createMission(
        request: 'Fix security CVE',
        repoPath: '/workspace',
      );
      expect(newMission['mission_id'], 'mission-cve-456');

      final snap = await api.getMissionSnapshot('mission-alpha-123');
      expect(snap['criteria'], isNotEmpty);
      expect(snap['issues'], isNotEmpty);
      expect(snap['approvals'], isNotEmpty);

      final apprRes = await api.respondToApproval(
        approvalId: 'appr-99',
        approved: true,
      );
      expect(apprRes['status'], 'ok');

      final patch = await api.getMissionPatch('mission-alpha-123');
      expect(patch, contains('--- a/lib/auth.dart'));

      final roster = await api.getGuildRoster();
      expect(roster.length, 1);
      expect(roster.first['name'], 'Atlas');
    });
  });

  group('TelemetryService Live Backend Integration Tests', () {
    test('service seamlessly parses backend snapshot and sets reactive state', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/missions/mission-live-1/snapshot') {
          return http.Response(
            jsonEncode({
              'mission': {
                'mission_id': 'mission-live-1',
                'request': 'Implement Paper & Lime Design Scheme',
                'status': 'running',
                'created_at': 1730000000.0,
                'hired_agents': ['Atlas', 'Takeshi', 'Mei'],
              },
              'criteria': [
                {
                  'id': 'crit-1',
                  'text': 'Pass 64 Flutter unit & widget tests',
                  'status': 'MET',
                  'evidence_ids': ['ev-99'],
                },
                {
                  'id': 'crit-2',
                  'text': 'Zero fake data in mobile client',
                  'status': 'IN_PROGRESS',
                  'evidence_ids': [],
                }
              ],
              'issues': [
                {
                  'id': 'iss-design',
                  'text': 'Should border radius be 16 or 20?',
                  'blocking': false,
                  'resolution': null,
                }
              ],
              'approvals': [
                {
                  'id': 'appr-gate-1',
                  'action': 'apply_patch',
                  'risk_level': 'AMBER',
                  'status': 'PENDING',
                  'tool': 'git_apply',
                  'justification': 'Modifying UI components in worktree',
                }
              ],
              'evidence': [
                {
                  'id': 'ev-99',
                  'kind': 'test_report',
                  'task_id': 'task-flutter-test',
                  'verifiable_hash': 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
                  'created_at': 1730000500.0,
                  'metadata': {'tests_passed': 64},
                }
              ],
              'agents': {
                'Takeshi': {'phase': 'Synthesizing', 'task': 'Refactoring DetailScreen'},
                'Mei': {'phase': 'Verifying', 'task': 'Auditing test coverage'},
              },
              'logs': [
                {'id': 1, 'text': '[BACKEND] Connected to live worker pool', 'level': 'info'},
                {'id': 2, 'text': '[BUILD] Generated UI widgets', 'level': 'success'},
              ],
              'lastSeq': 2,
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (request.url.path == '/api/v1/missions/mission-live-1/issues/iss-design/resolve') {
          return http.Response(
            jsonEncode({'status': 'resolved'}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (request.url.path == '/api/v1/approvals/appr-gate-1/respond') {
          return http.Response(
            jsonEncode({'status': 'approved'}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response(
          jsonEncode({'missions': []}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = DevPilotApiClient(
        baseUrl: 'http://127.0.0.1:8000',
        httpClient: mockClient,
      );

      final service = TelemetryService(
        autoStart: false,
        client: apiClient,
      );

      // Select mission and fetch snapshot
      await service.selectMission('mission-live-1', connectWs: false);

      // Verify mission goals are mapped from criteria
      expect(service.goals.length, 2);
      expect(service.goals[0].title, 'Pass 64 Flutter unit & widget tests');
      expect(service.goals[0].isCompleted, isTrue);
      expect(service.goals[1].title, 'Zero fake data in mobile client');
      expect(service.goals[1].isCompleted, isFalse);

      // Verify open issues and evidence
      expect(service.openIssues.length, 1);
      expect(service.openIssues.first.text, 'Should border radius be 16 or 20?');
      expect(service.evidenceRecords.length, 1);
      expect(service.evidenceRecords.first.evidenceId, 'ev-99');

      // Verify AMBER gate is raised
      expect(service.isPendingApproval, isTrue);
      expect(service.pendingActionTitle, contains('git_apply'));
      expect(service.pendingApproval?.risk, 'AMBER');

      // Approve gate
      await service.approvePendingGate('Operator approved patch');
      expect(service.isPendingApproval, isFalse);

      // Resolve open issue
      await service.resolveHumanIssue('iss-design', 'Use 16px corner radius');
      
      service.dispose();
    });
  });

  group('New Modals Widget Tests (Patch, Evidence, Issue, Create)', () {
    testWidgets('PatchReviewModal renders diff lines and handles interactions', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/patch')) {
          return http.Response(
            '--- a/lib/main.dart\n+++ b/lib/main.dart\n@@ -10,3 +10,4 @@\n-oldLine();\n+newLine();\n',
            200,
            headers: {'content-type': 'text/plain; charset=utf-8'},
          );
        }
        return http.Response(jsonEncode({}), 200, headers: {'content-type': 'application/json; charset=utf-8'});
      });

      final service = TelemetryService(
        autoStart: false,
        client: DevPilotApiClient(httpClient: mockClient),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => PatchReviewModal.show(ctx, service),
                child: const Text('Open Diff'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Diff'));
      await tester.pumpAndSettle();

      expect(find.text('Unified Git Patch Diff'), findsOneWidget);
      expect(find.text('Apply to Repo'), findsOneWidget);

      service.dispose();
    });

    testWidgets('EvidenceModal displays verifiable sha-256 evidence details', (tester) async {
      const evidence = EvidenceRecord(
        evidenceId: 'ev-test-1',
        kind: 'test_run',
        agent: 'Mei',
        taskId: 'task-build',
        passed: true,
        summary: 'Unit test suite passed with 0 errors',
        data: {'exit_code': 0, 'tests_passed': 42},
        at: 1730000000,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => EvidenceModal.show(ctx, evidence),
                child: const Text('Show Evidence'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Evidence'));
      await tester.pumpAndSettle();

      expect(find.text('Verifiable Evidence Artifact'), findsOneWidget);
      expect(find.text('VERDICT: PASS'), findsOneWidget);
      expect(find.text('TEST_RUN'), findsOneWidget);
      expect(find.textContaining('ev-test-1'), findsWidgets);
    });

    testWidgets('IssueResolverModal renders question and submits resolution', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'status': 'resolved'}), 200, headers: {'content-type': 'application/json; charset=utf-8'});
      });

      final service = TelemetryService(
        autoStart: false,
        client: DevPilotApiClient(httpClient: mockClient),
      );

      const issue = OpenIssueItem(
        id: 'iss-test',
        raisedBy: 'Atlas',
        kind: 'clarification',
        text: 'Should we enable dark mode by default?',
        needsHuman: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => IssueResolverModal.show(
                  ctx,
                  service: service,
                  issue: issue,
                ),
                child: const Text('Resolve Issue'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Resolve Issue'));
      await tester.pumpAndSettle();

      expect(find.text('Human-in-the-Loop Clarification'), findsOneWidget);
      expect(find.text('Should we enable dark mode by default?'), findsOneWidget);
      expect(find.text('Submit Resolution & Resume'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Yes, follow system preference');
      await tester.tap(find.text('Submit Resolution & Resume'));
      await tester.pumpAndSettle();

      service.dispose();
    });

    testWidgets('CreateMissionModal renders evaluation benchmark scenarios', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'mission_id': 'm-new', 'status': 'created'}), 201, headers: {'content-type': 'application/json; charset=utf-8'});
      });

      final service = TelemetryService(
        autoStart: false,
        client: DevPilotApiClient(httpClient: mockClient),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => CreateMissionModal.show(ctx, service),
                child: const Text('Create Mission'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Create Mission'));
      await tester.pumpAndSettle();

      expect(find.text('Launch AI Mission'), findsOneWidget);
      expect(find.text('EVALUATION BENCHMARK SCENARIOS'), findsOneWidget);
      expect(find.text('E-Commerce Discounts Feature'), findsOneWidget);
      expect(find.text('Catalog Pagination Bug Fix'), findsOneWidget);

      service.dispose();
    });
  });
}
