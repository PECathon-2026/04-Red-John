import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'macro_deck.dart';
import 'vitals_bar.dart';

/// Primary tactical card for Image 1 Home Screen.
/// Displays active pipeline task, live duration counter, E2EE security badge,
/// embedded hardware vitals bar, and quick-action macro deck.
class RunningTaskCard extends StatelessWidget {
  final RunningTask task;
  final HardwareVitals vitals;
  final void Function(String action) onMacroAction;
  final VoidCallback? onTap;

  const RunningTaskCard({
    super.key,
    required this.task,
    required this.vitals,
    required this.onMacroAction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: AppTheme.cardRadius,
        border: Border.all(
          color: AppTheme.borderSubtle,
          width: 1.2,
        ),
        boxShadow: AppTheme.cardShadow,
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
                // Top Row: Status chip, timer pill & security badge
                _buildHeaderRow(),

                const SizedBox(height: 16),

                // Middle: Pipeline category & task title
                _buildTitleSection(),

                const SizedBox(height: 14),

                // Task Progress indicator
                _buildProgressSection(),

                const SizedBox(height: 16),

                // Vitals metrics bar
                VitalsBar(vitals: vitals),

                const SizedBox(height: 16),

                // Tactile Macro Action Deck
                MacroDeck(onActionTriggered: onMacroAction),
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
        // Pulsing Phase Indicator Chip
        _PulsingStatusChip(
          label: task.phaseLabel,
          color: task.statusColor,
        ),

        const Spacer(),

        // Elapsed duration pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.darkPill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            task.elapsedString,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // LAN E2EE Lock badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.bgWarm,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.borderSubtle,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_rounded,
                size: 11,
                color: AppTheme.statusGreen,
              ),
              const SizedBox(width: 4),
              Text(
                task.securityBadge,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                  letterSpacing: 0.3,
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
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          task.taskName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
            letterSpacing: -0.3,
            height: 1.25,
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
            const Text(
              'PROGRESS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              '$percent%',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.accentOrange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: task.progress.clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: AppTheme.bgWarm,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentOrange),
          ),
        ),
      ],
    );
  }
}

class _PulsingStatusChip extends StatefulWidget {
  final String label;
  final Color color;

  const _PulsingStatusChip({
    required this.label,
    required this.color,
  });

  @override
  State<_PulsingStatusChip> createState() => _PulsingStatusChipState();
}

class _PulsingStatusChipState extends State<_PulsingStatusChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Only repeat animation in non-test runtime to allow pumpAndSettle in test suites
    final isTest = WidgetsBinding.instance.runtimeType
        .toString()
        .contains('TestWidgetsFlutterBinding');
    if (!isTest) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.color.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: 0.4 + (_controller.value * 0.6),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: widget.color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
