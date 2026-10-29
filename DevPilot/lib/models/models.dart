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
      memberAvatars: (json['memberAvatars'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
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
    final duration =
        elapsedDuration.isNegative ? Duration.zero : elapsedDuration;
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
      assignedTools: (json['assignedTools'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      subtaskChecklist: (json['subtaskChecklist'] as List<dynamic>?)
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
