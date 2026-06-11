import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_extension.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/providers/auth_provider.dart';

/// Splash Screen — Premium animated logo + auth check
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _ringController;
  late AnimationController _logoController;
  late AnimationController _shimmerController;

  late Animation<double> _glowRadius;
  late Animation<double> _glowOpacity;
  late Animation<double> _ringRotation;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _shimmerProgress;

  @override
  void initState() {
    super.initState();

    // Glow pulse
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowRadius = Tween<double>(begin: 80, end: 160).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _glowOpacity = Tween<double>(begin: 0.15, end: 0.35).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Ring rotation
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _ringRotation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.linear),
    );

    // Logo spring in
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Shimmer loading bar
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _shimmerProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Sequence
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _logoController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _shimmerController.forward();
    });

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    await ref.read(authProvider.notifier).initialize();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _ringController.dispose();
    _logoController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      body: Stack(
        children: [
          // Animated radial gold glow background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _RadialGlowPainter(
                    radius: _glowRadius.value,
                    opacity: _glowOpacity.value,
                  ),
                );
              },
            ),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo stack — ring + icon
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Rotating gradient ring
                      AnimatedBuilder(
                        animation: _ringRotation,
                        builder: (context, _) {
                          return Transform.rotate(
                            angle: _ringRotation.value,
                            child: CustomPaint(
                              size: const Size(130, 130),
                              painter: _GradientRingPainter(),
                            ),
                          );
                        },
                      ),

                      // Logo circle
                      ScaleTransition(
                        scale: _logoScale,
                        child: FadeTransition(
                          opacity: _logoOpacity,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c.surface,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.goldShadow,
                                  blurRadius: 24,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.content_cut,
                              size: 44,
                              color: AppColors.goldPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // App name — staggered animate
                Text(
                  'CROWN CUTS',
                  style: AppTypography.display.copyWith(
                    color: AppColors.goldPrimary,
                    letterSpacing: 8,
                    fontSize: 30,
                  ),
                )
                    .animate(delay: 500.ms)
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),

                const SizedBox(height: 8),

                Text(
                  'PREMIUM BARBER EXPERIENCE',
                  style: AppTypography.caption.copyWith(
                    color: c.textMuted,
                    letterSpacing: 3,
                    fontSize: 11,
                  ),
                )
                    .animate(delay: 700.ms)
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),

                const SizedBox(height: 48),

                // Shimmer loading bar
                AnimatedBuilder(
                  animation: _shimmerProgress,
                  builder: (context, _) {
                    return Container(
                      width: 160,
                      height: 2,
                      decoration: BoxDecoration(
                        color: c.surface2,
                        borderRadius: BorderRadius.circular(1),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _shimmerProgress.value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.goldPrimary,
                                AppColors.goldLight,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Version tag
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'v1.0.0',
              style: AppTypography.caption.copyWith(
                color: c.textMuted.withAlpha(80),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ).animate(delay: 900.ms).fadeIn(duration: 600.ms),
          ),
        ],
      ),
    );
  }
}

/// Paints a radial gold glow behind the logo
class _RadialGlowPainter extends CustomPainter {
  final double radius;
  final double opacity;

  _RadialGlowPainter({required this.radius, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 60);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.goldPrimary.withAlpha((opacity * 255).round()),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_RadialGlowPainter old) =>
      old.radius != radius || old.opacity != opacity;
}

/// Paints a rotating dashed/gradient ring
class _GradientRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..shader = SweepGradient(
        colors: [
          AppColors.goldPrimary,
          AppColors.goldLight,
          Colors.transparent,
          AppColors.goldPrimary.withAlpha(80),
          AppColors.goldPrimary,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_GradientRingPainter old) => false;
}
