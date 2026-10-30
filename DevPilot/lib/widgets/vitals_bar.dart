import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

/// Compact 4-column horizontal vitals bar displaying real-time hardware telemetry:
/// CPU%, RAM%, Network throughput (MB/s), and Battery percentage.
///
/// Implements Paper & Lime styling with `surfaceAlt` card background, 24px radius,
/// `labelUppercase` kickers, and Space Grotesk numerals with tabular figures.
class VitalsBar extends StatelessWidget {
  final HardwareVitals vitals;
  final bool compact;

  const VitalsBar({super.key, required this.vitals, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('vitals_bar_card'),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 10 : 14,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: AppTheme.cardRadius,
      ),
      child: Row(
        children: [
          // CPU Metric
          Expanded(
            child: _buildMetricTile(
              icon: Icons.memory_rounded,
              label: 'CPU',
              value: vitals.cpuFormatted,
              percent: vitals.cpuPercent / 100.0,
              progressColor: _colorForLoad(vitals.cpuPercent),
            ),
          ),
          _buildDivider(),

          // RAM Metric
          Expanded(
            child: _buildMetricTile(
              icon: Icons.storage_rounded,
              label: 'RAM',
              value: vitals.ramFormatted,
              percent: vitals.ramPercent / 100.0,
              progressColor: _colorForLoad(vitals.ramPercent),
            ),
          ),
          _buildDivider(),

          // NET Metric
          Expanded(
            child: _buildMetricTile(
              icon: Icons.swap_vert_rounded,
              label: 'NET',
              value: vitals.networkFormatted,
              percent: (vitals.networkMBps / 50.0).clamp(0.0, 1.0),
              progressColor: AppTheme.onSurface,
            ),
          ),
          _buildDivider(),

          // Battery Metric
          Expanded(child: _buildBatteryTile()),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: AppTheme.border,
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required double percent,
    required Color progressColor,
  }) {
    final numeralStyle = AppTheme.numeralSm.copyWith(
      fontSize: compact ? 13 : 15,
      letterSpacing: -0.02 * (compact ? 13 : 15),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppTheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: AppTheme.labelUppercase,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: numeralStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: percent.clamp(0.0, 1.0),
            minHeight: 3,
            backgroundColor: AppTheme.borderStrong,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
      ],
    );
  }

  Widget _buildBatteryTile() {
    final batteryPercent = vitals.batteryPercent;
    final isCharging = vitals.isCharging;
    final progressColor = batteryPercent < 20
        ? AppTheme.statusRed
        : (isCharging ? AppTheme.statusGreen : AppTheme.onSurface);
    final numeralStyle = AppTheme.numeralSm.copyWith(
      fontSize: compact ? 13 : 15,
      letterSpacing: -0.02 * (compact ? 13 : 15),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCharging
                  ? Icons.battery_charging_full_rounded
                  : (batteryPercent < 20
                        ? Icons.battery_alert_rounded
                        : Icons.battery_std_rounded),
              size: 12,
              color: isCharging
                  ? AppTheme.statusGreen
                  : (batteryPercent < 20
                      ? AppTheme.statusRed
                      : AppTheme.onSurfaceVariant),
            ),
            if (isCharging) ...[
              const SizedBox(width: 2),
              const Icon(
                Icons.bolt_rounded,
                size: 12,
                color: AppTheme.accent,
              ),
            ],
            const SizedBox(width: 4),
            Text(
              'BAT',
              style: AppTheme.labelUppercase,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          vitals.batteryFormatted,
          style: numeralStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: (batteryPercent / 100.0).clamp(0.0, 1.0),
            minHeight: 3,
            backgroundColor: AppTheme.borderStrong,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
      ],
    );
  }

  Color _colorForLoad(double load) {
    if (load >= 85) return AppTheme.statusRed;
    if (load >= 70) return AppTheme.statusAmber;
    return AppTheme.onSurface;
  }
}
