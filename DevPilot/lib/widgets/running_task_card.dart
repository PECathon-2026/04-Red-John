import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import 'macro_deck.dart';
import 'vitals_bar.dart';

/// Primary hero active card for DevPilot.
/// Displays active pipeline task, electric lime status pill, live duration counter
/// with Space Grotesk tabular figures, LAN E2EE security badge,
/// and optionally embedded hardware vitals bar and macro deck.
///
/// Implements Paper & Lime language: `surfaceAlt` fill, 24px radius, flat without shadows.
class RunningTaskCard extends StatelessWidget {
  final RunningTask task;
  final HardwareVitals? vitals;
  final void Function(String action)? onMacroAction;
  final VoidCallback? onTap;

  const RunningTaskCard({
    super.key,
    required this.task,
    this.vitals,
    this.onMacroAction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('running_task_card'),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: AppTheme.cardRadius,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppTheme.cardRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppTheme.cardRadius,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row: Electric lime status chip, timer pill & security badge
                _buildHeaderRow(),

                const SizedBox(height: 16),

                // Middle: Pipeline category & task title
                _buildTitleSection(),

                const SizedBox(height: 16),

                // Task Progress indicator
                _buildProgressSection(),

                // Optional Vitals metrics bar
                if (vitals != null) ...[
                  const SizedBox(height: 16),
                  VitalsBar(vitals: vitals!),
                ],

                // Optional Tactile Macro Action Deck
                if (onMacroAction != null) ...[
                  const SizedBox(height: 16),
                  MacroDeck(onActionTriggered: onMacroAction!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      children: [
        // Electric lime status pill
        Container(
          key: const Key('running_task_status_chip'),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.primary,
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
              const SizedBox(width: 6),
              Text(
                task.phaseLabel,
                style: AppTheme.labelMd.copyWith(
                  color: AppTheme.onPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Elapsed duration counter pill (Space Grotesk tabular figures)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.surfaceInverse,
            borderRadius: AppTheme.pillRadius,
          ),
          child: Text(
            task.elapsedString,
            style: AppTheme.numeralSm.copyWith(
              fontSize: 11,
              color: AppTheme.onInverse,
              letterSpacing: 0.5,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // LAN E2EE Lock badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.surfaceRaised,
            borderRadius: AppTheme.pillRadius,
            border: Border.all(color: AppTheme.border, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_rounded,
                size: 11,
                color: AppTheme.onSurface,
              ),
              const SizedBox(width: 4),
              Text(
                task.securityBadge,
                style: AppTheme.labelSm.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.pipelineName,
          style: AppTheme.labelUppercase,
        ),
        const SizedBox(height: 6),
        Text(
          task.taskName,
          style: AppTheme.headlineMd.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    final percent = (task.progress * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PROGRESS',
              style: AppTheme.labelUppercase,
            ),
            Text(
              '$percent%',
              style: AppTheme.numeralSm.copyWith(
                fontSize: 12,
                color: AppTheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: task.progress.clamp(0.0, 1.0),
            minHeight: 4,
            backgroundColor: AppTheme.borderStrong,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
