import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_colors_extension.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';

/// Crown Cuts — Primary Action Button
///
/// Uses a gold gradient fill in both themes with a branded glow shadow.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final double? width;
  final EdgeInsets? padding;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.width,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDisabled = onPressed == null && !isLoading;

    if (isOutlined) {
      return SizedBox(
        width: width,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          child: _buildLabel(context, isLoading: isLoading),
        ),
      );
    }

    // Primary: gradient button with glow shadow
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.buttonBorder,
          gradient: isDisabled
              ? null
              : const LinearGradient(
                  colors: [Color(0xFFC9A84C), Color(0xFFE8B84B)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: isDisabled ? c.surface2 : null,
          boxShadow: isDisabled ? [] : c.buttonShadow,
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor:
                isDisabled ? c.textMuted : (context.isDark ? c.background : Colors.white),
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: c.textMuted,
            elevation: 0,
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.buttonBorder,
            ),
          ),
          child: _buildLabel(context, isLoading: isLoading),
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, {required bool isLoading}) {
    if (isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            context.isDark
                ? context.colors.background
                : Colors.white,
          ),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        Text(label, style: AppTypography.button),
      ],
    );
  }
}

/// Crown Cuts — Chip-style toggle button
class AppChipButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isSelected;

  const AppChipButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFC9A84C), Color(0xFFE8B84B)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isSelected ? null : c.surface2,
          borderRadius: AppRadius.slotBorder,
          border: Border.all(
            color: isSelected ? Colors.transparent : c.borderDefault,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodyBold.copyWith(
            color: isSelected
                ? (context.isDark ? c.background : Colors.white)
                : c.textPrimary,
          ),
        ),
      ),
    );
  }
}
