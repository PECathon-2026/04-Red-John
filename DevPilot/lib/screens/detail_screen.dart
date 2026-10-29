import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../services/telemetry_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dicebear_avatar.dart';
import '../widgets/primitives.dart';
import 'artifact_list_screen.dart';
import 'diff_screen.dart';
import 'full_terminal_screen.dart';

/// Redesigned Monochrome Editorial Project Detail Screen.
///
/// Features:
/// - Top bar: Back button + Title + Overflow menu (View Diff, Share, Stop). No timer in header.
/// - Live Execution Pill: Shows under project only when an agent is running; ONLY place with elapsed timer.
/// - Goals Preview: 4 goals (1 old completed, 1 current, 2 future). Tapping opens all goals with assigned agent & cute avatar.
/// - Team Section: 3-column hairline card grid with cute avatars. Tapping opens member dossier bottom sheet.
/// - Terminal Console: Formatted log lines with LIVE status. Tapping opens full-screen terminal.
/// - Artifacts Row: Max 4 type-colored cards. "View all →" opens 2-column ArtifactListScreen.
class DetailScreen extends StatefulWidget {
  final TelemetryService service;
  final ProjectItem project;
  final VoidCallback onBack;
  final VoidCallback? onOpenCli;
  final VoidCallback? onOpenSettings;
  final void Function(AgentItem agent)? onOpenAgent;

  const DetailScreen({
    super.key,
    required this.service,
    required this.project,
    required this.onBack,
    this.onOpenCli,
    this.onOpenSettings,
    this.onOpenAgent,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleShareLink() {
    HapticFeedback.lightImpact();
    const hostLink = 'https://devpilot.lan:8000/session/planning';
    Clipboard.setData(const ClipboardData(text: hostLink));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Host link copied to clipboard: devpilot.lan'),
        backgroundColor: Color(0xFF1E1E1E),
      ),
    );
  }

  void _showOverflowMenu() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: T.background,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: T.border)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.difference_outlined, color: T.onSurface),
              title: Text('View Diff / File Review', style: T.headlineSm),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DiffScreen(service: widget.service),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.link_rounded, color: T.onSurface),
              title: Text('Share Session Link', style: T.headlineSm),
              onTap: () {
                Navigator.pop(ctx);
                _handleShareLink();
              },
            ),
            ListTile(
              leading: const Icon(Icons.stop_circle_outlined, color: Colors.red),
              title: Text('Stop / Kill Mission',
                  style: T.headlineSm.copyWith(color: Colors.red.shade400)),
              onTap: () {
                Navigator.pop(ctx);
                widget.service.stopActiveMission();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mission execution halted by operator.'),
                    backgroundColor: Color(0xFF1E1E1E),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.background,
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: widget.service,
          builder: (context, _) {
            final goals = widget.service.goals;
            final agents = widget.service.agents;
            final logs = widget.service.logs;
            final artifacts = widget.service.artifacts;

            return Column(
              children: [
                // Top App Bar (Back button, Title, Overflow menu, NO timer here)
                _buildTopBar(),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(0, 16, 0, 96),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Conditional Live Execution Pill (Timer is ONLY here!)
                        _buildExecutionPill(),

                        const SizedBox(height: 24),

                        // Goals Preview (4 goals: 1 old, 1 current, 2 future)
                        _buildGoalsPreview(goals),

                        const SizedBox(height: 32),

                        // Team 3-Column Grid with Cute Avatars
                        _buildTeamGrid(agents),

                        const SizedBox(height: 32),

                        // Live Terminal Console (Tap to expand into full terminal screen)
                        _buildTerminalSection(logs),

                        const SizedBox(height: 32),

                        // Artifacts Row (Max 4, type-colored, expand to 2-col list)
                        _buildArtifactSection(artifacts),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- Top App Bar ---
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(T.lg, 12, T.lg, 12),
      decoration: const BoxDecoration(
        color: T.background,
        border: Border(bottom: BorderSide(color: T.border)),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onBack();
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: T.background,
                border: Border.all(color: T.border),
              ),
              child: const Icon(Icons.arrow_back, color: T.onSurface, size: 20),
            ),
          ),
          const SizedBox(width: T.md),
          // Project Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.project.title,
                  style: T.headlineSm,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.project.subtitle.isNotEmpty
                      ? widget.project.subtitle
                      : 'AUTONOMOUS MISSION',
                  style: T.labelUpXs.copyWith(color: T.onSurfaceVar),
                ),
              ],
            ),
          ),
          // Difference Button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DiffScreen(service: widget.service),
                ),
              );
            },
            child: Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: T.background,
                border: Border.all(color: T.border),
              ),
              child: const Icon(Icons.difference_outlined,
                  color: T.onSurface, size: 20),
            ),
          ),
          // Overflow Menu [···]
          GestureDetector(
            onTap: _showOverflowMenu,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: T.background,
                border: Border.all(color: T.border),
              ),
              child: const Icon(Icons.more_horiz, color: T.onSurface, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // --- Conditional Current Execution Pill (Timer ONLY here) ---
  Widget _buildExecutionPill() {
    final running = widget.service.agents.where((a) {
      final p = a.phase.toLowerCase();
      return p == 'running' || p == 'working' || p == 'implementation';
    }).toList();

    if (running.isEmpty) return const SizedBox.shrink();

    final agent = running.first;
    final elapsed =
        agent.elapsed.isNotEmpty ? agent.elapsed : widget.service.currentTask.elapsedString;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: T.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LIVE EXECUTION', style: T.eyebrowWide),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(T.md),
            decoration: BoxDecoration(
              color: T.surfaceMuted.withValues(alpha: 0.3),
              border: Border.all(color: T.success.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                // Running dot
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: T.sm),
                  decoration: const BoxDecoration(
                    color: T.success,
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  'RUNNING',
                  style: T.labelUpXs.copyWith(color: T.success),
                ),
                const SizedBox(width: T.md),
                Expanded(
                  child: Text(
                    agent.name,
                    style: T.headlineSm,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Elapsed Timer — Appears ONLY HERE
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1C),
                    border: Border.all(color: T.border),
                  ),
                  child: Text(
                    elapsed.isNotEmpty ? elapsed : 'T+00:00',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: T.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Goals Section (4 Goals Preview: 1 old, 1 current, 2 future) ---
  Widget _buildGoalsPreview(List<GoalItem> goals) {
    final completed =
        goals.where((g) => g.status == GoalStatus.completed).toList();
    final inProgress =
        goals.where((g) => g.status == GoalStatus.inProgress).toList();
    final pending =
        goals.where((g) => g.status == GoalStatus.pending).toList();

    final preview = <GoalItem>[
      if (completed.isNotEmpty) completed.last, // 1 old completed
      if (inProgress.isNotEmpty) inProgress.first, // 1 current
      ...pending.take(2), // up to 2 future
    ].take(4).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: T.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            'GOALS',
            trailing: GestureDetector(
              onTap: () => _showAllGoals(goals),
              child: Text(
                'View all (${goals.length}) →',
                style: T.labelUpXs.copyWith(color: T.onSurface),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(border: Border.all(color: T.border)),
            child: Column(
              children: [
                for (int i = 0; i < preview.length; i++) ...[
                  if (i > 0) Container(height: 1, color: T.border),
                  _GoalRow(
                    goal: preview[i],
                    index: i,
                    onTap: () => _showAllGoals(goals),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAllGoals(List<GoalItem> goals) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: T.background,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(T.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('PIPELINE GOALS', style: T.headlineLg),
                  BadgePill('${goals.length} TOTAL'),
                ],
              ),
            ),
            Container(height: 1, color: T.border),
            Expanded(
              child: ListView.separated(
                controller: controller,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(T.lg),
                itemCount: goals.length,
                separatorBuilder: (_, _) =>
                    Container(height: 1, color: T.border, margin: const EdgeInsets.symmetric(vertical: 16)),
                itemBuilder: (_, i) {
                  final goal = goals[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('STEP ${goal.stepNumber} • ${goal.category.toUpperCase()}',
                              style: T.labelUpXs),
                          BadgePill(
                            goal.status.label.toUpperCase(),
                            bg: goal.status == GoalStatus.completed
                                ? T.surfaceMuted
                                : goal.status == GoalStatus.inProgress
                                    ? T.success.withValues(alpha: 0.2)
                                    : T.surfaceAlt,
                            textColor: goal.status == GoalStatus.inProgress
                                ? T.success
                                : T.onSurface,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        goal.title,
                        style: T.headlineMd.copyWith(
                          decoration: goal.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: goal.isCompleted
                              ? T.onSurfaceMuted
                              : T.onSurface,
                        ),
                      ),
                      if (goal.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          goal.description,
                          style: T.bodyMd.copyWith(color: T.onSurfaceVar),
                        ),
                      ],
                      if (goal.assignedAgent != null) ...[
                        const SizedBox(height: 14),
                        Text('ASSIGNED AGENT', style: T.labelUpXs),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            CuteAvatar(name: goal.assignedAgent!, size: 36),
                            const SizedBox(width: 10),
                            Text(goal.assignedAgent!, style: T.headlineSm),
                          ],
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Team Section: 3-Column Hairline Grid ---
  Widget _buildTeamGrid(List<AgentItem> agents) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: T.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            'TEAM MEMBERS',
            trailing: BadgePill('${agents.length} AGENTS'),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(border: Border.all(color: T.border)),
            child: Wrap(
              children: [
                for (int i = 0; i < agents.length; i++)
                  _buildTeamCell(agents[i], i, agents.length),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCell(AgentItem agent, int idx, int total) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = (constraints.maxWidth - 2) / 3;
        final hasRightBorder = idx % 3 != 2;
        final rows = (total / 3).ceil();
        final currentRow = idx ~/ 3;
        final hasBottomBorder = currentRow < rows - 1;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          key: Key('team_cell_${agent.name}'),
          onTap: () {
            if (widget.onOpenAgent != null) {
              widget.onOpenAgent!(agent);
            } else {
              _showAgentDossier(agent);
            }
          },
          child: Container(
            width: w,
            decoration: BoxDecoration(
              color: T.background,
              border: Border(
                right: hasRightBorder
                    ? const BorderSide(color: T.border)
                    : BorderSide.none,
                bottom: hasBottomBorder
                    ? const BorderSide(color: T.border)
                    : BorderSide.none,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Cute offline vector avatar
                CuteAvatar(name: agent.name, size: 48),
                const SizedBox(height: 8),
                Text(
                  agent.name,
                  style: T.headlineSm,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  agent.team.toUpperCase(),
                  style: T.labelUpXs.copyWith(fontSize: 8.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                _phaseChip(agent.phase),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _phaseChip(String phase) {
    final p = phase.toLowerCase();
    final isRunning = p == 'running' || p == 'working' || p == 'implementation';
    final isDone = p == 'done' || p == 'completed';
    final color = isRunning
        ? T.success
        : isDone
            ? T.onSurfaceVar
            : T.onSurfaceMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: T.zero,
      ),
      child: Text(
        phase.toUpperCase(),
        style: T.labelUpXs.copyWith(color: color, fontSize: 8),
      ),
    );
  }

  void _showAgentDossier(AgentItem agent) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: T.background,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(T.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CuteAvatar(name: agent.name, size: 64),
                  const SizedBox(width: T.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(agent.name, style: T.displaySm),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(agent.team.toUpperCase(), style: T.labelUpSm),
                            const SizedBox(width: T.sm),
                            BadgePill(
                              agent.clearance,
                              bg: agent.clearanceColor.withValues(alpha: 0.2),
                              textColor: agent.clearanceColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: T.lg),
              Container(height: 1, color: T.border),
              const SizedBox(height: T.lg),
              // Phase
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(border: Border.all(color: T.border)),
                child: Center(
                  child: Text(
                    'PHASE: ${agent.phase.toUpperCase()}',
                    style: T.labelUpMd.copyWith(color: T.onSurface),
                  ),
                ),
              ),
              const SizedBox(height: T.lg),
              // Mission Statement / Bio
              if (agent.bio.isNotEmpty) ...[
                Text('MISSION STATEMENT', style: T.labelUpMd),
                const SizedBox(height: 8),
                Text(agent.bio,
                    style: T.bodyMd.copyWith(color: T.onSurfaceVar)),
                const SizedBox(height: T.lg),
              ],
              // Current Task
              Text('CURRENT TASK', style: T.labelUpMd),
              const SizedBox(height: 8),
              Text(
                agent.currentTask.isNotEmpty ? agent.currentTask : '—',
                style: T.bodyMd.copyWith(color: T.onSurfaceVar),
              ),
              const SizedBox(height: T.lg),
              // Assigned Tools
              if (agent.assignedTools.isNotEmpty) ...[
                Text('TOOL GRANTS', style: T.labelUpMd),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: agent.assignedTools
                      .map((t) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration:
                                BoxDecoration(border: Border.all(color: T.border)),
                            child: Text(t, style: T.labelUpXs),
                          ))
                      .toList(),
                ),
                const SizedBox(height: T.lg),
              ],
              // Subtask Checklist
              if (agent.subtaskChecklist.isNotEmpty) ...[
                Text('RESPONSIBILITIES', style: T.labelUpMd),
                const SizedBox(height: 8),
                for (final item in agent.subtaskChecklist) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 16, color: T.onSurfaceVar),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(item, style: T.bodySm),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- Terminal Console (Compact Preview -> Tap pushes FullTerminalScreen) ---
  Widget _buildTerminalSection(List<TerminalLog> logs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: T.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            'TERMINAL CONSOLE',
            trailing: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullTerminalScreen(service: widget.service),
                  ),
                );
              },
              child: Text('Fullscreen ↗',
                  style: T.labelUpXs.copyWith(color: T.onSurface)),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            key: const Key('terminal_console_card'),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullTerminalScreen(service: widget.service),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                border: Border.all(color: T.border),
              ),
              padding: const EdgeInsets.all(T.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status bar
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: const BoxDecoration(
                          color: T.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text('LIVE',
                          style: T.labelUpXs.copyWith(color: T.success)),
                      const Spacer(),
                      Text(
                        logs.isNotEmpty
                            ? logs.last.formattedTimestamp
                            : '--:--:--',
                        style: T.labelUpXs,
                      ),
                    ],
                  ),
                  Container(
                    height: 1,
                    color: T.border,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  // Last 6 log lines
                  if (logs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '> awaiting execution pipeline telemetry...',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: T.onSurfaceMuted,
                        ),
                      ),
                    )
                  else
                    ...logs.reversed.take(6).toList().reversed.map((log) =>
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            _formatLogLine(log),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: log.logColor,
                              height: 1.45,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                  Container(
                    height: 1,
                    color: T.border,
                    margin: const EdgeInsets.only(top: 8, bottom: 4),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('Tap to expand console ↗', style: T.labelUpXs),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLogLine(TerminalLog log) {
    final prefix = switch (log.type) {
      LogType.success => 'OK ',
      LogType.error => 'ERR',
      LogType.warning => '!! ',
      LogType.command => '>> ',
      LogType.stderr => 'ERR',
      _ => '>  ',
    };
    return '${log.formattedTimestamp} $prefix ${log.message}';
  }

  // --- Artifacts Row: Max 4, Type-Colored, Expand to 2-Col Screen ---
  Widget _buildArtifactSection(List<ArtifactItem> artifacts) {
    final preview = artifacts.take(4).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: T.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            'ARTIFACTS',
            trailing: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ArtifactListScreen(
                      artifacts: artifacts,
                      service: widget.service,
                    ),
                  ),
                );
              },
              child: Text('View all (${artifacts.length}) →',
                  style: T.labelUpXs.copyWith(color: T.onSurface)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: preview.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final a = preview[i];
                final color = ArtifactListScreen.artifactColor(a.type);
                final icon = ArtifactListScreen.artifactIcon(a.type);

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ArtifactListScreen(
                          artifacts: artifacts,
                          service: widget.service,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 100,
                    decoration: BoxDecoration(
                      color: T.background,
                      border: Border.all(color: T.border),
                    ),
                    padding: const EdgeInsets.all(T.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(icon, size: 24, color: color),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              a.name,
                              style: T.labelUpXs.copyWith(color: T.onSurface),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.size, style: T.labelUpXs),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: T.zero,
                              ),
                              child: Text(
                                a.typeLabel,
                                style: T.labelUpXs
                                    .copyWith(color: color, fontSize: 8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  final GoalItem goal;
  final int index;
  final VoidCallback onTap;

  const _GoalRow({
    required this.goal,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = goal.status == GoalStatus.completed;
    final isInProgress = goal.status == GoalStatus.inProgress;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: T.background,
        padding: const EdgeInsets.all(T.md),
        child: Row(
          children: [
            // Step Number Box
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: T.surfaceMuted,
                border: Border.all(color: T.border),
              ),
              child: Center(
                child: Text(
                  '${goal.stepNumber}',
                  style: T.labelUpSm.copyWith(color: T.onSurfaceVar),
                ),
              ),
            ),
            const SizedBox(width: T.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goal.category.toUpperCase(), style: T.labelUpXs),
                  const SizedBox(height: 2),
                  Text(
                    goal.title,
                    style: T.headlineSm.copyWith(
                      color: isCompleted ? T.onSurfaceMuted : T.onSurface,
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Status Badge
            if (isInProgress)
              BadgePill(
                'ACTIVE',
                bg: T.success.withValues(alpha: 0.15),
                textColor: T.success,
              )
            else if (isCompleted)
              const BadgePill(
                'DONE',
                bg: Color(0xFF1E1E1E),
                textColor: T.onSurfaceMuted,
              )
            else
              BadgePill(
                'PENDING',
                bg: T.surfaceMuted,
                textColor: T.onSurfaceVar,
              ),
          ],
        ),
      ),
    );
  }
}
