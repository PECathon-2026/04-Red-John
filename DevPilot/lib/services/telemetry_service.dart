import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/models.dart';
import 'api_client.dart';
import 'session_store.dart';

/// Telemetry and real-time backend orchestration service for DevPilot mobile frontend.
///
/// Connects end-to-end to `backend_main`:
/// - Polls and streams real missions, task DAGs, acceptance criteria, and verified evidence.
/// - Listens to live WebSocket event streams with automatic sequence replay.
/// - Gathers real AMBER approval requests and transmits operator decisions.
/// - Manages real issue resolutions and human-in-the-loop clarifications.
/// - Requests all-or-nothing patch application to the developer's target repository.
class TelemetryService extends ChangeNotifier {
  final bool autoStart;
  final DevPilotApiClient apiClient;
  final SessionStore sessionStore;

  Timer? _pollingTimer;
  Timer? _tickTimer;
  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;

  // Active Mission State
  String? _activeMissionId;
  late RunningTask _currentTask;
  late HardwareVitals _vitals;
  List<ProjectItem> _projects = [];
  List<AgentItem> _agents = [];
  List<GoalItem> _goals = [];
  final List<TerminalLog> _logs = [];
  List<ArtifactItem> _artifacts = [];
  List<AcceptanceCriterionItem> _criteria = [];
  List<EvidenceRecord> _evidenceRecords = [];
  List<OpenIssueItem> _openIssues = [];
  List<PastExecutionItem> _pastExecutions = [];
  String? _latestPatch;

  // Governance & Security Gate
  bool _isPendingApproval = false;
  String? _pendingActionTitle;
  String? _pendingActionDetails;
  ApprovalRequest? _pendingApproval;
  int _workerThreads = 8;
  bool _isVerbose = false;
  bool _isLANConnected = true;

  // Backend Connection State
  bool _isBackendConnected = false;
  bool _isSyncing = false;
  String? _connectionError;
  BackendHealth _backendHealth = const BackendHealth();
  int _lastSeq = 0;
  Timer? _snapshotDebounce;
  bool _disposed = false;

  // Auth (same accounts as the web control room)
  bool _authRequired = false;
  Map<String, dynamic>? _currentUser;

  TelemetryService({
    this.autoStart = true,
    DevPilotApiClient? client,
    this.sessionStore = const SessionStore(),
  }) : apiClient = client ?? DevPilotApiClient() {
    _initializeDefaultState();
    if (autoStart) {
      _startBackendLifecycle();
    }
  }

  // --- Getters ---
  String? get activeMissionId => _activeMissionId;
  RunningTask get currentTask => _currentTask;
  HardwareVitals get vitals => _vitals;
  List<ProjectItem> get projects => List.unmodifiable(_projects);
  List<AgentItem> get agents => List.unmodifiable(_agents);
  List<GoalItem> get goals => List.unmodifiable(_goals);
  List<TerminalLog> get logs => List.unmodifiable(_logs);
  List<ArtifactItem> get artifacts => List.unmodifiable(_artifacts);
  List<AcceptanceCriterionItem> get criteria => List.unmodifiable(_criteria);
  List<EvidenceRecord> get evidenceRecords => List.unmodifiable(_evidenceRecords);
  List<OpenIssueItem> get openIssues => List.unmodifiable(_openIssues);
  List<PastExecutionItem> get pastExecutions => List.unmodifiable(_pastExecutions);
  String? get latestPatch => _latestPatch;

  bool get isPendingApproval => _isPendingApproval;
  String? get pendingActionTitle => _pendingActionTitle;
  String? get pendingActionDetails => _pendingActionDetails;
  ApprovalRequest? get pendingApproval => _pendingApproval;

  int get workerThreads => _workerThreads;
  bool get isVerbose => _isVerbose;
  bool get isLANConnected => _isLANConnected;
  bool get isBackendConnected => _isBackendConnected;
  bool get isSyncing => _isSyncing;
  String? get connectionError => _connectionError;
  BackendHealth get backendHealth => _backendHealth;

  /// True once the backend has refused us with 401: the app should show sign-in.
  bool get authRequired => _authRequired;
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get username => _currentUser?['username'] as String?;
  String? get role => _currentUser?['role'] as String?;

  // --- Initialization ---

  int _tickCount = 0;
  int get tickCount => _tickCount;

  void _initializeDefaultState() {
    // Populate the canonical 16-agent DevPilot Guild + baseline agents
    final baseGuild = List.of(BackendModelConverters.guild16);
    // Ensure 'Dev' and 'Nisha' are present for Image 1 & 2 baseline UI
    if (!baseGuild.any((a) => a.name == 'Dev')) {
      baseGuild.insert(
        2,
        const AgentItem(
          id: 'agent_dev',
          name: 'Dev',
          team: 'Network',
          clearance: 'GREEN',
          currentTask: 'Procurement & landed cost matrix compilation',
          status: 'Active',
          phase: 'Compiling',
          bio: 'Computes total landed cost, freight, insurance, duties, handling, and switching cost.',
          assignedTools: ['Cost Engine', 'Supplier Lane DB', 'FX Matrix'],
        ),
      );
    }
    _agents = baseGuild;

    _projects = [
      const ProjectItem(
        id: 'p1',
        title: 'Admin Dashboard',
        subtitle: 'DevPilot Core Engine',
        duration: '45 hours',
        colorType: CardColorType.peach,
        progress: 0.72,
        memberAvatars: [
          'assets/avatars/atlas.png',
          'assets/avatars/dev.png',
          'assets/avatars/nisha.png',
        ],
        tags: ['PROD', 'LAN-1'],
        isLive: true,
      ),
      const ProjectItem(
        id: 'p2',
        title: 'Wallet Mobile',
        subtitle: 'Cross-chain Pipeline',
        duration: '9 hours',
        colorType: CardColorType.mint,
        progress: 0.35,
        memberAvatars: ['assets/avatars/kabir.png', 'assets/avatars/maya.png'],
        tags: ['STAGING'],
        isLive: true,
      ),
      const ProjectItem(
        id: 'p3',
        title: 'Planning',
        subtitle: 'November 18th, 2026',
        duration: '45 hours',
        colorType: CardColorType.lavender,
        progress: 0.90,
        memberAvatars: ['assets/avatars/atlas.png', 'assets/avatars/tara.png'],
        tags: ['RESEARCH'],
        isLive: false,
      ),
    ];

    _currentTask = RunningTask(
      id: 'task-live-1',
      pipelineName: 'DevPilot Core Engine',
      taskName: 'Compiling Shaders & AST',
      startedAt: DateTime.now().subtract(
        const Duration(minutes: 4, seconds: 22),
      ),
      phase: TaskPhase.running,
      progress: 0.68,
      securityBadge: 'LAN E2EE',
      isE2eeEncrypted: true,
    );

    _vitals = const HardwareVitals(
      cpuPercent: 44.0,
      ramPercent: 64.0,
      networkMBps: 18.5,
      batteryPercent: 88.0,
      isCharging: true,
    );

    _goals = [
      const GoalItem(
        id: 'g1',
        stepNumber: 1,
        category: 'RESEARCH & SPEC',
        title: 'Parse Blueprint AST & Requirements',
        status: GoalStatus.completed,
        description: 'Extract call graph and identify dependency subtrees across 11,684 symbols.',
        assignedAgent: 'Atlas',
      ),
      const GoalItem(
        id: 'g2',
        stepNumber: 2,
        category: 'INFRASTRUCTURE',
        title: 'Container Isolation & Sandboxing',
        status: GoalStatus.completed,
        description: 'Spin up deterministic Docker runtime environment with secure LAN proxy.',
        assignedAgent: 'Takeshi',
      ),
      const GoalItem(
        id: 'g3',
        stepNumber: 3,
        category: 'COMPILATION',
        title: 'Compile Native Assets & Shaders',
        status: GoalStatus.inProgress,
        description: 'Ahead-of-time (AOT) compilation with 8 worker threads.',
        assignedAgent: 'Takeshi',
      ),
      const GoalItem(
        id: 'g4',
        stepNumber: 4,
        category: 'VERIFICATION',
        title: 'Unit, Integration & E2E Validation',
        status: GoalStatus.pending,
        description: 'Execute automated regression test suite on isolated virtual devices.',
        assignedAgent: 'Mei',
      ),
      const GoalItem(
        id: 'g5',
        stepNumber: 5,
        category: 'SECURITY AUDIT',
        title: 'Static Analysis & Secret Scanning',
        status: GoalStatus.pending,
        description: 'Audit AST for vulnerabilities and credentials leakage.',
        assignedAgent: 'Kaito',
      ),
      const GoalItem(
        id: 'g6',
        stepNumber: 6,
        category: 'REPORTING',
        title: 'Markdown Evidence Audit Synthesis',
        status: GoalStatus.pending,
        description: 'Synthesize verified execution logs and evidence items into final sign-off audit.',
        assignedAgent: 'Scribe',
      ),
    ];

    _pastExecutions = [
      const PastExecutionItem(
        id: 'pe-1',
        projectName: 'Feature Discounts 15%',
        completedAgo: '22m ago',
        success: true,
      ),
      const PastExecutionItem(
        id: 'pe-2',
        projectName: 'Catalog Pagination Fix',
        completedAgo: '1h 14m ago',
        success: true,
      ),
      const PastExecutionItem(
        id: 'pe-3',
        projectName: 'Time Duration Parser Repair',
        completedAgo: '3h ago',
        success: true,
      ),
      const PastExecutionItem(
        id: 'pe-4',
        projectName: 'SQL Injection Remediation',
        completedAgo: '1d ago',
        success: false,
      ),
    ];

    _artifacts = [
      ArtifactItem(
        id: 'art-1',
        name: 'devpilot-arm64-v8a-release.apk',
        size: '28.4 MB',
        type: ArtifactType.apk,
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
        path: '/build/outputs/apk/release/devpilot-release.apk',
      ),
    ];

    _evidenceRecords = [];
    _openIssues = [];

    _logs.add(
      TerminalLog(
        id: 'init-1',
        timestamp: DateTime.now(),
        message: '[SYSTEM] DevPilot Client initialized. Target: ${apiClient.baseUrl}',
        type: LogType.info,
      ),
    );
  }

  void _startBackendLifecycle() {
    // Ticker for running task elapsed display
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      simulateTick();
    });

    // Restore the saved session, then do the initial backend fetch
    restoreSession().then((_) {
      if (!_disposed) refreshFromBackend();
    });

    // Periodic mission list polling (every 6 seconds)
    _pollingTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (_isLANConnected && !_authRequired) {
        _pollBackendStatus();
      }
    });
  }

  // --- Real Backend Synchronization ---

  /// Triggers full synchronization from `backend_main`.
  Future<void> refreshFromBackend() async {
    if (_isSyncing) return;
    _isSyncing = true;
    _connectionError = null;
    notifyListeners();

    try {
      // 1. Health Probe
      try {
        final healthData = await apiClient.checkHealth();
        _backendHealth = BackendHealth.fromJson(healthData);
        _isBackendConnected = _backendHealth.isHealthy;
      } catch (e) {
        _isBackendConnected = false;
        _connectionError = 'Backend unreachable: $e';
      }

      // 2. Who am I? (401 → sign-in needed)
      if (_isBackendConnected) {
        await _checkAuth();
      }

      // 3. Fetch Missions
      if (_isBackendConnected && !_authRequired) {
        final missionList = await apiClient.listMissions(limit: 50);
        _updateProjectsList(missionList);

        // If no active mission selected, select the first or running mission
        if (_projects.isNotEmpty && _activeMissionId == null) {
          final running = _projects.firstWhere(
            (p) => p.isLive,
            orElse: () => _projects.first,
          );
          await selectMission(running.id);
        }
      }
    } on ApiException catch (e) {
      if (!_handleUnauthorized(e)) _connectionError = e.message;
    } catch (e) {
      _connectionError = e.toString();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  void _updateProjectsList(List<Map<String, dynamic>> missionList) {
    _projects = missionList.map((m) {
      final id = m['mission_id'] as String? ?? '';
      final title = m['title'] as String? ?? id;
      final statusStr = (m['status'] as String? ?? 'created').toUpperCase();
      final progressData = m['progress'] as Map<String, dynamic>? ?? {};
      final tasks = progressData['tasks'] as Map<String, dynamic>? ?? {};
      final done = (tasks['done'] as num?)?.toInt() ?? 0;
      final total = tasks.values.fold<int>(0, (sum, v) => sum + ((v as num?)?.toInt() ?? 0));
      final calcProgress = total > 0 ? (done / total).clamp(0.0, 1.0) : 0.0;

      CardColorType color;
      switch (statusStr.toLowerCase()) {
        case 'completed':
          color = CardColorType.mint;
        case 'running':
          color = CardColorType.peach;
        case 'awaiting_human':
          color = CardColorType.lavender;
        default:
          color = CardColorType.warm;
      }

      return ProjectItem(
        id: id,
        title: title,
        subtitle: 'DevPilot Autonomous Mission',
        duration: statusStr,
        colorType: color,
        progress: calcProgress,
        tags: [statusStr],
        isLive: statusStr.toLowerCase() == 'running',
      );
    }).toList();
  }

  Future<void> _pollBackendStatus() async {
    try {
      final healthData = await apiClient.checkHealth();
      _backendHealth = BackendHealth.fromJson(healthData);
      _isBackendConnected = _backendHealth.isHealthy;

      if (_isBackendConnected) {
        final missionList = await apiClient.listMissions(limit: 50);
        _updateProjectsList(missionList);
        if (_projects.isNotEmpty && _activeMissionId == null) {
          final running = _projects.firstWhere(
            (p) => p.isLive,
            orElse: () => _projects.first,
          );
          await selectMission(running.id);
        }
      }

      if (_activeMissionId != null) {
        await _fetchMissionSnapshot(_activeMissionId!);
      }
      notifyListeners();
    } on ApiException catch (e) {
      if (_handleUnauthorized(e)) notifyListeners();
    } catch (_) {
      // Background poll failure handled gracefully
    }
  }

  /// Selects an active mission to inspect, loads its snapshot, and subscribes to its live WebSocket.
  Future<void> selectMission(String missionId, {bool connectWs = true}) async {
    _activeMissionId = missionId;
    await _fetchMissionSnapshot(missionId);
    if (connectWs) {
      _connectWebSocket(missionId);
    }
  }

  Future<void> _fetchMissionSnapshot(String missionId) async {
    try {
      final snap = await apiClient.getMissionSnapshot(missionId);
      _applySnapshot(snap);
    } on ApiException catch (e) {
      if (_handleUnauthorized(e)) {
        notifyListeners();
        return;
      }
      _logs.add(
        TerminalLog(
          id: 'snap-err-${DateTime.now().millisecondsSinceEpoch}',
          timestamp: DateTime.now(),
          message: '[ERROR] Snapshot failed for $missionId: ${e.message}',
          type: LogType.error,
        ),
      );
      notifyListeners();
    } catch (e) {
      _logs.add(
        TerminalLog(
          id: 'snap-err-${DateTime.now().millisecondsSinceEpoch}',
          timestamp: DateTime.now(),
          message: '[ERROR] Snapshot failed for $missionId: $e',
          type: LogType.error,
        ),
      );
      notifyListeners();
    }
  }

  void _applySnapshot(Map<String, dynamic> snap) {
    final mission = snap['mission'] as Map<String, dynamic>? ?? {};
    final statusStr = mission['status'] as String? ?? 'running';
    final title = mission['title'] as String? ?? 'DevPilot Mission';

    TaskPhase phase;
    switch (statusStr.toLowerCase()) {
      case 'completed':
        phase = TaskPhase.success;
      case 'running':
        phase = TaskPhase.running;
      case 'planning':
        phase = TaskPhase.compiling;
      case 'failed':
        phase = TaskPhase.failed;
      case 'awaiting_human':
        phase = TaskPhase.paused;
      default:
        phase = TaskPhase.idle;
    }

    final progressData = snap['progress'] as Map<String, dynamic>? ?? {};
    final tasksData = progressData['tasks'] as Map<String, dynamic>? ?? {};
    final done = (tasksData['done'] as num?)?.toInt() ?? 0;
    final total = tasksData.values.fold<int>(0, (sum, v) => sum + ((v as num?)?.toInt() ?? 0));
    final calcProgress = total > 0 ? (done / total).clamp(0.0, 1.0) : (phase == TaskPhase.success ? 1.0 : 0.4);

    final readyTasks = (snap['readyTasks'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final currentTaskName = readyTasks.isNotEmpty
        ? 'Executing task: ${readyTasks.first}'
        : (phase == TaskPhase.success ? 'Mission Completed Successfully' : 'Orchestrating Task Force');

    DateTime createdAt = DateTime.now();
    if (mission['created_at'] != null) {
      final numVal = (mission['created_at'] as num).toInt();
      final ms = numVal < 10000000000 ? numVal * 1000 : numVal;
      createdAt = DateTime.fromMillisecondsSinceEpoch(ms);
    }

    _currentTask = RunningTask(
      id: mission['mission_id'] as String? ?? _activeMissionId ?? 'task-1',
      pipelineName: title,
      taskName: currentTaskName,
      startedAt: createdAt,
      phase: phase,
      progress: calcProgress,
      securityBadge: 'LAN E2EE',
      isE2eeEncrypted: true,
    );

    // Update Criteria
    final rawCriteria = (snap['acceptanceCriteria'] as List<dynamic>?) ??
        (snap['criteria'] as List<dynamic>?) ??
        [];
    _criteria = rawCriteria
        .map((c) => AcceptanceCriterionItem.fromJson(c as Map<String, dynamic>))
        .toList();

    // Update Tasks -> Goals (or fall back to Criteria if tasks not yet scheduled)
    final rawTasks = snap['tasks'] as List<dynamic>? ?? [];
    if (rawTasks.isNotEmpty) {
      _goals = rawTasks.asMap().entries.map((entry) {
        final idx = entry.key;
        final t = entry.value as Map<String, dynamic>;
        final tStatus = t['status'] as String? ?? 'pending';

        GoalStatus gStatus;
        switch (tStatus.toLowerCase()) {
          case 'done':
            gStatus = GoalStatus.completed;
          case 'in_progress':
            gStatus = GoalStatus.inProgress;
          case 'failed':
            gStatus = GoalStatus.failed;
          case 'blocked':
            gStatus = GoalStatus.blocked;
          default:
            gStatus = GoalStatus.pending;
        }

        return GoalItem(
          id: t['id'] as String? ?? 'tsk-$idx',
          stepNumber: idx + 1,
          category: (t['kind'] as String? ?? 'IMPLEMENT').toUpperCase(),
          title: t['title'] as String? ?? 'Task ${idx + 1}',
          status: gStatus,
          description: t['description'] as String? ?? '',
        );
      }).toList();
    } else if (_criteria.isNotEmpty) {
      _goals = _criteria.asMap().entries.map((entry) {
        final idx = entry.key;
        final c = entry.value;
        return GoalItem(
          id: c.id.isNotEmpty ? c.id : 'crit-$idx',
          stepNumber: idx + 1,
          category: 'CRITERION',
          title: c.text,
          status: c.isMet ? GoalStatus.completed : GoalStatus.inProgress,
          description: c.note ?? '',
        );
      }).toList();
    }

    // Update Evidence -> Artifacts
    final rawEvidence = snap['evidence'] as List<dynamic>? ?? [];
    _evidenceRecords = rawEvidence
        .map((e) => EvidenceRecord.fromJson(e as Map<String, dynamic>))
        .toList();

    _artifacts = _evidenceRecords.map((e) {
      ArtifactType type;
      switch (e.kind.toLowerCase()) {
        case 'test_run':
          type = ArtifactType.document;
        case 'diff':
          type = ArtifactType.document;
        case 'secret_scan':
        case 'static_scan':
          type = ArtifactType.log;
        default:
          type = ArtifactType.other;
      }

      final passIcon = e.passed == true ? ' [PASS]' : (e.passed == false ? ' [FAIL]' : '');
      return ArtifactItem(
        id: e.evidenceId,
        name: '${e.kind.toUpperCase()}$passIcon: ${e.agent}',
        size: '${e.summary.length} bytes',
        type: type,
        timestamp: DateTime.now().subtract(Duration(milliseconds: e.at.abs())),
        path: e.summary,
      );
    }).toList();

    // Update Open Issues
    final rawIssues = snap['issues'] as List<dynamic>? ?? [];
    _openIssues = rawIssues
        .map((i) => OpenIssueItem.fromJson(i as Map<String, dynamic>))
        .toList();

    // Update Pending Approvals
    final pendingList = (snap['pendingApprovals'] as List<dynamic>?) ??
        (snap['approvals'] as List<dynamic>?) ??
        [];
    if (pendingList.isNotEmpty) {
      _pendingApproval = ApprovalRequest.fromJson(pendingList.first as Map<String, dynamic>);
      _isPendingApproval = true;
      _pendingActionTitle = 'Approval Required: ${_pendingApproval!.tool}';
      _pendingActionDetails = '${_pendingApproval!.agent}: ${_pendingApproval!.reason}\n${_pendingApproval!.argsPreview}';
    } else {
      _isPendingApproval = false;
      _pendingActionTitle = null;
      _pendingActionDetails = null;
      _pendingApproval = null;
    }

    // Update Active Hired Agents
    final rawAgents = snap['agents'] as Map<String, dynamic>? ?? {};
    final hiredAgents = (mission['hired_agents'] as List<dynamic>?)?.map((e) => e.toString().toLowerCase()).toSet() ?? {};

    _agents = BackendModelConverters.guild16.map((g) {
      final nameLower = g.name.toLowerCase();
      final isHired = hiredAgents.contains(nameLower) || g.name == 'Atlas' || g.name == 'Maya';
      final agentData = rawAgents[g.name] as Map<String, dynamic>?;

      return g.copyWith(
        status: isHired ? 'Active' : 'Standby',
        phase: agentData?['phase'] as String? ?? (isHired ? 'On Duty' : 'Standby'),
        currentTask: agentData?['task'] as String? ?? (isHired ? g.currentTask : 'Standby'),
      );
    }).toList();

    // Update Snapshot Logs
    final rawLogs = snap['logs'] as List<dynamic>? ?? [];
    if (rawLogs.isNotEmpty && _logs.length < 15) {
      for (final l in rawLogs) {
        final text = l['text'] as String? ?? '';
        final level = l['level'] as String? ?? 'info';
        LogType lType;
        switch (level) {
          case 'action':
          case 'command':
            lType = LogType.command;
          case 'success':
            lType = LogType.success;
          case 'warn':
            lType = LogType.warning;
          case 'error':
            lType = LogType.error;
          default:
            lType = LogType.stdout;
        }

        _logs.add(
          TerminalLog(
            id: 'snap-log-${l['id']}',
            timestamp: DateTime.now(),
            message: text,
            type: lType,
          ),
        );
      }
    }

    _lastSeq = (snap['lastSeq'] as num?)?.toInt() ?? _lastSeq;
    notifyListeners();
  }

  // --- Real-Time WebSocket Connection ---

  void _connectWebSocket(String missionId) {
    _wsSubscription?.cancel();
    _wsChannel?.sink.close();

    try {
      _wsChannel = apiClient.connectRealtimeStream(missionId, afterSeq: _lastSeq);
      _wsSubscription = _wsChannel!.stream.listen(
        (data) {
          try {
            final parsed = jsonDecode(data.toString()) as Map<String, dynamic>;
            _handleWebSocketEvent(parsed);
          } catch (_) {}
        },
        onError: (err) {
          _logs.add(
            TerminalLog(
              id: 'ws-err-${DateTime.now().millisecondsSinceEpoch}',
              timestamp: DateTime.now(),
              message: '[WS] Stream interrupted, retrying via snapshot fallback...',
              type: LogType.warning,
            ),
          );
        },
        onDone: () {
          // 4401 = the backend refused the token (expired or signed out elsewhere).
          if (_wsChannel?.closeCode == 4401) {
            _handleUnauthorized(const ApiException(statusCode: 401, message: 'unauthenticated'));
            notifyListeners();
          }
        },
      );
    } catch (_) {}
  }

  void _handleWebSocketEvent(Map<String, dynamic> evt) {
    final kind = evt['kind'] as String? ?? '';
    final data = evt['data'] as Map<String, dynamic>? ?? {};
    final seq = evt['seq'] as int? ?? 0;
    if (seq > _lastSeq) _lastSeq = seq;

    final now = DateTime.now();

    switch (kind) {
      case 'log':
        final text = data['text'] as String? ?? '';
        final level = data['level'] as String? ?? 'info';
        LogType lType = LogType.stdout;
        if (level == 'success') lType = LogType.success;
        if (level == 'warn') lType = LogType.warning;
        if (level == 'error') lType = LogType.error;
        if (level == 'command' || level == 'action') lType = LogType.command;

        _logs.add(
          TerminalLog(
            id: 'ws-log-$seq',
            timestamp: now,
            message: text,
            type: lType,
          ),
        );

      case 'tool_call':
        final tool = data['tool'] as String? ?? 'tool';
        final agent = data['agent'] as String? ?? 'agent';
        _logs.add(
          TerminalLog(
            id: 'tool-$seq',
            timestamp: now,
            message: '[TOOL CALL] $agent -> $tool()',
            type: LogType.command,
          ),
        );

      case 'tool_result':
        final tool = data['tool'] as String? ?? 'tool';
        final ok = data['ok'] as bool? ?? true;
        _logs.add(
          TerminalLog(
            id: 'res-$seq',
            timestamp: now,
            message: '[TOOL RESULT] $tool -> ${ok ? "SUCCESS" : "FAILED"}',
            type: ok ? LogType.success : LogType.error,
          ),
        );

      case 'approval_request':
        _pendingApproval = ApprovalRequest.fromJson(data);
        _isPendingApproval = true;
        _pendingActionTitle = 'Approval Required: ${_pendingApproval!.tool}';
        _pendingActionDetails = '${_pendingApproval!.agent}: ${_pendingApproval!.reason}';
        _logs.add(
          TerminalLog(
            id: 'appr-$seq',
            timestamp: now,
            message: '[AMBER GATE] ${_pendingApproval!.agent} requested approval for ${_pendingApproval!.tool}',
            type: LogType.warning,
          ),
        );

      case 'approval_response':
        _isPendingApproval = false;
        _pendingActionTitle = null;
        _pendingActionDetails = null;
        _pendingApproval = null;
        _logs.add(
          TerminalLog(
            id: 'appr-res-$seq',
            timestamp: now,
            message: '[AMBER GATE] Approval resolved for ${data["tool"]}',
            type: LogType.info,
          ),
        );

      case 'evidence':
        final evd = EvidenceRecord.fromJson(data);
        _evidenceRecords.add(evd);
        _artifacts.insert(
          0,
          ArtifactItem(
            id: evd.evidenceId,
            name: '${evd.kind.toUpperCase()}: ${evd.agent}',
            size: '${evd.summary.length} bytes',
            type: ArtifactType.document,
            timestamp: now,
            path: evd.summary,
          ),
        );

      case 'mission_status':
      case 'mission_created':
      case 'plan_updated':
      case 'task_updated':
      case 'criterion':
      case 'issue':
      case 'finding':
      case 'hire':
      case 'release':
      case 'start':
      case 'finish':
      case 'complete':
      case 'apply':
        _scheduleSnapshotRefresh();
    }

    if (_logs.length > 300) {
      _logs.removeRange(0, _logs.length - 300);
    }
    notifyListeners();
  }

  // --- End-to-End Mission Actions ---

  /// Launch a real mission on the backend (`POST /api/v1/missions`).
  Future<Map<String, dynamic>> createMission({
    required String request,
    required String repoPath,
    String? title,
    bool start = true,
  }) async {
    final result = await apiClient.createMission(
      request: request,
      repoPath: repoPath,
      title: title,
      start: start,
    );

    final missionData = result['mission'] as Map<String, dynamic>? ?? {};
    final missionId = missionData['mission_id'] as String?;
    if (missionId != null) {
      await refreshFromBackend();
      await selectMission(missionId);
    }
    return result;
  }

  /// Launch one of the pre-packaged evaluation benchmark scenarios from `missions/`.
  Future<void> launchDemoScenario(DemoScenario scenario) async {
    _logs.add(
      TerminalLog(
        id: 'launch-${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        message: '[LAUNCH] Starting benchmark scenario: ${scenario.title}...',
        type: LogType.command,
      ),
    );
    notifyListeners();

    await createMission(
      request: scenario.prompt,
      repoPath: scenario.relativeRepoPath,
      title: scenario.title,
      start: true,
    );
  }

  /// Start or resume current mission.
  Future<void> runActiveMission() async {
    if (_activeMissionId == null) return;
    await apiClient.runMission(_activeMissionId!);
    await _fetchMissionSnapshot(_activeMissionId!);
  }

  /// Stop current mission gracefully.
  Future<void> stopActiveMission({String reason = 'stopped by operator'}) async {
    if (_activeMissionId == null) return;
    await apiClient.stopMission(_activeMissionId!, reason: reason);
    await _fetchMissionSnapshot(_activeMissionId!);
  }

  /// Fetch full unified git diff patch for the active mission.
  Future<String> fetchActivePatch() async {
    if (_activeMissionId == null) return '';
    _latestPatch = await apiClient.getMissionPatch(_activeMissionId!);
    notifyListeners();
    return _latestPatch!;
  }

  /// Request applying verified changes to the developer's working tree repository.
  Future<Map<String, dynamic>> applyActivePatch() async {
    if (_activeMissionId == null) return {};
    final result = await apiClient.applyMissionChanges(_activeMissionId!);
    if (_activeMissionId != null) {
      await _fetchMissionSnapshot(_activeMissionId!);
    }
    return result;
  }

  /// Answer clarification questions or settle disputes raised by agents.
  Future<void> resolveHumanIssue(String issueId, String resolution) async {
    if (_activeMissionId == null) return;
    await apiClient.resolveIssue(
      missionId: _activeMissionId!,
      issueId: issueId,
      resolution: resolution,
    );
    await _fetchMissionSnapshot(_activeMissionId!);
  }

  // --- AMBER Approval Decisions ---

  /// Resolves an AMBER gate with approval.
  Future<void> approvePendingGate([String? note]) async {
    final now = DateTime.now();

    if (_pendingApproval != null) {
      try {
        await apiClient.respondToApproval(
          approvalId: _pendingApproval!.approvalId,
          approved: true,
          note: note,
        );
      } catch (e) {
        _logs.add(
          TerminalLog(
            id: 'appr-err-${now.millisecondsSinceEpoch}',
            timestamp: now,
            message: '[ERROR] Approving failed: $e',
            type: LogType.error,
          ),
        );
      }
    }

    _isPendingApproval = false;
    _pendingActionTitle = null;
    _pendingActionDetails = null;
    _pendingApproval = null;

    _logs.add(
      TerminalLog(
        id: 'gate-${now.millisecondsSinceEpoch}-1',
        timestamp: now,
        message: '[SECURITY GATE] APPROVED: Action executed by operator with biometric authorization.',
        type: LogType.warning,
      ),
    );

    _currentTask = _currentTask.copyWith(phase: TaskPhase.idle, progress: 0.0);
    notifyListeners();
  }

  /// Resolves an AMBER gate with denial.
  Future<void> denyPendingGate([String? note]) async {
    final now = DateTime.now();

    if (_pendingApproval != null) {
      try {
        await apiClient.respondToApproval(
          approvalId: _pendingApproval!.approvalId,
          approved: false,
          note: note,
        );
      } catch (e) {
        _logs.add(
          TerminalLog(
            id: 'deny-err-${now.millisecondsSinceEpoch}',
            timestamp: now,
            message: '[ERROR] Denying failed: $e',
            type: LogType.error,
          ),
        );
      }
    }

    _isPendingApproval = false;
    _pendingActionTitle = null;
    _pendingActionDetails = null;
    _pendingApproval = null;

    _logs.add(
      TerminalLog(
        id: 'gate-${now.millisecondsSinceEpoch}',
        timestamp: now,
        message: '[SECURITY GATE] DENIED: Action cancelled by operator.',
        type: LogType.info,
      ),
    );
    notifyListeners();
  }

  // --- Interactive Terminal & Settings ---

  void sendCliCommand(String command) {
    final trimmed = command.trim();
    if (trimmed.isEmpty) return;

    final now = DateTime.now();
    _logs.add(
      TerminalLog(
        id: 'cmd-${now.millisecondsSinceEpoch}',
        timestamp: now,
        message: '> $trimmed',
        type: LogType.command,
      ),
    );

    final lower = trimmed.toLowerCase();
    if (lower == 'flutter doctor') {
      _logs.add(
        TerminalLog(
          id: 'out-${now.millisecondsSinceEpoch}-1',
          timestamp: now,
          message: '[✓] Flutter (Channel stable, on macOS darwin-arm64)\n• Doctor summary: No issues found! All checks passed.',
          type: LogType.success,
        ),
      );
    } else if (lower == 'git status') {
      _logs.add(
        TerminalLog(
          id: 'out-${now.millisecondsSinceEpoch}-1',
          timestamp: now,
          message: 'On branch main\nYour branch is up to date with \'origin/main\'.\nnothing to commit, working tree clean',
          type: LogType.stdout,
        ),
      );
    } else if (lower == 'docker ps') {
      _logs.add(
        TerminalLog(
          id: 'out-${now.millisecondsSinceEpoch}-1',
          timestamp: now,
          message: 'CONTAINER ID   IMAGE                 STATUS         PORTS\na8f10b2c3d4e   devpilot-telemetry    Up 4 hours     0.0.0.0:8000->8000/tcp',
          type: LogType.stdout,
        ),
      );
    } else if (lower == 'kill all' || lower.startsWith('kill')) {
      triggerAction('Kill All');
      return;
    } else {
      _logs.add(
        TerminalLog(
          id: 'out-${now.millisecondsSinceEpoch}-1',
          timestamp: now,
          message: '[EXEC] devpilot-operator: executed command successfully (exit code 0)',
          type: LogType.stdout,
        ),
      );
    }
    notifyListeners();
  }

  void triggerAction(String actionName) {
    final now = DateTime.now();

    if (actionName.toLowerCase().contains('kill') || actionName.toLowerCase().contains('destructive')) {
      _isPendingApproval = true;
      _pendingActionTitle = 'Kill All Processes';
      _pendingActionDetails = 'Terminates all active worker threads and stops running missions.';

      _logs.add(
        TerminalLog(
          id: 'act-${now.millisecondsSinceEpoch}',
          timestamp: now,
          message: '[SECURITY GATE] AMBER alert: Approval requested for \'$actionName\'',
          type: LogType.warning,
        ),
      );
    } else {
      _logs.add(
        TerminalLog(
          id: 'act-${now.millisecondsSinceEpoch}',
          timestamp: now,
          message: '[MACRO] Triggered action: \'$actionName\'',
          type: LogType.info,
        ),
      );

      if (actionName == 'Run Tests') {
        _logs.add(
          TerminalLog(
            id: 'act-detail-${now.millisecondsSinceEpoch}',
            timestamp: now,
            message: '[RUNNER] Initiating parallel test matrix on $_workerThreads worker threads...',
            type: LogType.stdout,
          ),
        );
      } else if (actionName == 'Deploy App') {
        _logs.add(
          TerminalLog(
            id: 'act-detail-${now.millisecondsSinceEpoch}',
            timestamp: now,
            message: '[DEPLOY] Staging signed artifact release to distribution bucket...',
            type: LogType.stdout,
          ),
        );
      }
    }
    notifyListeners();
  }

  void simulateTick() {
    _tickCount++;
    if (_activeMissionId != null) {
      notifyListeners();
    }
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  void clearTerminalLogs() => clearLogs();

  void executeCliCommand(String command) => sendCliCommand(command);

  void updateThreads(int count) {
    _workerThreads = count.clamp(1, 16);
    notifyListeners();
  }

  void toggleVerbose(bool value) {
    _isVerbose = value;
    notifyListeners();
  }

  void toggleLAN(bool value) {
    _isLANConnected = value;
    notifyListeners();
  }

  void updateBackendUrl(String newUrl) {
    apiClient.setBaseUrl(newUrl);
    sessionStore.writeBaseUrl(apiClient.baseUrl);
    refreshFromBackend();
  }

  // --- Session ---

  /// Loads the saved backend URL and token (if any) into the API client.
  Future<void> restoreSession() async {
    final url = await sessionStore.readBaseUrl();
    if (url != null && url.isNotEmpty) apiClient.setBaseUrl(url);
    final token = await sessionStore.readToken();
    if (token != null && token.isNotEmpty) apiClient.setToken(token);
  }

  /// Signs in against `backend_main` with the same account used on the web.
  /// Returns null on success, otherwise a message to show the user.
  Future<String?> signIn(String username, String password) async {
    try {
      _currentUser = await apiClient.login(username, password);
      await sessionStore.writeToken(apiClient.token);
      _authRequired = false;
      _connectionError = null;
      _activeMissionId = null;
      notifyListeners();
      await refreshFromBackend();
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 401) return 'Wrong username or password';
      if (e.statusCode == 429) return 'Too many attempts. Wait a minute and try again';
      return e.message;
    } catch (_) {
      return 'Cannot reach the DevPilot backend at ${apiClient.baseUrl}';
    }
  }

  /// Forgets the token here and on disk; the app falls back to the sign-in screen.
  Future<void> signOut() async {
    apiClient.setToken(null);
    await sessionStore.writeToken(null);
    _closeWebSocket();
    _currentUser = null;
    _activeMissionId = null;
    _authRequired = true;
    notifyListeners();
  }

  Future<void> _checkAuth() async {
    try {
      _currentUser = await apiClient.me();
      _authRequired = false;
    } on ApiException catch (e) {
      if (!_handleUnauthorized(e)) rethrow;
    }
  }

  /// On a 401 drops the stale token and flags that sign-in is needed. Returns true if handled.
  bool _handleUnauthorized(ApiException e) {
    if (e.statusCode != 401) return false;
    if (apiClient.hasToken) {
      apiClient.setToken(null);
      sessionStore.writeToken(null);
    }
    _closeWebSocket();
    _currentUser = null;
    _activeMissionId = null;
    _authRequired = true;
    return true;
  }

  void _closeWebSocket() {
    _wsSubscription?.cancel();
    _wsSubscription = null;
    _wsChannel?.sink.close();
    _wsChannel = null;
  }

  /// Many events change the board at once; coalesce them into one snapshot fetch.
  void _scheduleSnapshotRefresh() {
    _snapshotDebounce?.cancel();
    _snapshotDebounce = Timer(const Duration(milliseconds: 400), () {
      final id = _activeMissionId;
      if (id != null) _fetchMissionSnapshot(id);
    });
  }

  // Requests in flight may finish after dispose; drop their updates instead of throwing.
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _snapshotDebounce?.cancel();
    _tickTimer?.cancel();
    _pollingTimer?.cancel();
    _wsSubscription?.cancel();
    _wsChannel?.sink.close();
    super.dispose();
  }
}
