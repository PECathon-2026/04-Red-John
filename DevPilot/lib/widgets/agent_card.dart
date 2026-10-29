import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

/// Tactile Agent Personnel Card inspired by MYCEL `hire-cards.tsx`.
/// Displays agent portrait / initials, team badge, security clearance,
/// execution phase chip, current assignment task, and elapsed mission timer.
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
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.2),
        boxShadow: AppTheme.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
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
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textDark,
                                    letterSpacing: 0.4,
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
                              _buildTeamBadge(teamColor),
                              const SizedBox(width: 6),
                              _buildPhaseChip(phaseColor),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Elapsed timer pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.darkPill,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        formattedElapsed,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppTheme.borderSubtle,
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
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        agent.currentTask,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textDark,
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
        color: teamColor.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: teamColor.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _darken(teamColor, 0.4),
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }

  Widget _buildClearanceChip() {
    final color = agent.clearanceColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
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

  Widget _buildTeamBadge(Color teamColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: teamColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        agent.team,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: _darken(teamColor, 0.45),
        ),
      ),
    );
  }

  Widget _buildPhaseChip(Color phaseColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: phaseColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
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
              fontWeight: FontWeight.w700,
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
        return AppTheme.bgWarm;
    }
  }

  Color _phaseColor(String phase) {
    switch (phase.toLowerCase()) {
      case 'working':
      case 'compiling':
      case 'running':
        return AppTheme.accentOrange;
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
        return AppTheme.textSecondary;
    }
  }

  Color _darken(Color color, [double amount = 0.3]) {
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
