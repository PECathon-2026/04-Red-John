import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/models.dart';
import '../../theme/app_theme.dart';

/// Tactical Agent Dossier Modal inspired by MYCEL `hire-dossier-card.tsx`.
///
/// Features rich clearance badges (GREEN/AMBER/RED), team metadata, status phase,
/// assigned tools, live execution timer, subtask checklist, and operator control actions.
class AgentDossierModal extends StatelessWidget {
  final AgentItem agent;
  final VoidCallback? onClose;
  final void Function(String action)? onAction;

  const AgentDossierModal({
    super.key,
    required this.agent,
    this.onClose,
    this.onAction,
  });

  /// Static helper to display the Agent Dossier as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required AgentItem agent,
    void Function(String action)? onAction,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: AgentDossierModal(
          agent: agent,
          onClose: () => Navigator.of(ctx).pop(),
          onAction: onAction,
        ),
      ),
    );
  }

  Color get _clearanceColor {
    switch (agent.clearance.toUpperCase()) {
      case 'RED':
        return AppTheme.statusRed;
      case 'AMBER':
        return AppTheme.statusAmber;
      case 'GREEN':
      default:
        return AppTheme.statusGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tools = agent.assignedTools.isNotEmpty
        ? agent.assignedTools
        : const ['compiler', 'playwright', 'docker', 'rag_query'];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        maxWidth: 500,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: AppTheme.floatingShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle pill
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Scrollable Dossier Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Row: Agent Identification & Close Button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar Monogram Container
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: AppTheme.bgWarm,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _clearanceColor.withValues(alpha: 0.5),
                            width: 2,
                          ),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Center(
                          child: Text(
                            agent.name.isNotEmpty
                                ? agent.name[0].toUpperCase()
                                : 'A',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: _clearanceColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Name, ID & Team
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  agent.name,
                                  style: AppTheme.displayMedium.copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.darkPill,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    agent.id.toUpperCase(),
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
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                // Team badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardPeach,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    agent.team,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                ),

                                // Clearance badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _clearanceColor.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _clearanceColor.withValues(
                                        alpha: 0.6,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.shield_rounded,
                                        size: 13,
                                        color: _clearanceColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        agent.clearance.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: _clearanceColor,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Phase Pill
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardMint,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    agent.phase,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Close button
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 24,
                          color: AppTheme.textDark,
                        ),
                        onPressed:
                            onClose ?? () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Bio / Operational Profile
                  if (agent.bio.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.bgMain,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Text(
                        agent.bio,
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textDark,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Current Assignment Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.bgWarm.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.psychology_outlined,
                              size: 18,
                              color: AppTheme.accentOrange,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'CURRENT ASSIGNMENT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: AppTheme.accentOrange,
                              ),
                            ),
                            const Spacer(),
                            if (agent.elapsed.isNotEmpty) ...[
                              Icon(
                                Icons.timer_outlined,
                                size: 14,
                                color: AppTheme.textSecondary.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                agent.elapsed,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          agent.currentTask,
                          style: AppTheme.titleMedium.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Assigned Tools Section
                  const Text(
                    'ASSIGNED TOOLS & RUNTIMES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tools.map((tool) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.bgMain,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderMedium),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.terminal_rounded,
                              size: 13,
                              color: AppTheme.accentOrange,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tool,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Subtask Checklist Section
                  if (agent.subtaskChecklist.isNotEmpty) ...[
                    const Text(
                      'EXECUTION SUBTASKS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.bgMain,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Column(
                        children: agent.subtaskChecklist.asMap().entries.map((
                          entry,
                        ) {
                          final idx = entry.key;
                          final subtask = entry.value;
                          final isDone = idx == 0; // Simulated progress
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              border: idx < agent.subtaskChecklist.length - 1
                                  ? const Border(
                                      bottom: BorderSide(
                                        color: AppTheme.borderSubtle,
                                      ),
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isDone
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  size: 18,
                                  color: isDone
                                      ? AppTheme.statusGreen
                                      : AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    subtask,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isDone
                                          ? AppTheme.textSecondary
                                          : AppTheme.textDark,
                                      decoration: isDone
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),

          // Pinned Action Buttons Row (Reassign, Pause Agent)
          Container(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onAction?.call('pause');
                    },
                    icon: const Icon(
                      Icons.pause_circle_outline_rounded,
                      size: 18,
                    ),
                    label: const Text('Pause Agent'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textDark,
                      side: const BorderSide(color: AppTheme.borderMedium),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppTheme.pillRadius,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onAction?.call('reassign');
                    },
                    icon: const Icon(
                      Icons.swap_horiz_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Reassign Agent',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.darkPill,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppTheme.pillRadius,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
}
