import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

/// Compact horizontal vitals bar displaying real-time hardware telemetry:
/// CPU%, RAM%, Network throughput (MB/s), and Battery percentage.
class VitalsBar extends StatelessWidget {
  final HardwareVitals vitals;
  final bool compact;

  const VitalsBar({super.key, required this.vitals, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: AppTheme.bgMain.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle, width: 1),
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
              progressColor: AppTheme.accentOrange,
              isNet: true,
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
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: AppTheme.borderSubtle,
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required double percent,
    required Color progressColor,
    bool isNet = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
            fontFamily: 'monospace',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: percent.clamp(0.0, 1.0),
            minHeight: 3,
            backgroundColor: AppTheme.borderSubtle,
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
        : (isCharging ? AppTheme.statusGreen : AppTheme.textDark);

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
              size: 13,
              color: isCharging ? AppTheme.statusGreen : AppTheme.textSecondary,
            ),
            if (isCharging) ...[
              const SizedBox(width: 2),
              const Icon(
                Icons.bolt_rounded,
                size: 12,
                color: AppTheme.accentOrange,
              ),
            ],
            const SizedBox(width: 4),
            const Flexible(
              child: Text(
                'BAT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          vitals.batteryFormatted,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
            fontFamily: 'monospace',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: (batteryPercent / 100.0).clamp(0.0, 1.0),
            minHeight: 3,
            backgroundColor: AppTheme.borderSubtle,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
      ],
    );
  }

  Color _colorForLoad(double load) {
    if (load >= 85) return AppTheme.statusRed;
    if (load >= 70) return AppTheme.statusAmber;
    return AppTheme.textDark;
  }
}
