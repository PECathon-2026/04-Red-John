import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../services/telemetry_service.dart';
import '../theme/app_theme.dart';
import '../widgets/agent_card.dart';
import '../widgets/artifact_stream.dart';
import '../widgets/macro_deck.dart';
import '../widgets/terminal_feed.dart';
import '../widgets/vitals_bar.dart';

/// Full implementation of the Paper & Lime Project Command Center (DetailScreen).
///
/// Features:
/// - Screen-based navigation with top back button (`onBack`).
/// - Editorial header with project title and live elapsed timer in electric lime pill.
/// - Ink schedule card with Space Grotesk display numeral "21", LAN status, and host share button.
/// - Team members section with reminder action.
/// - Numbered pipeline goals in white raised cards (`surfaceRaised`).
/// - **Active Agent Roster (inside current project)**: Atlas, Dev, Nisha in white raised cards.
/// - **Live Terminal Feed (inside current project)**: color-coded streaming console with CLI trigger.
/// - **Artifact Stream (inside current project)**: horizontal generated file preview cards.
/// - **Host Hardware Vitals & Tactile Macro Deck (inside current project)**: CPU/RAM/NET/BAT tabular strip and quick actions.
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
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Host link copied to clipboard: devpilot.lan',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onInverse,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.surfaceInverse,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleSendReminder() {
    HapticFeedback.mediumImpact();
    final count = widget.service.agents.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Telemetry reminder dispatched to $count agents.',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.onInverse,
          ),
        ),
        backgroundColor: AppTheme.surfaceInverse,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: widget.service,
          builder: (context, _) {
            final agents = widget.service.agents;
            final goals = widget.service.goals;
            final logs = widget.service.logs;
            final artifacts = widget.service.artifacts;
            final vitals = widget.service.vitals;
            final currentTask = widget.service.currentTask;

            return SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. Top Navigation Bar ---
                  _buildTopBar(currentTask.elapsedString),

                  const SizedBox(height: 12),

                  // --- 2. Title & Date Subtitle ---
                  _buildTitleSection(),

                  const SizedBox(height: 20),

                  // --- 3. Session & Host Share Pill Card ---
                  _buildSessionCard(),

                  const SizedBox(height: 24),

                  // --- 4. Members & Team Section ---
                  _buildMembersSection(agents),

                  const SizedBox(height: 24),

                  // --- 5. Goals & Pipeline Steps Sheet (White Raised) ---
                  _buildGoalsSheet(goals),

                  const SizedBox(height: 28),

                  // --- 6. Active Agent Roster (Inside Project) ---
                  _buildActiveAgentRoster(agents),

                  const SizedBox(height: 28),

                  // --- 7. Live Terminal Feed (Inside Project) ---
                  _buildTerminalSection(logs),

                  const SizedBox(height: 28),

                  // --- 8. Artifact Stream (Inside Project) ---
                  _buildArtifactSection(artifacts),

                  const SizedBox(height: 28),

                  // --- 9. Host Vitals & Tactile Macro Deck (Inside Project) ---
                  _buildHostVitalsAndMacros(vitals),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- 1. Top Navigation Bar ---
  Widget _buildTopBar(String elapsed) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Round Icon Back Button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onBack();
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: AppTheme.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back,
                  size: 18,
                  color: AppTheme.onSurface,
                ),
              ),
            ),
          ),

          // Center Live Duration Pill (Electric Lime Accent)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary, // Electric Lime #D7FE47
              borderRadius: AppTheme.pillRadius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.onPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  elapsed.isNotEmpty ? elapsed : 'T+08:42',
                  style: const TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),

          // Right "Done" Ink Pill Button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onBack();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceInverse,
                borderRadius: AppTheme.pillRadius,
              ),
              child: const Text(
                'Done',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onInverse,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Title Section ---
  Widget _buildTitleSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.project.title,
            style: AppTheme.displayLarge.copyWith(
              color: AppTheme.onSurface,
              fontSize: 36,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.project.subtitle,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Session & Host Card ---
  Widget _buildSessionCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceInverse, // Ink #0E0F0C
          borderRadius: AppTheme.cardRadius,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: Space Grotesk display numeral "21"
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '21',
                        style: AppTheme.displayMd.copyWith(
                          color: AppTheme.onInverse,
                          fontSize: 38,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'November, 10 AM',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.onInverse.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppTheme.primary, // Electric Lime Dot
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'LAN E2EE • ',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primary,
                        ),
                      ),
                      Text(
                        'devpilot.lan',
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.onInverse.withValues(alpha: 0.8),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Right: Host Share link pill
            GestureDetector(
              onTap: _handleShareLink,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surface, // Warm Paper Button
                  borderRadius: AppTheme.pillRadius,
                ),
                child: const Row(
                  children: [
                    Icon(Icons.link_rounded, size: 16, color: AppTheme.onSurface),
                    SizedBox(width: 6),
                    Text(
                      'Share link',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 4. Members Section ---
  Widget _buildMembersSection(List<AgentItem> agents) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Members (${agents.length})', style: AppTheme.headlineSm),
              GestureDetector(
                onTap: _handleSendReminder,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceAlt,
                    borderRadius: AppTheme.pillRadius,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.send_rounded, size: 13, color: AppTheme.onSurface),
                      const SizedBox(width: 6),
                      Text(
                        'Send telemetry reminder',
                        style: AppTheme.labelSm.copyWith(
                          color: AppTheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: Stack(
              children: [
                for (int i = 0; i < agents.length && i < 6; i++)
                  Positioned(
                    left: i * 26.0,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceAlt,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.surface, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          agents[i].name.substring(0, 1),
                          style: const TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                          ),
                        ),
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

  // --- 5. Goals Sheet (White Raised) ---
  Widget _buildGoalsSheet(List<GoalItem> goals) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceRaised, // Pure White #FFFFFF
          borderRadius: AppTheme.cardRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Goals (${goals.length})', style: AppTheme.headlineSm),
                Text('PIPELINE QUEUE', style: AppTheme.labelUppercase),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: goals.length,
              separatorBuilder: (_, _) => const Divider(
                height: 24,
                thickness: 1,
                color: AppTheme.border,
              ),
              itemBuilder: (context, index) {
                final goal = goals[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Number Badge
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AppTheme.surfaceAlt,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.category.toUpperCase(),
                            style: AppTheme.labelUppercase,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            goal.title,
                            style: AppTheme.cardTitle.copyWith(
                              fontSize: 15,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildGoalStatusChip(goal.status),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalStatusChip(GoalStatus status) {
    String label;
    Color bg;
    Color textColor;

    switch (status) {
      case GoalStatus.completed:
        label = 'Completed';
        bg = AppTheme.primaryDeep.withValues(alpha: 0.15);
        textColor = AppTheme.onSurface;
        break;
      case GoalStatus.inProgress:
        label = 'Active';
        bg = AppTheme.primary;
        textColor = AppTheme.onPrimary;
        break;
      case GoalStatus.failed:
      case GoalStatus.blocked:
        label = 'Blocked';
        bg = AppTheme.accent.withValues(alpha: 0.15);
        textColor = AppTheme.accent;
        break;
      case GoalStatus.pending:
        label = 'Pending';
        bg = AppTheme.surfaceAlt;
        textColor = AppTheme.onSurfaceVariant;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppTheme.pillRadius,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  // --- 6. Active Agent Roster (Inside Project) ---
  Widget _buildActiveAgentRoster(List<AgentItem> agents) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ACTIVE AGENT ROSTER (${agents.length})', style: AppTheme.labelUppercase),
                  const SizedBox(height: 4),
                  Text('Running Subagents', style: AppTheme.headlineSm),
                ],
              ),
              const Icon(Icons.psychology_outlined, size: 20, color: AppTheme.onSurface),
            ],
          ),
          const SizedBox(height: 14),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: agents.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final agent = agents[index];
              return AgentCard(
                agent: agent,
                onTap: () => widget.onOpenAgent?.call(agent),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- 7. Live Terminal Feed (Inside Project) ---
  Widget _buildTerminalSection(List<TerminalLog> logs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LIVE TELEMETRY STREAM', style: AppTheme.labelUppercase),
                    const SizedBox(height: 4),
                    Text('Terminal Console', style: AppTheme.headlineSm),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.onOpenCli,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceInverse,
                    borderRadius: AppTheme.pillRadius,
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.terminal_rounded, size: 14, color: AppTheme.onInverse),
                      SizedBox(width: 6),
                      Text(
                        'Open CLI Terminal',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onInverse,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TerminalFeed(
            logs: logs,
            onClear: widget.service.clearLogs,
          ),
        ],
      ),
    );
  }

  // --- 8. Artifact Section (Inside Project) ---
  Widget _buildArtifactSection(List<ArtifactItem> artifacts) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('OUTPUT ARTIFACTS', style: AppTheme.labelUppercase),
                  const SizedBox(height: 4),
                  Text('Artifact Stream (${artifacts.length})', style: AppTheme.headlineSm),
                ],
              ),
              const Icon(Icons.auto_awesome_outlined, size: 18, color: AppTheme.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 14),
          ArtifactStream(
            artifacts: artifacts,
            onArtifactTap: (artifact) {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Previewing artifact: ${artifact.name}'),
                  backgroundColor: AppTheme.surfaceInverse,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- 9. Host Vitals & Macros (Inside Project) ---
  Widget _buildHostVitalsAndMacros(HardwareVitals vitals) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HOST VITALS & COMMAND DECK', style: AppTheme.labelUppercase),
          const SizedBox(height: 12),
          VitalsBar(vitals: vitals),
          const SizedBox(height: 14),
          MacroDeck(
            onAction: (action) {
              widget.service.triggerAction(action);
            },
          ),
        ],
      ),
    );
  }
}
