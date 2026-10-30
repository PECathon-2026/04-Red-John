import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Modern Light 5-item bottom navigation bar.
/// Styled with a comfortable 88px height, rounded top architectural container,
/// subtle elevation, active dot indicator, and vibrant accent states.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const List<(IconData, IconData, String)> _items = [
    (Icons.grid_view_outlined, Icons.grid_view_rounded, 'HOME'),
    (Icons.folder_outlined, Icons.folder_rounded, 'PROJECTS'),
    (Icons.terminal_outlined, Icons.terminal_rounded, 'TERMINAL'),
    (Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'ARTIFACTS'),
    (Icons.tune_outlined, Icons.tune_rounded, 'SETTINGS'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: T.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: T.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (i) {
            final active = currentIndex == i;
            final item = _items[i];

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onTap(i);
                },
                child: SizedBox(
                  height: 64,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Active indicator dot
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 5),
                        decoration: BoxDecoration(
                          color: active ? T.accent : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Icon(
                        active ? item.$2 : item.$1,
                        size: 24,
                        color: active ? T.accent : T.onSurfaceMuted,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.$3,
                        style: T.labelUpXs.copyWith(
                          fontSize: 9,
                          letterSpacing: 0.8,
                          color: active ? T.accent : T.onSurfaceVar,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
