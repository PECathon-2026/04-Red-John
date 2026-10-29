import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/telemetry_service.dart';
import '../theme/app_theme.dart';
import '../widgets/artifact_stream.dart';
import '../widgets/terminal_feed.dart';

/// Full implementation of Image 2 Detail & Pipeline Screen.
///
/// Features:
/// - Warm cream beige `#F6ECD9` header background (`AppTheme.bgWarm`).
/// - Navigation top bar with `< Back` and `Done` buttons.
/// - Giant bold project title and date subtitle.
/// - Image 2 session cards: Dark pill schedule card and Share link card.
/// - Members & agents section with overlapping avatar stack and reminder capsule.
/// - Pure white rounded sheet (`Radius.circular(32)`) containing:
///   - Goals & pipeline step checklist with circular pastel badges.
///   - Embedded Live Terminal Feed console (`TerminalFeed`).
///   - Embedded Artifact Stream carousel (`ArtifactStream`).
///   - Tactile "Open CLI Terminal" bottom action button.
/// - Reactive updates with `ListenableBuilder(listenable: service)`.
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
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Host link copied to clipboard: devpilot.lan',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.darkPill,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.darkPill,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: widget.service,
          builder: (context, _) {
            final goals = widget.service.goals;
            final logs = widget.service.logs;
            final artifacts = widget.service.artifacts;
            final agents = widget.service.agents;

            return SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Image 2 Top Navigation Bar ---
                  _buildTopBar(),

                  // --- Image 2 Header Title & Date ---
                  _buildHeaderTitle(),

                  const SizedBox(height: 18),

                  // --- Image 2 Session / Schedule Cards Row ---
                  _buildSessionCardsRow(),

                  const SizedBox(height: 22),

                  // --- Image 2 Members & Agents Section ---
                  _buildMembersSection(agents),

                  const SizedBox(height: 24),

                  // --- Image 2 Pure White Rounded Sheet ---
                  _buildWhiteSheet(goals, logs, artifacts),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- 1. Top Navigation Bar ---
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back arrow button
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.textDark, size: 22),
              onPressed: () {
                HapticFeedback.lightImpact();
                widget.onBack();
              },
            ),
          ),

          // Done text button on right
          TextButton(
            key: const Key('detail_done_button'),
            onPressed: () {
              HapticFeedback.lightImpact();
              widget.onBack();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              backgroundColor: Colors.white.withValues(alpha: 0.7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Done',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Title & Date Subtitle ---
  Widget _buildHeaderTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project Title
          Text(
            widget.project.title,
            style: AppTheme.displayLarge.copyWith(
              fontSize: 34,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 4),

          // Date Subtitle
          Text(
            widget.project.subtitle.isNotEmpty
                ? widget.project.subtitle
                : 'November 18th, 2026',
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Session / Schedule Cards (Row) ---
  Widget _buildSessionCardsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          // Left: Dark rounded pill card (#161618)
          Expanded(
            flex: 5,
            child: Container(
              height: 140,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.darkPill,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'DAY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white70,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: Colors.white60,
                      ),
                    ],
                  ),
                  const Text(
                    '21',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  const Text(
                    'November, 10 AM',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Right: Light beige pill card with Location & Share link button
          Expanded(
            flex: 6,
            child: Container(
              height: 140,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.borderSubtle,
                  width: 1.2,
                ),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'devpilot.lan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),

                  // Tactile Share link pill button
                  Material(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: _handleShareLink,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.borderMedium,
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.link_rounded, size: 15, color: AppTheme.textDark),
                            SizedBox(width: 6),
                            Text(
                              'Share link',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. Members / Agents Section ---
  Widget _buildMembersSection(List<AgentItem> agents) {
    final memberCount = agents.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with title and + button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Members ($memberCount)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                  letterSpacing: -0.2,
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.borderSubtle, width: 1),
                ),
                child: const Icon(Icons.add, size: 18, color: AppTheme.textDark),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Capsule button: Stacked avatars + "Send telemetry reminder" + chevron
          Material(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: _handleSendReminder,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.borderSubtle,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar stack
                    _buildAvatarStack(agents),

                    const SizedBox(width: 12),

                    // Label
                    const Expanded(
                      child: Text(
                        'Send telemetry reminder',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),

                    // Chevron >
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarStack(List<AgentItem> agents) {
    final displayAgents = agents.take(4).toList();
    const colors = [
      Color(0xFFFFD700),
      Color(0xFFAAEBFD),
      Color(0xFFE3C1C8),
      Color(0xFFB5EAD7),
    ];

    return SizedBox(
      height: 28,
      width: (displayAgents.length * 18.0) + 12,
      child: Stack(
        children: [
          for (int i = 0; i < displayAgents.length; i++)
            Positioned(
              left: i * 18.0,
              child: GestureDetector(
                onTap: () => widget.onOpenAgent?.call(displayAgents[i]),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colors[i % colors.length],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Center(
                    child: Text(
                      displayAgents[i].name.isNotEmpty
                          ? displayAgents[i].name.substring(0, 1).toUpperCase()
                          : 'A',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- 5. Pure White Rounded Sheet ---
  Widget _buildWhiteSheet(
    List<GoalItem> goals,
    List<TerminalLog> logs,
    List<ArtifactItem> artifacts,
  ) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(color: AppTheme.borderSubtle, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header: "Goals (N)" + add button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Goals (${goals.length})',
                style: AppTheme.titleLarge,
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.bgMain,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.borderSubtle, width: 1),
                ),
                child: const Icon(Icons.add, size: 18, color: AppTheme.textDark),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Goal Items list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: goals.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final goal = goals[index];
              return _GoalStepTile(
                goal: goal,
                pastelColor: _getPastelColorForIndex(index),
              );
            },
          ),

          const SizedBox(height: 28),

          // Embedded Live Monospace Terminal Feed
          TerminalFeed(
            logs: logs,
            onClear: () => widget.service.clearLogs(),
          ),

          const SizedBox(height: 26),

          // Embedded Artifact Stream Carousel
          ArtifactStream(
            artifacts: artifacts,
            onArtifactTap: (artifact) {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Previewing artifact: ${artifact.name}'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),

          const SizedBox(height: 28),

          // Bottom Bar Action: "Open CLI Terminal"
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                widget.onOpenCli?.call();
              },
              icon: const Icon(Icons.terminal_rounded, size: 20, color: Colors.white),
              label: const Text(
                'Open CLI Terminal',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.darkPill,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPastelColorForIndex(int index) {
    switch (index % 4) {
      case 0:
        return AppTheme.cardPeach;
      case 1:
        return AppTheme.cardMint;
      case 2:
        return AppTheme.cardLavender;
      case 3:
      default:
        return const Color(0xFFFFF3C4);
    }
  }
}

/// Goal / Pipeline Step Tile widget inside the Image 2 White Rounded Sheet.
class _GoalStepTile extends StatelessWidget {
  final GoalItem goal;
  final Color pastelColor;

  const _GoalStepTile({
    required this.goal,
    required this.pastelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgMain,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.borderSubtle,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular number badge with soft pastel background
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: pastelColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                '${goal.stepNumber}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Step Category & Bold Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.category.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  goal.title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                if (goal.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    goal.description,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textSecondary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Status Badge
          _buildStatusBadge(goal),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(GoalItem goal) {
    switch (goal.status) {
      case GoalStatus.completed:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.statusGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.statusGreen),
              SizedBox(width: 4),
              Text(
                'Completed',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.statusGreen,
                ),
              ),
            ],
          ),
        );

      case GoalStatus.inProgress:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.accentOrange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 11,
                height: 11,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentOrange),
                ),
              ),
              SizedBox(width: 6),
              Text(
                'Active',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentOrange,
                ),
              ),
            ],
          ),
        );

      case GoalStatus.failed:
      case GoalStatus.blocked:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.statusRed.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 14, color: AppTheme.statusRed),
              SizedBox(width: 4),
              Text(
                'Blocked',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.statusRed,
                ),
              ),
            ],
          ),
        );

      case GoalStatus.pending:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Pending',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        );
    }
  }
}
