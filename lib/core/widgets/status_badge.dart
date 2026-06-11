import 'package:flutter/material.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';

/// Crown Cuts — Status Badge (e.g. "Confirmed", "Completed", "Cancelled")
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool isAnimated;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.isAnimated = true,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: color.withAlpha(28),
      borderRadius: AppRadius.badgeBorder,
      border: Border.all(color: color.withAlpha(90), width: 0.8),
    );

    final child = Text(
      label.toUpperCase(),
      style: AppTypography.label.copyWith(
        color: color,
        letterSpacing: 0.8,
        fontSize: 10,
      ),
    );

    if (isAnimated) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: decoration,
        child: child,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: decoration,
      child: child,
    );
  }
}

/// Availability dot indicator with glow effect
class AvailabilityDot extends StatelessWidget {
  final Color color;
  final double size;

  const AvailabilityDot({
    super.key,
    required this.color,
    this.size = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(110),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

/// A thin horizontal gold gradient divider for premium section separators
class GoldDivider extends StatelessWidget {
  final double height;
  final EdgeInsets? margin;

  const GoldDivider({super.key, this.height = 1, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Color(0xFFC9A84C),
            Color(0xFFE8B84B),
            Color(0xFFC9A84C),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
