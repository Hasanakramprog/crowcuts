import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_extension.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/barber_provider.dart';
import '../../../data/repositories/firebase_auth_repository.dart';
import '../../../data/repositories/firebase_firestore_repository.dart';
import '../../../data/repositories/firebase_storage_repository.dart';
import '../../../data/models/barber_model.dart';
import '../../../data/models/work_schedule.dart';

/// Barber Settings Screen — Profile, Avatar & Password Management
class BarberSettingsScreen extends ConsumerStatefulWidget {
  const BarberSettingsScreen({super.key});

  @override
  ConsumerState<BarberSettingsScreen> createState() =>
      _BarberSettingsScreenState();
}

class _BarberSettingsScreenState extends ConsumerState<BarberSettingsScreen> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  bool _isSavingProfile = false;
  bool _isUploadingAvatar = false;
  bool _isChangingPassword = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  File? _localAvatarFile; // locally picked image before upload

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;

    final file = File(picked.path);
    setState(() {
      _localAvatarFile = file;
      _isUploadingAvatar = true;
    });

    try {
      final user = ref.read(authProvider).user;
      if (user == null) return;

      final barberId = user.barberId;
      debugPrint('🔑 Upload avatar — uid: ${user.id}, barberId: $barberId');
      if (barberId == null || barberId.isEmpty) {
        debugPrint('❌ barberId is null or empty — cannot update barber record');
        return;
      }

      // Upload to Firebase Storage
      final storageRepo = ref.read(firebaseStorageRepositoryProvider);
      final downloadUrl = await storageRepo.uploadBarberAvatar(
        barberId: barberId,
        imageFile: file,
      );
      debugPrint('✅ Uploaded to Storage: $downloadUrl');

      // Update the barber document in Firestore
      final firestoreRepo = ref.read(firebaseFirestoreRepositoryProvider);
      debugPrint('📝 Updating barbers/$barberId avatarUrl...');
      await firestoreRepo.updateBarberAvatarUrl(barberId, downloadUrl);
      debugPrint('✅ Firestore updated!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photo: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() => _isSavingProfile = true);

    try {
      final repo = ref.read(firebaseAuthRepositoryProvider);
      final newName = _nameController.text.trim();
      await repo.updateCurrentUserProfile(
        name: newName,
        phone: _phoneController.text.trim(),
      );

      // Sync name to the barbers collection
      final user = ref.read(authProvider).user;
      final barberId = user?.barberId;
      if (barberId != null && barberId.isNotEmpty) {
        final firestoreRepo = ref.read(firebaseFirestoreRepositoryProvider);
        final barber = await firestoreRepo.getBarber(barberId);
        if (barber != null && barber.id != 'unknown') {
          await firestoreRepo.setBarber(barber.copyWith(name: newName));
        } else {
          final newBarber = BarberModel(
            id: barberId,
            name: newName,
            schedule: WorkSchedule(
              weeklySchedule: List.generate(7, (i) {
                return DaySchedule(
                  weekday: i + 1,
                  isWorking: i < 5,
                  startTime: const TimeOfDay(hour: 9, minute: 0),
                  endTime: const TimeOfDay(hour: 18, minute: 0),
                  slotIntervalMinutes: 30,
                );
              }),
              daysOff: const [],
            ),
          );
          await firestoreRepo.setBarber(newBarber);
        }
      }

      await ref.read(authProvider.notifier).initialize();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _isChangingPassword = true);

    try {
      final repo = ref.read(firebaseAuthRepositoryProvider);
      await repo.updatePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Failed to change password';
        if (e.toString().contains('wrong-password')) {
          msg = 'Current password is incorrect';
        } else if (e.toString().contains('weak-password')) {
          msg = 'New password is too weak';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final c = context.colors;

    // Get the current barber's avatarUrl from the barbers collection
    final barberId = user?.barberId ?? '';
    final barber = barberId.isNotEmpty
        ? ref.watch(barberProvider(barberId))
        : null;
    final currentAvatarUrl = barber?.avatarUrl ?? '';

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar Section ──────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.goldPrimary,
                            width: 2.5,
                          ),
                        ),
                        child: ClipOval(
                          child: _isUploadingAvatar
                              ? Container(
                                  color: c.surface2,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.goldPrimary,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : _localAvatarFile != null
                              ? Image.file(_localAvatarFile!, fit: BoxFit.cover)
                              : currentAvatarUrl.isNotEmpty
                              ? Image.network(
                                  currentAvatarUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _DefaultAvatar(name: user?.name ?? 'B'),
                                )
                              : _DefaultAvatar(name: user?.name ?? 'B'),
                        ),
                      ),
                      // Camera button
                      GestureDetector(
                        onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.goldPrimary,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 18,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the camera to change photo',
                    style: AppTypography.caption.copyWith(
                      color: c.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Profile Section ─────────────────────────────────────────
            Text(
              'Profile Information',
              style: AppTypography.heading1.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: 12),
            Form(
              key: _profileFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline, size: 20),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Name is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: user?.email ?? '',
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined, size: 20),
                      helperText: 'Email cannot be changed',
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    label: 'Save Profile',
                    isLoading: _isSavingProfile,
                    onPressed: _saveProfile,
                    width: double.infinity,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 32),

            // ── Password Section ────────────────────────────────────────
            Text(
              'Change Password',
              style: AppTypography.heading1.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: 12),
            Form(
              key: _passwordFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _currentPasswordController,
                    obscureText: _obscureCurrentPassword,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCurrentPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(
                          () => _obscureCurrentPassword =
                              !_obscureCurrentPassword,
                        ),
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? 'Current password is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: _obscureNewPassword,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(
                          () => _obscureNewPassword = !_obscureNewPassword,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty)
                        return 'New password is required';
                      if (v.length < 6)
                        return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty)
                        return 'Please confirm password';
                      if (v != _newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    label: 'Change Password',
                    isLoading: _isChangingPassword,
                    onPressed: _changePassword,
                    width: double.infinity,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/// Default avatar widget showing initials when no image is set
class _DefaultAvatar extends StatelessWidget {
  final String name;
  const _DefaultAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'B';
    return Container(
      color: AppColors.goldDim,
      child: Center(
        child: Text(
          initial,
          style: AppTypography.heading1.copyWith(
            color: AppColors.goldPrimary,
            fontSize: 40,
          ),
        ),
      ),
    );
  }
}
