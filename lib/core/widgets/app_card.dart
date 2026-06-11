import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_colors_extension.dart';
import '../../core/theme/app_radius.dart';

/// Crown Cuts — Standard Card Container
///
/// Dark mode: surface color with subtle gold border.
/// Light mode: white card with soft drop shadow (no hard border).
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = context.isDark;

    final decoration = BoxDecoration(
      color: color ?? c.surface,
      borderRadius: AppRadius.cardBorder,
      border: border ??
          (isDark
              ? Border.all(color: c.borderDefault, width: 0.5)
              : null),
      boxShadow: isDark ? [] : c.cardShadow,
    );

    final card = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: decoration,
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: AppRadius.cardBorder,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.cardBorder,
          splashColor: AppColors.goldDim,
          highlightColor: AppColors.goldDim.withAlpha(40),
          child: card,
        ),
      );
    }

    return card;
  }
}

/// Gold-accented card with a left border stripe.
class AppAccentCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const AppAccentCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadius.cardBorder,
        border: Border(
          left: const BorderSide(color: AppColors.goldPrimary, width: 3),
          top: BorderSide(color: c.borderDefault, width: 0.5),
          right: BorderSide(color: c.borderDefault, width: 0.5),
          bottom: BorderSide(color: c.borderDefault, width: 0.5),
        ),
        boxShadow: context.isDark ? [] : c.cardShadow,
      ),
      child: child,
    );
  }
}
