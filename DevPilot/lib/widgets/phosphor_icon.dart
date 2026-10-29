import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';

/// Helper widget to render local Phosphor SVG icons from assets/icons/phosphor/
/// with a graceful Material icon fallback for testing and offline resilience.
class PhosphorIcon extends StatelessWidget {
  final String icon;
  final double size;
  final Color? color;

  const PhosphorIcon(
    this.icon, {
    super.key,
    this.size = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = 'assets/icons/phosphor/$icon.svg';
    final iconColor = color ?? T.onSurface;

    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      placeholderBuilder: (context) => Icon(
        _fallbackIcon(icon),
        size: size,
        color: iconColor,
      ),
    );
  }

  static IconData _fallbackIcon(String name) {
    switch (name) {
      case 'rocket-launch':
      case 'rocket':
        return Icons.rocket_launch_outlined;
      case 'cpu':
        return Icons.memory_outlined;
      case 'hard-drive':
        return Icons.storage_outlined;
      case 'wifi-high':
        return Icons.wifi;
      case 'gauge':
        return Icons.speed_outlined;
      case 'terminal-window':
      case 'terminal':
        return Icons.terminal_outlined;
      case 'folders':
      case 'folder-simple':
        return Icons.folder_outlined;
      case 'git-diff':
      case 'git-branch':
      case 'git-commit':
        return Icons.difference_outlined;
      case 'check-circle':
        return Icons.check_circle_outline;
      case 'warning-circle':
        return Icons.warning_amber_outlined;
      case 'user':
        return Icons.person_outline;
      case 'users-three':
        return Icons.group_outlined;
      case 'gear-six':
        return Icons.settings_outlined;
      case 'sparkle':
        return Icons.auto_awesome_outlined;
      case 'clock':
        return Icons.schedule_outlined;
      case 'arrow-right':
        return Icons.arrow_forward;
      case 'arrow-left':
        return Icons.arrow_back;
      case 'play':
        return Icons.play_arrow;
      case 'house':
        return Icons.home_outlined;
      case 'squares-four':
      case 'grid-four':
        return Icons.grid_view_outlined;
      case 'package':
      case 'archive':
      case 'stack':
        return Icons.inventory_2_outlined;
      case 'sliders':
      case 'faders':
        return Icons.tune_outlined;
      case 'gear':
        return Icons.settings_outlined;
      case 'arrows-down-up':
        return Icons.swap_vert_rounded;
      case 'arrow-clockwise':
      case 'arrows-clockwise':
        return Icons.refresh_rounded;
      case 'battery-charging':
        return Icons.battery_charging_full_rounded;
      case 'battery-warning':
        return Icons.battery_alert_rounded;
      case 'battery-full':
      case 'battery-high':
      case 'battery-medium':
      case 'battery-low':
        return Icons.battery_std_rounded;
      case 'lightning':
        return Icons.bolt_rounded;
      case 'lock':
        return Icons.lock_rounded;
      case 'copy':
        return Icons.copy_rounded;
      case 'trash':
        return Icons.delete_outline_rounded;
      case 'pause':
      case 'pause-circle':
        return Icons.pause_circle_outline;
      case 'stop':
      case 'stop-circle':
        return Icons.stop_circle_rounded;
      case 'device-mobile':
        return Icons.install_mobile_rounded;
      case 'image':
        return Icons.image_outlined;
      case 'file-text':
      case 'article':
        return Icons.description_outlined;
      case 'file-zip':
        return Icons.folder_zip_outlined;
      case 'file':
        return Icons.insert_drive_file_outlined;
      case 'code':
      case 'brackets-curly':
        return Icons.code_rounded;
      case 'database':
        return Icons.storage_rounded;
      case 'shield-check':
        return Icons.security_rounded;
      case 'magnifying-glass':
        return Icons.search_rounded;
      case 'funnel':
        return Icons.filter_alt_outlined;
      case 'x':
        return Icons.close_rounded;
      case 'plus':
        return Icons.add;
      default:
        return Icons.widgets_outlined;
    }
  }
}
