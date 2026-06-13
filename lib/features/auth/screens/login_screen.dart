import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_extension.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/router/app_router.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/repositories/firebase_auth_repository.dart';
import '../../../data/models/models.dart';

/// Login Screen — Email + Password + Google Sign-In
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isGoogleLoading = false;
  String? _googleError;
  late AnimationController _scissorsController;
  late Animation<double> _scissorsRotation;

  @override
  void initState() {
    super.initState();
    _scissorsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scissorsRotation = Tween<double>(begin: -0.3, end: 0.3).animate(
      CurvedAnimation(parent: _scissorsController, curve: Curves.easeInOut),
    );
    // Subtle idle animation
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _scissorsController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _scissorsController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (success && mounted) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        switch (user.role) {
          case UserRole.admin:
            context.go(AppRoutes.adminHome);
            break;
          case UserRole.barber:
            context.go(AppRoutes.barberDashboard);
            break;
          case UserRole.customer:
            context.go(AppRoutes.customerHome);
            break;
        }
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _googleError = null;
    });

    try {
      final authRepo = ref.read(firebaseAuthRepositoryProvider);
      final user = await authRepo.signInWithGoogle();

      if (mounted) {
        // Check if user has phone number
        if (!user.hasPhone) {
          // Navigate to phone input screen
          context.go(AppRoutes.phoneInput);
        } else {
          // Navigate to customer home
          context.go(AppRoutes.customerHome);
        }
      }
    } catch (e) {
      // Guard against setState after dispose (widget navigated away during async operation)
      if (!mounted) return;
      setState(() {
        _googleError = e.toString().contains('cancelled')
            ? 'Google sign-in was cancelled'
            : 'Failed to sign in with Google. Please try again.';
        _isGoogleLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.background,
      body: Stack(
        children: [
          // Subtle gradient background
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.goldPrimary.withAlpha(20),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.goldPrimary.withAlpha(12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),

                    // Animated Logo
                    Center(
                      child: AnimatedBuilder(
                        animation: _scissorsRotation,
                        builder: (context, _) {
                          return Transform.rotate(
                            angle: _scissorsRotation.value,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: c.surface,
                                border: Border.all(
                                  color: AppColors.goldPrimary.withAlpha(80),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.goldShadow,
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.content_cut,
                                size: 36,
                                color: AppColors.goldPrimary,
                              ),
                            ),
                          );
                        },
                      ),
                    ).animate().scale(
                          begin: const Offset(0.5, 0.5),
                          end: const Offset(1.0, 1.0),
                          curve: Curves.elasticOut,
                          duration: 900.ms,
                        ),

                    const SizedBox(height: 20),

                    Text(
                      'Crown Cuts',
                      style: AppTypography.display.copyWith(
                        color: AppColors.goldPrimary,
                        fontSize: 26,
                        letterSpacing: 3,
                      ),
                      textAlign: TextAlign.center,
                    ).animate(delay: 200.ms).fadeIn(duration: 500.ms),

                    const SizedBox(height: 6),

                    Text(
                      'Sign in to your account',
                      style: AppTypography.caption.copyWith(
                        color: c.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ).animate(delay: 300.ms).fadeIn(duration: 500.ms),

                    const SizedBox(height: 32),

                    // Google Sign-In Button
                    OutlinedButton.icon(
                      onPressed: _isGoogleLoading ? null : _loginWithGoogle,
                      icon: _isGoogleLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.goldPrimary,
                                ),
                              ),
                            )
                          : Image.network(
                              'https://www.google.com/favicon.ico',
                              width: 20,
                              height: 20,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                Icons.g_mobiledata,
                                size: 24,
                                color: AppColors.goldPrimary,
                              ),
                            ),
                      label: Text(
                        _isGoogleLoading
                            ? 'Signing in...'
                            : 'Continue with Google',
                        style: AppTypography.bodyBold.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        backgroundColor: c.surface,
                        side: BorderSide(color: c.borderDefault),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.inputBorder,
                        ),
                      ),
                    ).animate(delay: 400.ms).fadeIn(duration: 400.ms).slideY(
                          begin: 0.1,
                          end: 0,
                          curve: Curves.easeOutCubic,
                        ),

                    const SizedBox(height: 8),

                    // Customer-only note
                    Center(
                      child: Text(
                        'For customers only • Admins/Barbers use email',
                        style: AppTypography.caption.copyWith(
                          color: c.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ).animate(delay: 450.ms).fadeIn(duration: 400.ms),

                    // Google sign-in error message
                    if (_googleError != null) ...[ 
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.errorRed.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.errorRed.withAlpha(60),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 16,
                              color: AppColors.errorRed,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _googleError!,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.errorRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(color: c.borderDefault),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or sign in with email',
                            style: AppTypography.caption.copyWith(
                              color: c.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: c.borderDefault),
                        ),
                      ],
                    ).animate(delay: 500.ms).fadeIn(duration: 400.ms),

                    const SizedBox(height: 20),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email is required';
                        }
                        return null;
                      },
                    ).animate(delay: 550.ms).fadeIn(duration: 400.ms).slideX(
                          begin: -0.1,
                          end: 0,
                          curve: Curves.easeOutCubic,
                        ),

                    const SizedBox(height: 14),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: c.textMuted,
                          ),
                          onPressed: () {
                            setState(
                                () => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Password is required';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _login(),
                    ).animate(delay: 600.ms).fadeIn(duration: 400.ms).slideX(
                          begin: -0.1,
                          end: 0,
                          curve: Curves.easeOutCubic,
                        ),

                    // Error message
                    if (authState.error != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.errorRed.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.errorRed.withAlpha(60),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 16,
                              color: AppColors.errorRed,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                authState.error!,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.errorRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    AppButton(
                      label: 'Sign In',
                      isLoading: authState.isLoading,
                      onPressed: _login,
                      width: double.infinity,
                    ).animate(delay: 650.ms).fadeIn(duration: 400.ms),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: AppTypography.caption.copyWith(
                            color: c.textMuted,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go(AppRoutes.register),
                          child: const Text('Create One'),
                        ),
                      ],
                    ).animate(delay: 700.ms).fadeIn(duration: 400.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

