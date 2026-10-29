import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

/// Tactile Agent Personnel Card.
/// Displays agent avatar / initials, tracked-out uppercase team kicker,
/// security clearance badge, active execution phase chip, current assignment task,
/// and elapsed mission timer with tabular numerals.
///
/// Implements Paper & Lime white raised card (`surfaceRaised` #FFFFFF, 24px radius,
/// flat without drop shadows).
class AgentCard extends StatelessWidget {
  final AgentItem agent;
  final VoidCallback? onTap;

  const AgentCard({super.key, required this.agent, this.onTap});

  @override
  Widget build(BuildContext context) {
    final teamColor = _teamColor(agent.team);
    final phaseColor = _phaseColor(agent.phase);
    final formattedElapsed = agent.elapsed.isEmpty
        ? 'T+00:00'
        : (agent.elapsed.startsWith('T+')
              ? agent.elapsed
              : 'T+${agent.elapsed}');

    return Container(
      key: const Key('agent_card'),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: AppTheme.cardRadius,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppTheme.cardRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppTheme.cardRadius,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top row: Avatar + Name + Clearance + Elapsed timer
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar / Initials container
                    _buildAvatar(teamColor),

                    const SizedBox(width: 12),

                    // Agent Name & Clearance Chip
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  agent.name,
                                  style: AppTheme.headlineSm.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildClearanceChip(),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildTeamBadge(),
                              const SizedBox(width: 8),
                              _buildPhaseChip(phaseColor),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Elapsed timer pill (ink surface, Space Grotesk tabular figures)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceInverse,
                        borderRadius: AppTheme.pillRadius,
                      ),
                      child: Text(
                        formattedElapsed,
                        style: AppTheme.numeralSm.copyWith(
                          fontSize: 10,
                          color: AppTheme.onInverse,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppTheme.border,
                ),
                const SizedBox(height: 10),

                // Current task assignment
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2.0),
                      child: Icon(
                        Icons.terminal_rounded,
                        size: 13,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        agent.currentTask,
                        style: AppTheme.bodySm.copyWith(
                          color: AppTheme.onSurface,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(Color teamColor) {
    final initials = agent.name.length >= 2
        ? agent.name.substring(0, 2).toUpperCase()
        : agent.name.toUpperCase();

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: AppTheme.thumbRadius,
        border: Border.all(color: AppTheme.border, width: 1.0),
      ),
      child: Center(
        child: Text(
          initials,
          style: AppTheme.headlineSm.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildClearanceChip() {
    final color = agent.clearanceColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppTheme.pillRadius,
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        agent.clearance,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildTeamBadge() {
    return Text(
      agent.team.toUpperCase(),
      style: AppTheme.labelUppercase,
    );
  }

  Widget _buildPhaseChip(Color phaseColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: phaseColor.withValues(alpha: 0.12),
        borderRadius: AppTheme.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: phaseColor,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            agent.phase,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: phaseColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _teamColor(String team) {
    switch (team.toLowerCase()) {
      case 'executive':
        return const Color(0xFFFFD700);
      case 'intelligence':
        return const Color(0xFFBCD8CE);
      case 'architecture':
        return const Color(0xFFC9BEDE);
      case 'resilience':
        return const Color(0xFFB9D8AC);
      case 'network':
        return const Color(0xFFAAEBFD);
      case 'council':
        return const Color(0xFFE3C1C8);
      default:
        return AppTheme.surfaceAlt;
    }
  }

  Color _phaseColor(String phase) {
    switch (phase.toLowerCase()) {
      case 'working':
      case 'compiling':
      case 'running':
        return AppTheme.accent;
      case 'done':
      case 'completed':
      case 'success':
        return AppTheme.statusGreen;
      case 'standby':
      case 'idle':
      case 'paused':
        return AppTheme.statusAmber;
      case 'failed':
      case 'blocked':
        return AppTheme.statusRed;
      default:
        return AppTheme.onSurfaceVariant;
    }
  }
}
