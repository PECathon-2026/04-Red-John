import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Tactile Macro Deck providing 4 immediate system operations:
/// "Deploy", "Run Tests", "Restart Docker", and "Kill All".
///
/// Implements Paper & Lime tactile ink pills (`surfaceInverse` #0E0F0C, height 44px,
/// `pillRadius` 9999px, text #F4F2EC, zero drop shadows).
class MacroDeck extends StatelessWidget {
  final void Function(String action)? onActionTriggered;
  final void Function(String action)? onAction;
  final bool isPending;

  const MacroDeck({
    super.key,
    this.onActionTriggered,
    this.onAction,
    this.isPending = false,
  });

  static const List<_MacroConfig> _actions = [
    _MacroConfig(
      label: 'Deploy',
      icon: Icons.rocket_launch_rounded,
      isDestructive: false,
    ),
    _MacroConfig(
      label: 'Run Tests',
      icon: Icons.play_arrow_rounded,
      isDestructive: false,
    ),
    _MacroConfig(
      label: 'Restart Docker',
      icon: Icons.refresh_rounded,
      isDestructive: false,
    ),
    _MacroConfig(
      label: 'Kill All',
      icon: Icons.stop_circle_rounded,
      isDestructive: true,
    ),
  ];

  void _handleTrigger(String action) {
    if (onAction != null) {
      onAction!(action);
    } else if (onActionTriggered != null) {
      onActionTriggered!(action);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _actions.map((config) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _TactileMacroButton(
              config: config,
              isPending: isPending,
              onPressed: () => _handleTrigger(config.label),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MacroConfig {
  final String label;
  final IconData icon;
  final bool isDestructive;

  const _MacroConfig({
    required this.label,
    required this.icon,
    this.isDestructive = false,
  });
}

class _TactileMacroButton extends StatefulWidget {
  final _MacroConfig config;
  final bool isPending;
  final VoidCallback onPressed;

  const _TactileMacroButton({
    required this.config,
    required this.isPending,
    required this.onPressed,
  });

  @override
  State<_TactileMacroButton> createState() => _TactileMacroButtonState();
}

class _TactileMacroButtonState extends State<_TactileMacroButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    setState(() => _isPressed = true);
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
    widget.onPressed();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDestructive = widget.config.isDestructive;
    final baseBgColor = isDestructive
        ? AppTheme.statusRed.withValues(alpha: 0.12)
        : AppTheme.surfaceInverse;
    final pressedBgColor = isDestructive
        ? AppTheme.statusRed.withValues(alpha: 0.25)
        : const Color(0xFF222320);
    final borderColor = isDestructive
        ? AppTheme.statusRed.withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.08);
    final fgColor = isDestructive ? AppTheme.statusRed : AppTheme.onInverse;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: widget.isPending ? 0.7 : 1.0,
        child: Container(
          key: Key('macro_pill_${widget.config.label}'),
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _isPressed ? pressedBgColor : baseBgColor,
            borderRadius: AppTheme.pillRadius,
            border: Border.all(
              color: borderColor,
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.config.icon, size: 15, color: fgColor),
              const SizedBox(width: 8),
              Text(
                widget.config.label,
                style: AppTheme.labelMd.copyWith(
                  color: fgColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
