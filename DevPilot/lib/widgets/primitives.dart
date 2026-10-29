import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Hairline border box (the universal editorial card).
class HBox extends StatelessWidget {
  final Widget child;
  final Color bg;
  final EdgeInsets padding;
  final double? width;
  final double? height;

  const HBox({
    super.key,
    required this.child,
    this.bg = T.background,
    this.padding = const EdgeInsets.all(T.lg),
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: T.border, width: 1),
        ),
        padding: padding,
        child: child,
      );
}

/// 2-column hairline lattice grid.
class HairlineGrid extends StatelessWidget {
  final List<Widget> cells;
  final int crossAxisCount;

  const HairlineGrid({
    super.key,
    required this.cells,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final cellWidth =
            (totalWidth - (crossAxisCount - 1)) / crossAxisCount;

        return Container(
          decoration: BoxDecoration(
            color: T.border,
            border: Border.all(color: T.border, width: 1),
          ),
          child: Wrap(
            spacing: 1,
            runSpacing: 1,
            children: cells.map((cell) {
              return SizedBox(
                width: cellWidth,
                child: ColoredBox(
                  color: T.background,
                  child: cell,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

/// Badge pill (solid fill, high contrast text, zero radius).
class BadgePill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color textColor;
  final EdgeInsets padding;

  const BadgePill(
    this.label, {
    super.key,
    this.bg = T.onSurface,
    this.textColor = T.background,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(color: bg, borderRadius: T.zero),
        child: Text(
          label,
          style: T.labelUpXs.copyWith(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

/// 2px tall progress indicator with zero radius.
class HairlineBar extends StatelessWidget {
  final double value; // 0.0 – 1.0
  final Color? color;
  final Color? backgroundColor;

  const HairlineBar(
    this.value, {
    super.key,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return SizedBox(
      height: 2,
      child: LinearProgressIndicator(
        value: clamped,
        backgroundColor: backgroundColor ?? T.surfaceMuted,
        valueColor: AlwaysStoppedAnimation(color ?? T.onSurface),
        borderRadius: T.zero,
      ),
    );
  }
}

/// Section header row with uppercase tracked kicker and optional trailing widget.
class SectionHeader extends StatelessWidget {
  final String label;
  final Widget? trailing;

  const SectionHeader(this.label, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: T.labelUpMd),
          ?trailing,
        ],
      );
}

/// Primary action button (inverted high contrast, zero radius).
class ButtonPrimary extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Widget? icon;

  const ButtonPrimary({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: T.onSurface,
            borderRadius: T.zero,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: T.labelUpSm.copyWith(
                  color: T.background,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
}

/// Secondary action button (hairline border, ghost).
class ButtonSecondary extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Widget? icon;

  const ButtonSecondary({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: T.background,
            border: Border.all(color: T.border),
            borderRadius: T.zero,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: T.labelUpSm.copyWith(
                  color: T.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
}
