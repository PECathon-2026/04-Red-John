import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Tactile Macro Deck providing 4 immediate system operations:
/// "Deploy", "Run Tests", "Restart Docker", and "Kill All".
class MacroDeck extends StatelessWidget {
  final void Function(String action) onActionTriggered;

  const MacroDeck({super.key, required this.onActionTriggered});

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
              onPressed: () => onActionTriggered(config.label),
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
  final VoidCallback onPressed;

  const _TactileMacroButton({required this.config, required this.onPressed});

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
        : AppTheme.darkPill;
    final pressedBgColor = isDestructive
        ? AppTheme.statusRed.withValues(alpha: 0.25)
        : const Color(0xFF2C2C32);
    final borderColor = isDestructive
        ? AppTheme.statusRed.withValues(alpha: 0.6)
        : AppTheme.borderSubtle;
    final fgColor = isDestructive ? AppTheme.statusRed : Colors.white;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        curve: Curves.easeInOut,
        transform: Matrix4.translationValues(0, _isPressed ? 1.5 : 0, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: _isPressed ? pressedBgColor : baseBgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: isDestructive ? 1.2 : 1.0,
          ),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: isDestructive
                        ? AppTheme.statusRed.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.14),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.config.icon, size: 14, color: fgColor),
            const SizedBox(width: 6),
            Text(
              widget.config.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: fgColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
