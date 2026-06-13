import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_extension.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/router/app_router.dart';
import '../../../data/repositories/firebase_auth_repository.dart';
import '../../../data/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

/// Phone number input screen for Google sign-in users.
/// 
/// This screen is shown after Google authentication for new users
/// who haven't provided a phone number yet. Phone format: +961 XX XXX XXX (Lebanon)
class PhoneNumberInputScreen extends ConsumerStatefulWidget {
  const PhoneNumberInputScreen({super.key});

  @override
  ConsumerState<PhoneNumberInputScreen> createState() => _PhoneNumberInputScreenState();
}

class _PhoneNumberInputScreenState extends ConsumerState<PhoneNumberInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  /// Validate Lebanon phone number format
  /// Expected format: +961 XX XXX XXX (8 digits after country code)
  /// Valid prefixes: 3, 70, 71, 76, 78, 79, 81
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove spaces and any non-digit characters except +
    final cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');

    // Check if it starts with +961
    if (!cleaned.startsWith('+961')) {
      return 'Phone must start with +961 (Lebanon)';
    }

    // Extract digits after +961
    final digits = cleaned.substring(4);

    // Must be exactly 8 digits
    if (digits.length != 8) {
      return 'Phone must have 8 digits after +961';
    }

    // Check valid prefixes for Lebanon mobile numbers
    final validPrefixes = ['3', '70', '71', '76', '78', '79', '81'];
    bool hasValidPrefix = false;

    for (final prefix in validPrefixes) {
      if (digits.startsWith(prefix)) {
        hasValidPrefix = true;
        break;
      }
    }

    if (!hasValidPrefix) {
      return 'Invalid Lebanon mobile number';
    }

    return null;
  }

  /// Format phone number as user types
  String _formatPhone(String value) {
    // Remove all non-digit characters except +
    final cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (cleaned.isEmpty) return '';
    
    // Always start with +961
    if (!cleaned.startsWith('+961')) {
      return '+961 ';
    }
    
    // Format: +961 XX XXX XXX
    final digits = cleaned.substring(4);
    if (digits.isEmpty) return '+961 ';
    
    String formatted = '+961 ';
    if (digits.length <= 2) {
      formatted += digits;
    } else if (digits.length <= 5) {
      formatted += digits.substring(0, 2) + ' ' + digits.substring(2);
    } else {
      formatted += digits.substring(0, 2) + ' ' + 
                   digits.substring(2, 5) + ' ' + 
                   digits.substring(5, digits.length > 8 ? 8 : digits.length);
    }
    
    return formatted;
  }

  Future<void> _submitPhone() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = auth.FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Clean phone number for storage (digits and + only)
      final cleanedPhone = _phoneController.text.replaceAll(RegExp(r'[^\d+]'), '');

      // Update user's phone number in Firestore
      await ref.read(firebaseAuthRepositoryProvider).updatePhoneNumber(
        user.uid,
        cleanedPhone,
      );

      // Refresh auth state so the router picks up the updated phone number
      await ref.read(authProvider.notifier).initialize();

      if (mounted) {
        // Navigate to customer home (router redirect won't loop since phone is now set)
        context.go(AppRoutes.customerHome);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save phone number. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = auth.FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Welcome';

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Welcome message with user's profile picture
                Center(
                  child: Column(
                    children: [
                      // Profile picture
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.goldDim,
                        backgroundImage: user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : null,
                        child: user?.photoURL == null
                            ? Icon(
                                Icons.person,
                                size: 48,
                                color: AppColors.goldPrimary,
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Welcome text
                      Text(
                        'Welcome, $displayName!',
                        style: AppTypography.heading1.copyWith(
                          color: AppColors.goldPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      Text(
                        'To complete your profile, please\nadd your phone number',
                        style: AppTypography.body.copyWith(
                          color: context.colors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Phone number input
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d+\s]')),
                    LengthLimitingTextInputFormatter(17), // +961 XX XXX XXX = 16 chars + 1
                  ],
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+961 XX XXX XXX',
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    helperText: 'Lebanon mobile number format',
                    helperStyle: AppTypography.caption.copyWith(
                      color: context.colors.textMuted,
                    ),
                  ),
                  validator: _validatePhone,
                  onChanged: (value) {
                    // Auto-format as user types
                    final formatted = _formatPhone(value);
                    if (formatted != value) {
                      _phoneController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    }
                  },
                  onFieldSubmitted: (_) => _submitPhone(),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withOpacity(0.1),
                      borderRadius: AppRadius.inputBorder,
                      border: Border.all(
                        color: AppColors.errorRed.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppColors.errorRed,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
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

                // Continue button
                AppButton(
                  label: 'Continue',
                  onPressed: _submitPhone,
                  isLoading: _isLoading,
                  width: double.infinity,
                ),

                const SizedBox(height: 16),

                // Info box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.colors.surface2,
                    borderRadius: AppRadius.cardBorder,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: AppColors.goldPrimary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your phone number will be used to contact you about your bookings and appointments.',
                          style: AppTypography.caption.copyWith(
                            color: context.colors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
