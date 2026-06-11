import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_colors_extension.dart';

/// Crown Cuts — Step Progress Bar for Booking Flow
class StepProgress extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepProgress({
    super.key,
    required this.currentStep,
    this.totalSteps = 5,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: List.generate(totalSteps * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector line
          final stepIndex = (index - 1) ~/ 2;
          final isCompleted = currentStep > stepIndex + 1;
          return Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: isCompleted
                    ? const LinearGradient(
                        colors: [Color(0xFFC9A84C), Color(0xFFE8B84B)],
                      )
                    : null,
                color: isCompleted ? null : c.surface2,
              ),
            ),
          );
        }

        // Step dot
        final stepNumber = (index ~/ 2) + 1;
        final isActive = currentStep >= stepNumber;
        final isCurrent = currentStep == stepNumber;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          width: isCurrent ? 34 : 28,
          height: isCurrent ? 34 : 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isActive
                ? const LinearGradient(
                    colors: [Color(0xFFC9A84C), Color(0xFFE8B84B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isActive ? null : c.surface2,
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: AppColors.goldPrimary.withAlpha(80),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: Center(
            child: isActive && !isCurrent
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    '$stepNumber',
                    style: TextStyle(
                      color: isActive ? Colors.white : c.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: isCurrent ? 14 : 12,
                    ),
                  ),
          ),
        );
      }),
    );
  }
}
