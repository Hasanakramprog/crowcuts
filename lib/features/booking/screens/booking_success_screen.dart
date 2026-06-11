import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_extension.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/router/app_router.dart';

/// Booking Success Screen — Full-screen celebration
class BookingSuccessScreen extends StatefulWidget {
  const BookingSuccessScreen({super.key});

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _scissorsController;
  late AnimationController _glowController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _scissorsAnimation;
  late Animation<double> _glowRadius;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();

    // Card spring-in
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Scissors snip
    _scissorsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scissorsAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -0.3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.3, end: 0.3), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _scissorsController, curve: Curves.easeInOut),
    );

    // Gold glow pulse
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowRadius = Tween<double>(begin: 60, end: 140).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Confetti
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    // Sequence
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _scissorsController.forward();
        _confettiController.play();
      }
    });

    // Auto-dismiss
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) _navigateHome();
    });
  }

  void _navigateHome() {
    context.go(AppRoutes.customerHome);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _scissorsController.dispose();
    _glowController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Animated radial gold glow
          AnimatedBuilder(
            animation: _glowRadius,
            builder: (context, _) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _SuccessGlowPainter(radius: _glowRadius.value),
              );
            },
          ),

          // Top confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                AppColors.goldPrimary,
                AppColors.goldLight,
                Colors.white,
                AppColors.successGreen,
                Color(0xFF5B8DEF),
              ],
              numberOfParticles: 60,
              maxBlastForce: 25,
              minBlastForce: 8,
              gravity: 0.25,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
            ),
          ),

          // Left side confetti
          Align(
            alignment: Alignment.centerLeft,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 0,
              shouldLoop: false,
              colors: const [
                AppColors.goldPrimary,
                AppColors.goldLight,
                Colors.white,
              ],
              numberOfParticles: 15,
              gravity: 0.3,
              emissionFrequency: 0.03,
            ),
          ),

          // Right side confetti
          Align(
            alignment: Alignment.centerRight,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: math.pi,
              shouldLoop: false,
              colors: const [
                AppColors.goldPrimary,
                AppColors.goldLight,
                Colors.white,
              ],
              numberOfParticles: 15,
              gravity: 0.3,
              emissionFrequency: 0.03,
            ),
          ),

          // Success card
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: const EdgeInsets.all(28),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: context.colors.borderGold,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.goldShadow,
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated scissors
                  AnimatedBuilder(
                    animation: _scissorsAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _scissorsAnimation.value,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.goldPrimary.withAlpha(50),
                            AppColors.goldDim,
                          ],
                        ),
                        border: Border.all(
                          color: AppColors.goldPrimary.withAlpha(100),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.content_cut_rounded,
                        size: 42,
                        color: AppColors.goldPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Checkmark badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.successGreen.withAlpha(80),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 16, color: AppColors.successGreen),
                        const SizedBox(width: 6),
                        Text(
                          'BOOKING CONFIRMED',
                          style: AppTypography.label.copyWith(
                            color: AppColors.successGreen,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: 400.ms).fadeIn(duration: 400.ms).scale(
                        begin: const Offset(0.7, 0.7),
                        end: const Offset(1.0, 1.0),
                        curve: Curves.elasticOut,
                      ),

                  const SizedBox(height: 16),

                  Text(
                    'You\'re All Set!',
                    style: AppTypography.display.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                    ),
                    textAlign: TextAlign.center,
                  ).animate(delay: 500.ms).fadeIn(duration: 400.ms),

                  const SizedBox(height: 12),

                  Text(
                    'Your appointment has been booked successfully.\nWe look forward to seeing you!',
                    style: AppTypography.body.copyWith(
                      color: context.colors.textMuted,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ).animate(delay: 600.ms).fadeIn(duration: 400.ms),

                  const SizedBox(height: 8),

                  Text(
                    '✓  Check your profile for appointment details',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.goldLight,
                      fontSize: 12,
                    ),
                  ).animate(delay: 700.ms).fadeIn(duration: 400.ms),

                  const SizedBox(height: 28),

                  AppButton(
                    label: 'Back to Home',
                    onPressed: _navigateHome,
                    width: double.infinity,
                  ).animate(delay: 800.ms).fadeIn(duration: 400.ms).slideY(
                        begin: 0.3,
                        end: 0,
                        curve: Curves.easeOutCubic,
                      ),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () => context.go(AppRoutes.bookingHistory),
                    child: Text(
                      'View Booking Details',
                      style: AppTypography.caption.copyWith(
                        color: context.colors.textMuted,
                      ),
                    ),
                  ).animate(delay: 900.ms).fadeIn(duration: 400.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints a gold radial glow in the center
class _SuccessGlowPainter extends CustomPainter {
  final double radius;

  _SuccessGlowPainter({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.goldPrimary.withAlpha(50),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_SuccessGlowPainter old) => old.radius != radius;
}
