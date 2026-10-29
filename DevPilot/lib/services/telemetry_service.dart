import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/models.dart';

/// Telemetry and real-time simulation service for DevPilot mobile frontend.
///
/// Manages live hardware telemetry, task status, agent rosters, terminal logs,
/// and interactive security approval gates.
class TelemetryService extends ChangeNotifier {
  final bool autoStart;
  final Random _random = Random();

  Timer? _tickTimer;
  Timer? _simLogTimer;
  int _tickCount = 0;

  // Active state
  late RunningTask _currentTask;
  late HardwareVitals _vitals;
  late List<ProjectItem> _projects;
  late List<AgentItem> _agents;
  late List<GoalItem> _goals;
  final List<TerminalLog> _logs = [];
  late List<ArtifactItem> _artifacts;

  // Security gate & parameters
  bool _isPendingApproval = false;
  String? _pendingActionTitle;
  String? _pendingActionDetails;
  int _workerThreads = 8;
  bool _isVerbose = false;
  bool _isLANConnected = true;

  TelemetryService({this.autoStart = true}) {
    _initializeMockData();
    if (autoStart) {
      _startSimulation();
    }
  }

  // --- Getters ---
  RunningTask get currentTask => _currentTask;
  HardwareVitals get vitals => _vitals;
  List<ProjectItem> get projects => List.unmodifiable(_projects);
  List<AgentItem> get agents => List.unmodifiable(_agents);
  List<GoalItem> get goals => List.unmodifiable(_goals);
  List<TerminalLog> get logs => List.unmodifiable(_logs);
  List<ArtifactItem> get artifacts => List.unmodifiable(_artifacts);

  bool get isPendingApproval => _isPendingApproval;
  String? get pendingActionTitle => _pendingActionTitle;
  String? get pendingActionDetails => _pendingActionDetails;

  int get workerThreads => _workerThreads;
  bool get isVerbose => _isVerbose;
  bool get isLANConnected => _isLANConnected;

  // --- Initial Data Setup ---
  void _initializeMockData() {
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

    _agents = [
      const AgentItem(
        id: 'agent-1',
        name: 'Atlas',
        team: 'Executive',
        clearance: 'GREEN',
        currentTask: 'Analyzing AST call-graph & orchestrating pipeline',
        status: 'Active',
        phase: 'Analysis',
        bio: 'The organizational brain. Interprets mission briefs, builds research plans, monitors progress, and commissions the final architecture.',
        assignedTools: ['AST Parser', 'Docker Runner', 'Architecture Graph'],
        subtaskChecklist: [
          'Parse syntax tree',
          'Map dependencies',
          'Audit circular calls',
          'Verify type safety',
        ],
        elapsed: '14m 22s',
      ),
      const AgentItem(
        id: 'agent-2',
        name: 'Dev',
        team: 'Network',
        clearance: 'GREEN',
        currentTask: 'Procurement & landed cost matrix compilation',
        status: 'Active',
        phase: 'Compiling',
        bio: 'Computes total landed cost, freight, insurance, duties, handling, and switching cost for every supplier lane.',
        assignedTools: ['Cost Engine', 'Supplier Lane DB', 'FX Matrix'],
        subtaskChecklist: [
          'Import freight rates',
          'Calculate tariff surcharge',
          'Evaluate backup lanes',
        ],
        elapsed: '08m 45s',
      ),
      const AgentItem(
        id: 'agent-3',
        name: 'Nisha',
        team: 'Council',
        clearance: 'AMBER',
        currentTask: 'Evaluating operational feasibility & lead times',
        status: 'Active',
        phase: 'Review',
        bio: 'Operations strategist. Challenges unrealistic lead times, warehouse limitations, and operational complexity.',
        assignedTools: ['SimGrid', 'Warehouse Capacity Model'],
        subtaskChecklist: [
          'Audit warehouse throughput',
          'Flag 3PL bottlenecks',
          'Review pick & pack limits',
        ],
        elapsed: '21m 10s',
      ),
      const AgentItem(
        id: 'agent-4',
        name: 'Kabir',
        team: 'Network',
        clearance: 'GREEN',
        currentTask: 'Planning multimodal transport & route alternatives',
        status: 'Active',
        phase: 'Routing',
        bio: 'Plans transport modes, route selection, shipping times, warehouse placement, and last-mile considerations.',
        assignedTools: ['Route Optimizer', 'Port Congestion Feed'],
        subtaskChecklist: [
          'Check ocean freight choke points',
          'Optimize air/rail split',
          'Calculate ETA variance',
        ],
        elapsed: '05m 19s',
      ),
      const AgentItem(
        id: 'agent-5',
        name: 'Maya',
        team: 'Executive',
        clearance: 'GREEN',
        currentTask: 'AI task force hiring and capacity allocation',
        status: 'Idle',
        phase: 'Standby',
        bio: 'First decision-maker on missions. Reads incoming briefs and hires only the specialists the project actually requires.',
        assignedTools: ['Agent Registry', 'Skill Matcher'],
        subtaskChecklist: ['Evaluate task complexity', 'Form task force team'],
        elapsed: '42m 00s',
      ),
      const AgentItem(
        id: 'agent-6',
        name: 'Tara',
        team: 'Network',
        clearance: 'GREEN',
        currentTask: 'Safety stock & inventory buffer modeling',
        status: 'Active',
        phase: 'Modeling',
        bio: 'Sizes safety stock, reorder points, and inventory buffers per SKU/category and location against demand coverage.',
        assignedTools: ['Inventory Buffer Model', 'Demand Forecaster'],
        subtaskChecklist: ['Compute buffer sizes', 'Check stockout exposure'],
        elapsed: '11m 30s',
      ),
    ];

    _goals = [
      const GoalItem(
        id: 'g1',
        stepNumber: 1,
        category: 'RESEARCH & SPEC',
        title: 'Parse Blueprint AST & Requirements',
        status: GoalStatus.completed,
        description: 'Extract call graph and identify dependency subtrees across 11,684 symbols.',
      ),
      const GoalItem(
        id: 'g2',
        stepNumber: 2,
        category: 'INFRASTRUCTURE',
        title: 'Container Isolation & Sandboxing',
        status: GoalStatus.completed,
        description: 'Spin up deterministic Docker runtime environment with secure LAN proxy.',
      ),
      const GoalItem(
        id: 'g3',
        stepNumber: 3,
        category: 'COMPILATION',
        title: 'Compile Native Assets & Shaders',
        status: GoalStatus.inProgress,
        description: 'Ahead-of-time (AOT) compilation with 8 worker threads.',
      ),
      const GoalItem(
        id: 'g4',
        stepNumber: 4,
        category: 'VERIFICATION',
        title: 'Unit, Integration & E2E Validation',
        status: GoalStatus.pending,
        description: 'Execute automated regression test suite on isolated virtual devices.',
      ),
      const GoalItem(
        id: 'g5',
        stepNumber: 5,
        category: 'DEPLOYMENT',
        title: 'Sign & Distribute Release Artifacts',
        status: GoalStatus.pending,
        description: 'Generate signed APK and push encrypted telemetry metrics to devpilot.lan.',
      ),
    ];

    final now = DateTime.now();
    _logs.addAll([
      TerminalLog(
        id: 'log-1',
        timestamp: now.subtract(const Duration(minutes: 4, seconds: 15)),
        message:
            '[BOOT] DevPilot Agent Daemon v2.4 initialized on devpilot.lan',
        type: LogType.info,
      ),
      TerminalLog(
        id: 'log-2',
        timestamp: now.subtract(const Duration(minutes: 3, seconds: 50)),
        message: '[E2EE] Mutual TLS 1.3 handshake established (Cipher: TLS_AES_256_GCM_SHA384)',
        type: LogType.info,
      ),
      TerminalLog(
        id: 'log-3',
        timestamp: now.subtract(const Duration(minutes: 3, seconds: 12)),
        message: '[BUILD] Resolving package dependencies: 42 modules matched',
        type: LogType.stdout,
      ),
      TerminalLog(
        id: 'log-4',
        timestamp: now.subtract(const Duration(minutes: 2, seconds: 40)),
        message: '[AST] Parsing syntax tree: 11,684 symbols indexed in 380ms',
        type: LogType.stdout,
      ),
      TerminalLog(
        id: 'log-5',
        timestamp: now.subtract(const Duration(minutes: 2, seconds: 10)),
        message: '[WARN] Deprecated API call in telemetry_stream.dart: L88',
        type: LogType.warning,
      ),
      TerminalLog(
        id: 'log-6',
        timestamp: now.subtract(const Duration(minutes: 1, seconds: 35)),
        message: '[COMP] Compiling 248 Dart source units...',
        type: LogType.stdout,
      ),
      TerminalLog(
        id: 'log-7',
        timestamp: now.subtract(const Duration(seconds: 45)),
        message: '[TEST] Unit tests passed: 48/48 suites green (100%)',
        type: LogType.success,
      ),
      TerminalLog(
        id: 'log-8',
        timestamp: now.subtract(const Duration(seconds: 12)),
        message: '[AOT] Assembling native ARM64 release binaries...',
        type: LogType.stdout,
      ),
    ]);

    _artifacts = [
      ArtifactItem(
        id: 'art-1',
        name: 'devpilot-arm64-v8a-release.apk',
        size: '28.4 MB',
        type: ArtifactType.apk,
        timestamp: now.subtract(const Duration(minutes: 3)),
        path: '/build/outputs/apk/release/devpilot-release.apk',
      ),
      ArtifactItem(
        id: 'art-2',
        name: 'ast_graph_overview.png',
        size: '3.2 MB',
        type: ArtifactType.image,
        timestamp: now.subtract(const Duration(minutes: 6)),
        path: '/reports/ast_graph_overview.png',
      ),
      ArtifactItem(
        id: 'art-3',
        name: 'e2e_benchmark_report.pdf',
        size: '840 KB',
        type: ArtifactType.document,
        timestamp: now.subtract(const Duration(minutes: 10)),
        path: '/reports/e2e_benchmark.pdf',
      ),
      ArtifactItem(
        id: 'art-4',
        name: 'build_trace_20261030.log',
        size: '4.8 MB',
        type: ArtifactType.log,
        timestamp: now.subtract(const Duration(minutes: 15)),
        path: '/logs/build_trace.log',
      ),
    ];
  }

  // --- Real-Time Simulation Engine ---
  void _startSimulation() {
    // 1-second ticker for elapsed timer
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      simulateTick();
    });

    // 3-second simulation timer for realistic log bursts
    _simLogTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _emitSimulatedLog();
    });
  }

  /// Triggers a single simulation step (used by ticker and manual test invocations).
  void simulateTick() {
    _tickCount++;

    // 1. Natural hardware vitals fluctuation (CPU 28-65%, RAM 62-70%, network, battery 88-89%)
    final cpuBase = 42.0;
    final cpuJitter =
        sin(_tickCount * 0.15) * 14.0 + (_random.nextDouble() * 8.0 - 4.0);
    final nextCpu = (cpuBase + cpuJitter).clamp(28.0, 65.0);

    final ramBase = 65.0;
    final ramJitter =
        cos(_tickCount * 0.08) * 3.0 + (_random.nextDouble() * 2.0 - 1.0);
    final nextRam = (ramBase + ramJitter).clamp(62.0, 70.0);

    final netJitter =
        12.0 + sin(_tickCount * 0.3) * 8.0 + _random.nextDouble() * 6.0;
    final nextNet = max(1.2, netJitter);

    final nextBattery = _tickCount % 60 == 0
        ? max(85.0, _vitals.batteryPercent - 0.1)
        : _vitals.batteryPercent;

    _vitals = _vitals.copyWith(
      cpuPercent: nextCpu,
      ramPercent: nextRam,
      networkMBps: nextNet,
      batteryPercent: nextBattery,
    );

    // 2. Incremental progress on running task
    if (_currentTask.phase == TaskPhase.running &&
        _currentTask.progress < 0.96) {
      _currentTask = _currentTask.copyWith(
        progress: min(0.96, _currentTask.progress + 0.003),
      );
    }

    notifyListeners();
  }

  static const List<String> _simLogPool = [
    '[AOT] Optimizing inline assembly for core runtime...',
    '[CACHE] L2 cache hit ratio 94.2% across 12,400 symbols',
    '[AST] Cross-module dependency graph analyzed: 0 circular refs',
    '[NET] Telemetry sync acknowledged by devpilot.lan (RTT: 4ms)',
    '[AGENT: Atlas] Re-balancing subtask distribution across worker nodes',
    '[AGENT: Dev] Landed cost matrix verified with 0 discrepancy',
    '[BUILD] Emitting debug symbol dSYM bundle...',
    '[ENCRYPT] AES-256 session key rotated successfully',
  ];

  int _simLogIndex = 0;
  void _emitSimulatedLog() {
    if (!_isLANConnected) return;

    final message = _simLogPool[_simLogIndex % _simLogPool.length];
    _simLogIndex++;

    _logs.add(
      TerminalLog(
        id: 'log-sim-${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        message: message,
        type: LogType.stdout,
      ),
    );

    // Keep log buffer bounded to 200 items for memory efficiency
    if (_logs.length > 200) {
      _logs.removeRange(0, _logs.length - 200);
    }

    notifyListeners();
  }

  // --- Interactive Commands & Actions ---

  /// Simulates typing and executing a command in the terminal.
  void sendCliCommand(String command) {
    final trimmed = command.trim();
    if (trimmed.isEmpty) return;

    final now = DateTime.now();

    // 1. Log the typed command prompt
    _logs.add(
      TerminalLog(
        id: 'cmd-${now.millisecondsSinceEpoch}',
        timestamp: now,
        message: '> $trimmed',
        type: LogType.command,
      ),
    );

    // 2. Simulate outputs for known and ad-hoc commands
    final lower = trimmed.toLowerCase();
    if (lower == 'flutter doctor') {
      _logs.add(
        TerminalLog(
          id: 'out-${now.millisecondsSinceEpoch}-1',
          timestamp: now,
          message: '[✓] Flutter (Channel stable, 3.47.8, on macOS 15.1 darwin-arm64)',
          type: LogType.stdout,
        ),
      );
      _logs.add(
        TerminalLog(
          id: 'out-${now.millisecondsSinceEpoch}-2',
          timestamp: now,
          message: '[✓] Android toolchain - develop for Android devices (SDK 34.0.0)',
          type: LogType.stdout,
        ),
      );
      _logs.add(
        TerminalLog(
          id: 'out-${now.millisecondsSinceEpoch}-3',
          timestamp: now,
          message: '[✓] Xcode - develop for iOS and macOS (Xcode 16.1)',
          type: LogType.stdout,
        ),
      );
      _logs.add(
        TerminalLog(
          id: 'out-${now.millisecondsSinceEpoch}-4',
          timestamp: now,
          message: '[✓] Connected device (1 physical mobile target available)',
          type: LogType.stdout,
        ),
      );
      _logs.add(
        TerminalLog(
          id: 'out-${now.millisecondsSinceEpoch}-5',
          timestamp: now,
          message: '• Doctor summary: No issues found! All checks passed.',
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
          message: 'CONTAINER ID   IMAGE                 STATUS         PORTS\na8f10b2c3d4e   devpilot-telemetry    Up 4 hours     0.0.0.0:8000->8000/tcp\nb9d31e4f5a6b   mycel-ast-parser      Up 4 hours     0.0.0.0:9090->9090/tcp',
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
          message:
              '[EXEC] devpilot-operator: executed \'$trimmed\' successfully (exit code 0)',
          type: LogType.stdout,
        ),
      );
    }

    notifyListeners();
  }

  /// Triggers a macro action (e.g. from the MacroDeck on the Home Screen).
  void triggerAction(String actionName) {
    final now = DateTime.now();

    if (actionName.toLowerCase().contains('kill') ||
        actionName.toLowerCase().contains('destructive')) {
      _isPendingApproval = true;
      _pendingActionTitle = 'Kill All Processes';
      _pendingActionDetails = 'Terminates all active worker threads, agent sandboxes, and build pipelines immediately. Requires biometric verification.';

      _logs.add(
        TerminalLog(
          id: 'act-${now.millisecondsSinceEpoch}',
          timestamp: now,
          message:
              '[SECURITY GATE] AMBER alert: Approval requested for \'$actionName\'',
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
            message:
                '[RUNNER] Initiating parallel test matrix on $_workerThreads worker threads...',
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
      } else if (actionName == 'Restart Docker') {
        _logs.add(
          TerminalLog(
            id: 'act-detail-${now.millisecondsSinceEpoch}',
            timestamp: now,
            message: '[DOCKER] Sending SIGTERM to container cluster... restarted successfully',
            type: LogType.stdout,
          ),
        );
      }
    }

    notifyListeners();
  }

  /// Resolves an AMBER gate with approval.
  void approvePendingGate() {
    final now = DateTime.now();
    _isPendingApproval = false;
    _pendingActionTitle = null;
    _pendingActionDetails = null;

    _logs.add(
      TerminalLog(
        id: 'gate-${now.millisecondsSinceEpoch}-1',
        timestamp: now,
        message: '[SECURITY GATE] APPROVED: Action executed by operator with biometric auth.',
        type: LogType.warning,
      ),
    );

    _logs.add(
      TerminalLog(
        id: 'gate-${now.millisecondsSinceEpoch}-2',
        timestamp: now,
        message: '[SYSTEM] SIGKILL dispatched to worker processes (PID: 48921, 48922, 48925)',
        type: LogType.error,
      ),
    );

    _currentTask = _currentTask.copyWith(phase: TaskPhase.idle, progress: 0.0);

    notifyListeners();
  }

  /// Resolves an AMBER gate with denial.
  void denyPendingGate() {
    final now = DateTime.now();
    _isPendingApproval = false;
    _pendingActionTitle = null;
    _pendingActionDetails = null;

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

  /// Clears the terminal log list.
  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  /// Updates scraping or build worker threads count (1 to 16).
  void updateThreads(int count) {
    _workerThreads = count.clamp(1, 16);
    notifyListeners();
  }

  /// Toggles verbose terminal logging.
  void toggleVerbose(bool value) {
    _isVerbose = value;
    notifyListeners();
  }

  /// Toggles LAN connection status.
  void toggleLAN(bool value) {
    _isLANConnected = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _tickTimer = null;
    _simLogTimer?.cancel();
    _simLogTimer = null;
    super.dispose();
  }
}
