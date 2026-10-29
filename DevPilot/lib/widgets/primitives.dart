import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Clean card container with subtle border and optional rounded corners.
class HBox extends StatelessWidget {
  final Widget child;
  final Color bg;
  final EdgeInsets padding;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? borderColor;

  const HBox({
    super.key,
    required this.child,
    this.bg = T.surface,
    this.padding = const EdgeInsets.all(T.lg),
    this.width,
    this.height,
    this.borderRadius,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: borderColor ?? T.border, width: 1),
          borderRadius: borderRadius ?? T.rMd,
        ),
        padding: padding,
        child: child,
      );
}

/// 2-column hairline lattice grid.
class HairlineGrid extends StatelessWidget {
  final List<Widget> cells;
  final int crossAxisCount;
  final BorderRadius? borderRadius;

  const HairlineGrid({
    super.key,
    required this.cells,
    this.crossAxisCount = 2,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? T.rMd,
      child: LayoutBuilder(
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
                    color: T.surface,
                    child: cell,
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

/// Badge pill with rounded corners and high contrast text.
class BadgePill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color textColor;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;

  const BadgePill(
    this.label, {
    super.key,
    this.bg = T.surfaceMuted,
    this.textColor = T.onSurface,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: borderRadius ?? T.rFull,
        ),
        child: Text(
          label,
          style: T.labelUpXs.copyWith(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

/// Progress indicator with soft rounded ends.
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
      height: 3,
      child: ClipRRect(
        borderRadius: T.rFull,
        child: LinearProgressIndicator(
          value: clamped,
          backgroundColor: backgroundColor ?? T.surfaceMuted,
          valueColor: AlwaysStoppedAnimation(color ?? T.primary),
        ),
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

/// Primary action button (clean, rounded, high contrast).
class ButtonPrimary extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Widget? icon;
  final Color? bg;
  final Color? textColor;
  final BorderRadius? borderRadius;

  const ButtonPrimary({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.bg,
    this.textColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bg ?? T.onSurface,
            borderRadius: borderRadius ?? T.rSm,
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
                  color: textColor ?? T.surface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
}

/// Secondary action button (clean border, rounded, ghost).
class ButtonSecondary extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Widget? icon;
  final Color? bg;
  final Color? textColor;
  final BorderRadius? borderRadius;

  const ButtonSecondary({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.bg,
    this.textColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: bg ?? T.surface,
            border: Border.all(color: T.border),
            borderRadius: borderRadius ?? T.rSm,
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
                  color: textColor ?? T.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
}
