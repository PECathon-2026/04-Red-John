import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Card pastel color types matching Image 1 aesthetics.
enum CardColorType {
  peach,
  mint,
  lavender,
  warm,
  dark;

  Color get color {
    switch (this) {
      case CardColorType.peach:
        return AppTheme.cardPeach;
      case CardColorType.mint:
        return AppTheme.cardMint;
      case CardColorType.lavender:
        return AppTheme.cardLavender;
      case CardColorType.warm:
        return AppTheme.bgWarm;
      case CardColorType.dark:
        return AppTheme.darkPill;
    }
  }

  Color get textColor {
    switch (this) {
      case CardColorType.dark:
        return Colors.white;
      case CardColorType.peach:
      case CardColorType.mint:
      case CardColorType.lavender:
      case CardColorType.warm:
        return AppTheme.textDark;
    }
  }
}

/// Task execution phases for the running task card and pipeline.
enum TaskPhase {
  compiling('Compiling'),
  running('Running'),
  testing('Testing'),
  deploying('Deploying'),
  idle('Idle'),
  paused('Paused'),
  failed('Failed'),
  success('Success');

  final String label;
  const TaskPhase(this.label);

  Color get statusColor {
    switch (this) {
      case TaskPhase.compiling:
      case TaskPhase.deploying:
      case TaskPhase.testing:
        return AppTheme.accentOrange;
      case TaskPhase.running:
      case TaskPhase.success:
        return AppTheme.statusGreen;
      case TaskPhase.idle:
      case TaskPhase.paused:
        return AppTheme.statusAmber;
      case TaskPhase.failed:
        return AppTheme.statusRed;
    }
  }
}

/// Goal completion status for detail pipeline steps.
enum GoalStatus {
  pending('Pending'),
  inProgress('In Progress'),
  completed('Completed'),
  failed('Failed'),
  blocked('Blocked');

  final String label;
  const GoalStatus(this.label);

  Color get statusColor {
    switch (this) {
      case GoalStatus.completed:
        return AppTheme.statusGreen;
      case GoalStatus.inProgress:
        return AppTheme.accentOrange;
      case GoalStatus.failed:
      case GoalStatus.blocked:
        return AppTheme.statusRed;
      case GoalStatus.pending:
        return AppTheme.textSecondary;
    }
  }
}

/// Terminal log entry classifications.
enum LogType {
  stdout,
  stderr,
  info,
  success,
  warning,
  error,
  command;

  Color get logColor {
    switch (this) {
      case LogType.success:
        return AppTheme.statusGreen;
      case LogType.warning:
        return AppTheme.statusAmber;
      case LogType.error:
      case LogType.stderr:
        return AppTheme.statusRed;
      case LogType.command:
        return AppTheme.accentOrange;
      case LogType.info:
      case LogType.stdout:
        return Colors.white;
    }
  }
}

/// Artifact asset types generated during execution.
enum ArtifactType {
  apk('APK'),
  image('Screenshot'),
  document('Document'),
  log('Log File'),
  archive('Archive'),
  other('Asset');

  final String label;
  const ArtifactType(this.label);
}

/// Project / Workflow model representing high-level cards on Image 1.
class ProjectItem {
  final String id;
  final String title;
  final String subtitle;
  final String duration;
  final CardColorType colorType;
  final double progress;
  final List<String> memberAvatars;
  final List<String> tags;
  final bool isLive;

  const ProjectItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.colorType,
    this.progress = 0.0,
    this.memberAvatars = const [],
    this.tags = const [],
    this.isLive = true,
  });

  Color get backgroundColor => colorType.color;
  Color get textColor => colorType.textColor;

  ProjectItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? duration,
    CardColorType? colorType,
    double? progress,
    List<String>? memberAvatars,
    List<String>? tags,
    bool? isLive,
  }) {
    return ProjectItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      duration: duration ?? this.duration,
      colorType: colorType ?? this.colorType,
      progress: progress ?? this.progress,
      memberAvatars: memberAvatars ?? this.memberAvatars,
      tags: tags ?? this.tags,
      isLive: isLive ?? this.isLive,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'duration': duration,
    'colorType': colorType.name,
    'progress': progress,
    'memberAvatars': memberAvatars,
    'tags': tags,
    'isLive': isLive,
  };

  factory ProjectItem.fromJson(Map<String, dynamic> json) {
    return ProjectItem(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      colorType: CardColorType.values.firstWhere(
        (e) => e.name == json['colorType'],
        orElse: () => CardColorType.peach,
      ),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      memberAvatars:
          (json['memberAvatars'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const [],
      isLive: json['isLive'] as bool? ?? true,
    );
  }
}

/// Live hardware vitals streaming from the laptop / build server.
class HardwareVitals {
  final double cpuPercent;
  final double ramPercent;
  final double networkMBps;
  final double batteryPercent;
  final bool isCharging;

  const HardwareVitals({
    this.cpuPercent = 0.0,
    this.ramPercent = 0.0,
    this.networkMBps = 0.0,
    this.batteryPercent = 100.0,
    this.isCharging = true,
  });

  String get cpuFormatted => '${cpuPercent.round()}%';
  String get ramFormatted => '${ramPercent.round()}%';
  String get networkFormatted => '${networkMBps.toStringAsFixed(1)} MB/s';
  String get batteryFormatted => '${batteryPercent.round()}%';

  HardwareVitals copyWith({
    double? cpuPercent,
    double? ramPercent,
    double? networkMBps,
    double? batteryPercent,
    bool? isCharging,
  }) {
    return HardwareVitals(
      cpuPercent: cpuPercent ?? this.cpuPercent,
      ramPercent: ramPercent ?? this.ramPercent,
      networkMBps: networkMBps ?? this.networkMBps,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      isCharging: isCharging ?? this.isCharging,
    );
  }

  Map<String, dynamic> toJson() => {
    'cpuPercent': cpuPercent,
    'ramPercent': ramPercent,
    'networkMBps': networkMBps,
    'batteryPercent': batteryPercent,
    'isCharging': isCharging,
  };

  factory HardwareVitals.fromJson(Map<String, dynamic> json) {
    return HardwareVitals(
      cpuPercent: (json['cpuPercent'] as num?)?.toDouble() ?? 0.0,
      ramPercent: (json['ramPercent'] as num?)?.toDouble() ?? 0.0,
      networkMBps: (json['networkMBps'] as num?)?.toDouble() ?? 0.0,
      batteryPercent: (json['batteryPercent'] as num?)?.toDouble() ?? 100.0,
      isCharging: json['isCharging'] as bool? ?? true,
    );
  }
}

/// Currently active build/pipeline task running on the laptop.
class RunningTask {
  final String id;
  final String pipelineName;
  final String taskName;
  final DateTime startedAt;
  final TaskPhase phase;
  final double progress;
  final String securityBadge;
  final bool isE2eeEncrypted;
  final Duration? customElapsed;

  const RunningTask({
    required this.id,
    required this.pipelineName,
    required this.taskName,
    required this.startedAt,
    required this.phase,
    this.progress = 0.0,
    this.securityBadge = 'LAN E2EE',
    this.isE2eeEncrypted = true,
    this.customElapsed,
  });

  Duration get elapsedDuration =>
      customElapsed ?? DateTime.now().difference(startedAt);

  String get elapsedString {
    final duration = elapsedDuration.isNegative
        ? Duration.zero
        : elapsedDuration;
    if (duration.inHours > 0) {
      final hours = duration.inHours.toString().padLeft(2, '0');
      final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
      final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
      return 'T+$hours:$minutes:$seconds';
    } else {
      final minutes = duration.inMinutes.toString().padLeft(2, '0');
      final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
      return 'T+$minutes:$seconds';
    }
  }

  Color get statusColor => phase.statusColor;
  String get phaseLabel => phase.label;

  RunningTask copyWith({
    String? id,
    String? pipelineName,
    String? taskName,
    DateTime? startedAt,
    TaskPhase? phase,
    double? progress,
    String? securityBadge,
    bool? isE2eeEncrypted,
    Duration? customElapsed,
  }) {
    return RunningTask(
      id: id ?? this.id,
      pipelineName: pipelineName ?? this.pipelineName,
      taskName: taskName ?? this.taskName,
      startedAt: startedAt ?? this.startedAt,
      phase: phase ?? this.phase,
      progress: progress ?? this.progress,
      securityBadge: securityBadge ?? this.securityBadge,
      isE2eeEncrypted: isE2eeEncrypted ?? this.isE2eeEncrypted,
      customElapsed: customElapsed ?? this.customElapsed,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'pipelineName': pipelineName,
    'taskName': taskName,
    'startedAt': startedAt.toIso8601String(),
    'phase': phase.name,
    'progress': progress,
    'securityBadge': securityBadge,
    'isE2eeEncrypted': isE2eeEncrypted,
  };

  factory RunningTask.fromJson(Map<String, dynamic> json) {
    return RunningTask(
      id: json['id'] as String,
      pipelineName: json['pipelineName'] as String,
      taskName: json['taskName'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      phase: TaskPhase.values.firstWhere(
        (e) => e.name == json['phase'],
        orElse: () => TaskPhase.running,
      ),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      securityBadge: json['securityBadge'] as String? ?? 'LAN E2EE',
      isE2eeEncrypted: json['isE2eeEncrypted'] as bool? ?? true,
    );
  }
}

/// Agent entity representing active AI personnel in the roster / dossier.
class AgentItem {
  final String id;
  final String name;
  final String team;
  final String avatarUrl;
  final String clearance; // 'GREEN', 'AMBER', 'RED'
  final String currentTask;
  final String status;
  final String phase;
  final String bio;
  final List<String> assignedTools;
  final List<String> subtaskChecklist;
  final String elapsed;

  const AgentItem({
    required this.id,
    required this.name,
    required this.team,
    this.avatarUrl = '',
    this.clearance = 'GREEN',
    required this.currentTask,
    this.status = 'Active',
    this.phase = 'Running',
    this.bio = '',
    this.assignedTools = const [],
    this.subtaskChecklist = const [],
    this.elapsed = '',
  });

  Color get clearanceColor {
    switch (clearance.toUpperCase()) {
      case 'AMBER':
        return AppTheme.statusAmber;
      case 'RED':
        return AppTheme.statusRed;
      case 'GREEN':
      default:
        return AppTheme.statusGreen;
    }
  }

  AgentItem copyWith({
    String? id,
    String? name,
    String? team,
    String? avatarUrl,
    String? clearance,
    String? currentTask,
    String? status,
    String? phase,
    String? bio,
    List<String>? assignedTools,
    List<String>? subtaskChecklist,
    String? elapsed,
  }) {
    return AgentItem(
      id: id ?? this.id,
      name: name ?? this.name,
      team: team ?? this.team,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      clearance: clearance ?? this.clearance,
      currentTask: currentTask ?? this.currentTask,
      status: status ?? this.status,
      phase: phase ?? this.phase,
      bio: bio ?? this.bio,
      assignedTools: assignedTools ?? this.assignedTools,
      subtaskChecklist: subtaskChecklist ?? this.subtaskChecklist,
      elapsed: elapsed ?? this.elapsed,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'team': team,
    'avatarUrl': avatarUrl,
    'clearance': clearance,
    'currentTask': currentTask,
    'status': status,
    'phase': phase,
    'bio': bio,
    'assignedTools': assignedTools,
    'subtaskChecklist': subtaskChecklist,
    'elapsed': elapsed,
  };

  factory AgentItem.fromJson(Map<String, dynamic> json) {
    return AgentItem(
      id: json['id'] as String,
      name: json['name'] as String,
      team: json['team'] as String,
      avatarUrl: json['avatarUrl'] as String? ?? '',
      clearance: json['clearance'] as String? ?? 'GREEN',
      currentTask: json['currentTask'] as String? ?? '',
      status: json['status'] as String? ?? 'Active',
      phase: json['phase'] as String? ?? 'Running',
      bio: json['bio'] as String? ?? '',
      assignedTools:
          (json['assignedTools'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      subtaskChecklist:
          (json['subtaskChecklist'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      elapsed: json['elapsed'] as String? ?? '',
    );
  }
}

/// Goal / Step model representing ordered pipeline stages on Image 2.
class GoalItem {
  final String id;
  final int stepNumber;
  final String category;
  final String title;
  final GoalStatus status;
  final String description;

  const GoalItem({
    required this.id,
    required this.stepNumber,
    required this.category,
    required this.title,
    required this.status,
    this.description = '',
  });

  bool get isCompleted => status == GoalStatus.completed;
  bool get isInProgress => status == GoalStatus.inProgress;
  Color get statusColor => status.statusColor;

  GoalItem copyWith({
    String? id,
    int? stepNumber,
    String? category,
    String? title,
    GoalStatus? status,
    String? description,
  }) {
    return GoalItem(
      id: id ?? this.id,
      stepNumber: stepNumber ?? this.stepNumber,
      category: category ?? this.category,
      title: title ?? this.title,
      status: status ?? this.status,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'stepNumber': stepNumber,
    'category': category,
    'title': title,
    'status': status.name,
    'description': description,
  };

  factory GoalItem.fromJson(Map<String, dynamic> json) {
    return GoalItem(
      id: json['id'] as String,
      stepNumber: json['stepNumber'] as int,
      category: json['category'] as String,
      title: json['title'] as String,
      status: GoalStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => GoalStatus.pending,
      ),
      description: json['description'] as String? ?? '',
    );
  }
}

/// Live streaming terminal line model with timestamp and color semantics.
class TerminalLog {
  final String id;
  final DateTime timestamp;
  final String message;
  final LogType type;

  const TerminalLog({
    required this.id,
    required this.timestamp,
    required this.message,
    required this.type,
  });

  Color get logColor => type.logColor;

  String get formattedTimestamp {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  TerminalLog copyWith({
    String? id,
    DateTime? timestamp,
    String? message,
    LogType? type,
  }) {
    return TerminalLog(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      message: message ?? this.message,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'message': message,
    'type': type.name,
  };

  factory TerminalLog.fromJson(Map<String, dynamic> json) {
    return TerminalLog(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      message: json['message'] as String,
      type: LogType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => LogType.info,
      ),
    );
  }
}

/// Artifact generated during build / AI pipeline runs.
class ArtifactItem {
  final String id;
  final String name;
  final String size;
  final ArtifactType type;
  final DateTime timestamp;
  final String? path;
  final String? url;

  const ArtifactItem({
    required this.id,
    required this.name,
    required this.size,
    required this.type,
    required this.timestamp,
    this.path,
    this.url,
  });

  String get typeLabel => type.label;

  ArtifactItem copyWith({
    String? id,
    String? name,
    String? size,
    ArtifactType? type,
    DateTime? timestamp,
    String? path,
    String? url,
  }) {
    return ArtifactItem(
      id: id ?? this.id,
      name: name ?? this.name,
      size: size ?? this.size,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      path: path ?? this.path,
      url: url ?? this.url,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'size': size,
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    'path': path,
    'url': url,
  };

  factory ArtifactItem.fromJson(Map<String, dynamic> json) {
    return ArtifactItem(
      id: json['id'] as String,
      name: json['name'] as String,
      size: json['size'] as String,
      type: ArtifactType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ArtifactType.other,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      path: json['path'] as String?,
      url: json['url'] as String?,
    );
  }
}

/// Real AMBER human approval request emitted by backend governance.
class ApprovalRequest {
  final String approvalId;
  final String missionId;
  final String agent;
  final String tool;
  final String risk;
  final String reason;
  final String argsPreview;
  final int expiresAt;

  const ApprovalRequest({
    required this.approvalId,
    required this.missionId,
    required this.agent,
    required this.tool,
    this.risk = 'AMBER',
    required this.reason,
    this.argsPreview = '',
    required this.expiresAt,
  });

  factory ApprovalRequest.fromJson(Map<String, dynamic> json) {
    return ApprovalRequest(
      approvalId: json['approval_id'] as String? ?? json['id'] as String? ?? '',
      missionId: json['mission_id'] as String? ?? '',
      agent: json['agent'] as String? ?? 'Atlas',
      tool: json['tool'] as String? ?? 'apply_changes',
      risk: json['risk'] as String? ?? json['action_class'] as String? ?? 'AMBER',
      reason: json['reason'] as String? ?? 'Action requires operator approval',
      argsPreview: json['args_preview'] as String? ?? '',
      expiresAt: (json['expires_at'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'approval_id': approvalId,
    'mission_id': missionId,
    'agent': agent,
    'tool': tool,
    'risk': risk,
    'reason': reason,
    'args_preview': argsPreview,
    'expires_at': expiresAt,
  };
}

/// Issue or clarification question raised by agents needing human attention.
class OpenIssueItem {
  final String id;
  final String raisedBy;
  final String kind; // question, clarification, blocker, dispute
  final String text;
  final bool needsHuman;
  final String? taskId;
  final String status; // open, resolved
  final String? resolution;
  final String? resolvedBy;

  const OpenIssueItem({
    required this.id,
    required this.raisedBy,
    required this.kind,
    required this.text,
    this.needsHuman = false,
    this.taskId,
    this.status = 'open',
    this.resolution,
    this.resolvedBy,
  });

  bool get isResolved => status == 'resolved';

  factory OpenIssueItem.fromJson(Map<String, dynamic> json) {
    return OpenIssueItem(
      id: json['id'] as String? ?? '',
      raisedBy: json['raised_by'] as String? ?? 'Atlas',
      kind: json['kind'] as String? ?? 'clarification',
      text: json['text'] as String? ?? '',
      needsHuman: json['needs_human'] as bool? ?? false,
      taskId: json['task_id'] as String?,
      status: json['status'] as String? ?? 'open',
      resolution: json['resolution'] as String?,
      resolvedBy: json['resolved_by'] as String?,
    );
  }
}

/// Acceptance criterion verified independently with real evidence.
class AcceptanceCriterionItem {
  final String id;
  final String text;
  final String status; // pending, met, unmet, unverifiable
  final List<String> evidenceIds;
  final String? verifiedBy;
  final String? note;

  const AcceptanceCriterionItem({
    required this.id,
    required this.text,
    this.status = 'pending',
    this.evidenceIds = const [],
    this.verifiedBy,
    this.note,
  });

  bool get isMet => status.toLowerCase() == 'met';

  factory AcceptanceCriterionItem.fromJson(Map<String, dynamic> json) {
    return AcceptanceCriterionItem(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      evidenceIds: (json['evidence_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      verifiedBy: json['verified_by'] as String?,
      note: json['note'] as String?,
    );
  }
}

/// Verifiable evidence item from tool execution (test runs, scans, diffs).
class EvidenceRecord {
  final String evidenceId;
  final String kind; // test_run, diff, static_scan, secret_scan, command
  final String agent;
  final String? taskId;
  final bool? passed;
  final String summary;
  final Map<String, dynamic> data;
  final int at;

  const EvidenceRecord({
    required this.evidenceId,
    required this.kind,
    required this.agent,
    this.taskId,
    this.passed,
    this.summary = '',
    this.data = const {},
    this.at = 0,
  });

  factory EvidenceRecord.fromJson(Map<String, dynamic> json) {
    return EvidenceRecord(
      evidenceId: json['evidence_id'] as String? ?? json['id'] as String? ?? '',
      kind: json['kind'] as String? ?? 'test_run',
      agent: json['agent'] as String? ?? '',
      taskId: json['task_id'] as String?,
      passed: json['passed'] as bool?,
      summary: json['summary'] as String? ?? '',
      data: (json['data'] as Map<String, dynamic>?) ?? const {},
      at: (json['at'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Real health status of the backend subsystems.
class BackendHealth {
  final bool isHealthy;
  final bool storageOk;
  final bool eventBusOk;
  final bool llmConfigured;
  final int llmRoutes;

  const BackendHealth({
    this.isHealthy = false,
    this.storageOk = false,
    this.eventBusOk = false,
    this.llmConfigured = false,
    this.llmRoutes = 0,
  });

  factory BackendHealth.fromJson(Map<String, dynamic> json) {
    final checks = json['checks'] as Map<String, dynamic>? ?? {};
    final routes = json['llm_routes'];
    int routeCount = 0;
    if (routes is List) {
      routeCount = routes.length;
    } else if (routes is Map) {
      for (final v in routes.values) {
        if (v is List) {
          routeCount += v.length;
        } else {
          routeCount += 1;
        }
      }
    }
    return BackendHealth(
      isHealthy: json['status'] == 'ok',
      storageOk: checks['storage'] as bool? ?? false,
      eventBusOk: checks['event_bus'] as bool? ?? false,
      llmConfigured: checks['llm_configured'] as bool? ?? false,
      llmRoutes: routeCount,
    );
  }
}

/// Evaluation benchmark scenarios available directly under `missions/`.
class DemoScenario {
  final String id;
  final String title;
  final String prompt;
  final String relativeRepoPath;
  final String category;

  const DemoScenario({
    required this.id,
    required this.title,
    required this.prompt,
    required this.relativeRepoPath,
    required this.category,
  });

  static const List<DemoScenario> all = [
    DemoScenario(
      id: '01-feature-discounts',
      title: 'E-Commerce Discounts Feature',
      prompt:
          'Implement a 15% cart discount whenever 3 or more items are in the shopping cart. Ensure existing tests pass and add unit tests.',
      relativeRepoPath: 'missions/01-feature-discounts/repo',
      category: 'FEATURE',
    ),
    DemoScenario(
      id: '02-bug-pagination',
      title: 'Catalog Pagination Bug Fix',
      prompt:
          'Fix the off-by-one pagination bug in catalog/pagination.py so the last page does not return empty results.',
      relativeRepoPath: 'missions/02-bug-pagination/repo',
      category: 'BUG FIX',
    ),
    DemoScenario(
      id: '03-failing-test-durations',
      title: 'Time Duration Parser Repair',
      prompt:
          'Repair failing test in timeparse/durations.py where composite strings (e.g. 1h30m) fail to parse.',
      relativeRepoPath: 'missions/03-failing-test-durations/repo',
      category: 'TEST FIX',
    ),
    DemoScenario(
      id: '04-vulnerability-accounts',
      title: 'SQL Injection Remediation',
      prompt:
          'Audit and fix security vulnerability in accounts/store.py where raw query formatting allows parameter injection.',
      relativeRepoPath: 'missions/04-vulnerability-accounts/repo',
      category: 'SECURITY',
    ),
    DemoScenario(
      id: '05-ambiguous-export',
      title: 'Ambiguous Format Clarification',
      prompt:
          'Export monthly summary report. Note: ask the human whether output should be formatted as CSV or JSON.',
      relativeRepoPath: 'missions/05-ambiguous-export/repo',
      category: 'HUMAN LOOP',
    ),
    DemoScenario(
      id: '06-no-tests-temperature',
      title: 'Temperature Unit Test Authoring',
      prompt:
          'Author full test suite for units/convert.py verifying Celsius to Fahrenheit and Kelvin conversions.',
      relativeRepoPath: 'missions/06-no-tests-temperature/repo',
      category: 'TEST AUTHORING',
    ),
  ];
}

/// Extension methods for converting backend payloads to existing UI models.
extension BackendModelConverters on AgentItem {
  /// The canonical 16-agent DevPilot Guild defined in `backend_main/app/agents/guild.py`.
  static List<AgentItem> get guild16 => const [
        AgentItem(
          id: 'executive_atlas',
          name: 'Atlas',
          team: 'Executive',
          clearance: 'GREEN',
          currentTask: 'Mission Orchestrator',
          status: 'Active',
          phase: 'Orchestration',
          bio: 'Runs the floor. Decides what happens next from evidence on the board: continue, retry, replan, clarify, escalate, or stop.',
          assignedTools: ['mission_state', 'list_evidence'],
          subtaskChecklist: ['Review evidence', 'Coordinate task force', 'Enforce stop rules'],
          elapsed: 'Live',
        ),
        AgentItem(
          id: 'executive_maya',
          name: 'Maya',
          team: 'Executive',
          clearance: 'GREEN',
          currentTask: 'Guild HR — Hiring Engine',
          status: 'Active',
          phase: 'Hiring',
          bio: 'Staffs each mission with only the load-bearing specialists it needs, and drafts each hire mandate.',
          assignedTools: ['hire_agent', 'release_agent'],
          subtaskChecklist: ['Score required skills', 'Draft specialist mandate'],
          elapsed: 'Live',
        ),
        AgentItem(
          id: 'planning_kenji',
          name: 'Kenji',
          team: 'Planning',
          clearance: 'GREEN',
          currentTask: 'Requirements Analyst',
          status: 'Active',
          phase: 'Analysis',
          bio: 'Pins down requests into concrete acceptance criteria that a verifier can check with evidence.',
          assignedTools: ['read_file', 'list_dir', 'raise_issue'],
          subtaskChecklist: ['Extract criteria', 'Flag ambiguities'],
          elapsed: 'Live',
        ),
        AgentItem(
          id: 'planning_hana',
          name: 'Hana',
          team: 'Planning',
          clearance: 'GREEN',
          currentTask: 'Codebase Scout',
          status: 'Active',
          phase: 'Recon',
          bio: 'Maps the repository, conventions, and establishes baseline test results before any code changes.',
          assignedTools: ['read_file', 'git_log', 'run_tests'],
          subtaskChecklist: ['Map layout', 'Record test baseline'],
          elapsed: 'Live',
        ),
        AgentItem(
          id: 'planning_ryo',
          name: 'Ryo',
          team: 'Planning',
          clearance: 'GREEN',
          currentTask: 'Task Planner',
          status: 'Active',
          phase: 'Planning',
          bio: 'Cuts the mission into an acyclic task graph that can run in parallel where possible.',
          assignedTools: ['mission_state', 'list_evidence'],
          subtaskChecklist: ['Construct DAG', 'Link criteria to tasks'],
          elapsed: 'Live',
        ),
        AgentItem(
          id: 'forge_takeshi',
          name: 'Takeshi',
          team: 'Forge',
          clearance: 'AMBER',
          currentTask: 'Backend Engineer',
          status: 'Active',
          phase: 'Implementation',
          bio: 'Builds backend and Python changes in the house style, verifying with tests after every change.',
          assignedTools: ['write_file', 'edit_file', 'run_tests', 'run_command'],
          subtaskChecklist: ['Edit code', 'Verify tests pass'],
          elapsed: 'Live',
        ),
        AgentItem(
          id: 'forge_yuki',
          name: 'Yuki',
          team: 'Forge',
          clearance: 'AMBER',
          currentTask: 'Frontend Engineer',
          status: 'Active',
          phase: 'Implementation',
          bio: 'Ships frontend and UI changes cleanly following existing patterns and accessibility guidelines.',
          assignedTools: ['write_file', 'edit_file', 'run_tests'],
          subtaskChecklist: ['Update components', 'Test UI builds'],
          elapsed: 'Live',
        ),
        AgentItem(
          id: 'forge_daichi',
          name: 'Daichi',
          team: 'Forge',
          clearance: 'AMBER',
          currentTask: 'Deep Debugger',
          status: 'Active',
          phase: 'Debugging',
          bio: 'Called in when tests fail repeatedly. Finds and fixes root causes without weakening tests.',
          assignedTools: ['run_tests', 'edit_file', 'run_command'],
          subtaskChecklist: ['Form hypothesis', 'Target root cause'],
          elapsed: 'Live',
        ),
        AgentItem(
          id: 'forge_sora',
          name: 'Sora',
          team: 'Forge',
          clearance: 'AMBER',
          currentTask: 'Refactor & Style Keeper',
          status: 'Active',
          phase: 'Refactoring',
          bio: 'Cleans code, addresses review findings, and fixes linting while strictly preserving behavior.',
          assignedTools: ['edit_file', 'run_tests'],
          subtaskChecklist: ['Resolve lint issues', 'Preserve regression test pass'],
          elapsed: 'Live',
        ),
        AgentItem(
          id: 'sentinel_aiko',
          name: 'Aiko',
          team: 'Sentinel',
          clearance: 'GREEN',
          currentTask: 'Test Runner',
          status: 'Active',
          phase: 'Testing',
          bio: 'Runs the test suite against changes and reports exact test output without altering code.',
          assignedTools: ['run_tests', 'git_diff'],
          subtaskChecklist: ['Execute test matrix', 'Capture evidence id'],
          elapsed: 'Live',
        ),
        AgentItem(
          id: 'sentinel_riku',
          name: 'Riku',
          team: 'Sentinel',
          clearance: 'AMBER',
          currentTask: 'Test Author',
          status: 'Active',
          phase: 'Test Writing',
          bio: 'Writes edge-case and regression tests to pin down bugs and acceptance criteria.',
          assignedTools: ['write_file', 'edit_file', 'run_tests'],
          subtaskChecklist: ['Write failing test', 'Verify fix passes'],
          elapsed: 'Live',
        ),
        AgentItem(
          id: 'sentinel_mei',
          name: 'Mei',
          team: 'Sentinel',
          clearance: 'GREEN',
          currentTask: 'Independent Verifier',
          status: 'Active',
          phase: 'Verification',
          bio: 'Independently checks every acceptance criterion against real evidence before sign-off.',
          assignedTools: ['verify_criterion', 'run_tests', 'git_diff'],
          subtaskChecklist: ['Check test evidence', 'Sign off criteria'],
          elapsed: 'Live',
        ),
        AgentItem(
          id: 'shadow_haruto',
          name: 'Haruto',
          team: 'Shadow',
          clearance: 'GREEN',
          currentTask: 'Code Reviewer',
          status: 'Active',
          phase: 'Review',
          bio: 'Attacks the git diff for correctness, readability, edge cases, and maintainability.',
          assignedTools: ['git_diff', 'read_file', 'record_finding'],
          subtaskChecklist: ['Inspect diff', 'Flag regressions'],
          elapsed: 'Live',
        ),
        AgentItem(
          id: 'shadow_kaito',
          name: 'Kaito',
          team: 'Shadow',
          clearance: 'GREEN',
          currentTask: 'Security Inspector',
          status: 'Active',
          phase: 'Security Audit',
          bio: 'Runs static and secret scans to prevent injections, exposed keys, and insecure operations.',
          assignedTools: ['secret_scan', 'static_scan', 'git_diff'],
          subtaskChecklist: ['Scan secrets', 'Audit injection vectors'],
          elapsed: 'Live',
        ),
        AgentItem(
          id: 'shadow_emi',
          name: 'Emi',
          team: 'Shadow',
          clearance: 'GREEN',
          currentTask: 'Dispute Arbiter',
          status: 'Active',
          phase: 'Arbitration',
          bio: 'Settles disputes between developers and reviewers using evidence only, or escalates to human.',
          assignedTools: ['git_diff', 'run_tests', 'update_finding'],
          subtaskChecklist: ['Evaluate critique', 'Issue ruling'],
          elapsed: 'Live',
        ),
        AgentItem(
          id: 'support_scribe',
          name: 'Scribe',
          team: 'Support',
          clearance: 'GREEN',
          currentTask: 'Mission Scribe',
          status: 'Active',
          phase: 'Reporting',
          bio: 'Compiles the full Markdown evidence audit report, clearly separating proven facts from claims.',
          assignedTools: ['git_diff', 'list_evidence'],
          subtaskChecklist: ['Collect evidence proofs', 'Format audit report'],
          elapsed: 'Live',
        ),
      ];
}

