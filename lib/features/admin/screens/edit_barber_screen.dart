import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_extension.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/providers/barber_provider.dart';
import '../../../data/repositories/firebase_auth_repository.dart';
import '../../../data/models/models.dart';
import '../../../core/router/app_router.dart';
import 'package:uuid/uuid.dart';

/// Admin — Add/Edit Barber Screen with full form + service assignment
class EditBarberScreen extends ConsumerStatefulWidget {
  final String? barberId; // null for add, non-null for edit

  const EditBarberScreen({super.key, this.barberId});

  @override
  ConsumerState<EditBarberScreen> createState() => _EditBarberScreenState();
}

class _EditBarberScreenState extends ConsumerState<EditBarberScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _experienceController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  bool _isActive = true;
  bool _isSaving = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  List<String> _selectedServiceIds = [];

  /// Per-service pricing controllers keyed by serviceId.
  final Map<String, TextEditingController> _priceControllers = {};

  /// Per-service duration controllers keyed by serviceId.
  final Map<String, TextEditingController> _durationControllers = {};

  String? _linkedUserId; // Firestore user doc ID for this barber

  @override
  void initState() {
    super.initState();
    final barber = widget.barberId != null
        ? ref.read(barberProvider(widget.barberId!))
        : null;

    _nameController = TextEditingController(text: barber?.name ?? '');
    _phoneController = TextEditingController(text: '');
    _emailController = TextEditingController(text: '');
    _experienceController = TextEditingController(
      text: barber?.experienceYears.toString() ?? '',
    );
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _isActive = barber?.isActive ?? true;
    // Populate selected services + pricing controllers
    _selectedServiceIds =
        barber?.services.map((s) => s.serviceId).toList() ?? [];
    for (final svc in barber?.services ?? []) {
      _priceControllers[svc.serviceId] = TextEditingController(
        text: svc.price.toStringAsFixed(0),
      );
      _durationControllers[svc.serviceId] = TextEditingController(
        text: svc.durationMinutes.toString(),
      );
    }

    // ── Load phone/email from the linked user document ─────────────────
    if (widget.barberId != null) {
      _loadLinkedUser(widget.barberId!);
    }
  }

  Future<void> _loadLinkedUser(String barberId) async {
    final repo = ref.read(firebaseAuthRepositoryProvider);
    final user = await repo.getUserByBarberId(barberId);
    if (user != null && mounted) {
      _linkedUserId = user.id;
      _phoneController.text = user.phone ?? '';
      _emailController.text = user.email;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _experienceController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    for (final c in _priceControllers.values) {
      c.dispose();
    }
    for (final c in _durationControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Build the barber services from selected service IDs with per-barber pricing
      final allServices = ref.read(serviceCatalogProvider);
      final barberServices = _selectedServiceIds.map((id) {
        final svc = allServices.firstWhere((s) => s.id == id);
        return BarberService(
          serviceId: id,
          name: svc.name,
          price: double.tryParse(_priceControllers[id]?.text ?? '') ?? 30.0,
          durationMinutes:
              int.tryParse(_durationControllers[id]?.text ?? '') ?? 30,
        );
      }).toList();

      if (widget.barberId != null) {
        // Editing — update existing barber
        final existing = ref.read(barberProvider(widget.barberId!));
        if (existing != null) {
          await ref
              .read(barbersProvider.notifier)
              .updateBarber(
                existing.copyWith(
                  name: _nameController.text.trim(),
                  experienceYears:
                      int.tryParse(_experienceController.text) ?? 0,
                  isActive: _isActive,
                  services: barberServices,
                ),
              );

          // Sync phone/email back to the linked user document
          if (_linkedUserId != null) {
            final repo = ref.read(firebaseAuthRepositoryProvider);
            final existingUser = await repo.getUserById(_linkedUserId!);
            if (existingUser != null) {
              await repo.updateUser(
                existingUser.copyWith(
                  phone: _phoneController.text.trim(),
                  email: _emailController.text.trim(),
                ),
              );
            }
          }
        }
      } else {
        // Adding — create new barber with authentication
        final uuid = const Uuid();
        final barberId = 'barber-${uuid.v4().substring(0, 8)}';
        
        // 1️⃣ Create barber profile record FIRST (admin is still authenticated)
        final newBarber = BarberModel(
          id: barberId,
          name: _nameController.text.trim(),
          rating: 0.0,
          reviewCount: 0,
          experienceYears: int.tryParse(_experienceController.text) ?? 0,
          isActive: _isActive,
          services: barberServices,
          schedule: WorkSchedule(
            weeklySchedule: List.generate(7, (i) {
              return DaySchedule(
                weekday: i + 1,
                isWorking: i < 5, // Mon-Fri working by default
                startTime: const TimeOfDay(hour: 9, minute: 0),
                endTime: const TimeOfDay(hour: 18, minute: 0),
                slotIntervalMinutes: 30,
              );
            }),
            daysOff: [],
          ),
        );
        await ref.read(barbersProvider.notifier).addBarber(newBarber);
        
        // 2️⃣ THEN create Firebase Auth account + user document
        // (this signs in the new barber, so the admin session is replaced)
        final repo = ref.read(firebaseAuthRepositoryProvider);
        await repo.createBarberUser(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          barberId: barberId,
        );
      }

      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.barberId != null
                  ? 'Barber updated successfully'
                  : 'Barber created successfully with login credentials',
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _toggleService(ServiceModel service) {
    setState(() {
      if (_selectedServiceIds.contains(service.id)) {
        _selectedServiceIds.remove(service.id);
        _priceControllers[service.id]?.dispose();
        _priceControllers.remove(service.id);
        _durationControllers[service.id]?.dispose();
        _durationControllers.remove(service.id);
      } else {
        _selectedServiceIds.add(service.id);
        _priceControllers[service.id] = TextEditingController(text: '30');
        _durationControllers[service.id] = TextEditingController(text: '30');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.barberId != null;
    final allServices = ref.watch(serviceCatalogProvider);
    final activeServices = allServices.where((s) => s.isActive).toList();

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(title: Text(isEditing ? 'Edit Barber' : 'Add Barber')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.goldDim,
                  child: Icon(
                    Icons.person,
                    size: 48,
                    color: AppColors.goldPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter barber name',
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+1 (555) 123-4567',
                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'barber@crowncuts.com',
                  prefixIcon: Icon(Icons.email_outlined, size: 20),
                ),
                validator: (v) {
                  // Email is required for new barbers (auth account creation)
                  if (widget.barberId == null) {
                    if (v == null || v.trim().isEmpty)
                      return 'Email is required';
                    // Basic email validation
                    final emailRegex = RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    );
                    if (!emailRegex.hasMatch(v.trim()))
                      return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _experienceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Years of Experience',
                  hintText: 'e.g. 5',
                  prefixIcon: Icon(Icons.work_outline, size: 20),
                ),
              ),
              const SizedBox(height: 16),

              // Password fields only for new barbers
              if (widget.barberId == null) ...[
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter initial password',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
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
                    labelText: 'Confirm Password',
                    hintText: 'Re-enter password',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty)
                      return 'Please confirm password';
                    if (v != _passwordController.text)
                      return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.goldDim.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.goldDim),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: AppColors.goldPrimary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'The barber can login with this email and password to manage their profile',
                          style: AppTypography.caption.copyWith(
                            color: context.colors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Active toggle
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: context.colors.surface2,
                  borderRadius: AppRadius.inputBorder,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.toggle_on_outlined,
                      size: 20,
                      color: context.colors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text('Active Barber', style: AppTypography.body),
                    const Spacer(),
                    Switch(
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      activeColor: AppColors.goldPrimary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Service Assignment
              Text('Services Offered', style: AppTypography.heading2),
              const SizedBox(height: 4),
              Text(
                'Select which services this barber provides',
                style: AppTypography.caption.copyWith(
                  color: context.colors.textMuted,
                ),
              ),
              const SizedBox(height: 12),

              if (activeServices.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.colors.surface2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: AppColors.warningAmber,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'No services available. Add services first.',
                        style: AppTypography.caption.copyWith(
                          color: context.colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...activeServices.map((service) {
                  final isSelected = _selectedServiceIds.contains(service.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => _toggleService(service),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.goldDim.withAlpha(40)
                              : context.colors.surface2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? context.colors.borderGold
                                : context.colors.borderDefault,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? AppColors.goldPrimary
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.goldPrimary
                                          : context.colors.textMuted,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Icon(
                                          Icons.check,
                                          size: 14,
                                          color: context.colors.background,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    service.name,
                                    style: AppTypography.body.copyWith(
                                      color: isSelected
                                          ? (context.isDark
                                                ? AppColors.goldPrimary
                                                : context.colors.textPrimary)
                                          : context.colors.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Per-barber pricing fields
                            if (isSelected) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _priceControllers[service.id],
                                      decoration: const InputDecoration(
                                        labelText: 'Price (\$)',
                                        hintText: '30',
                                        prefixIcon: Icon(
                                          Icons.attach_money,
                                          size: 18,
                                        ),
                                        isDense: true,
                                      ),
                                      keyboardType: TextInputType.number,
                                      style: AppTypography.body.copyWith(
                                        color: context.isDark
                                            ? AppColors.goldPrimary
                                            : context.colors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller:
                                          _durationControllers[service.id],
                                      decoration: const InputDecoration(
                                        labelText: 'Duration (min)',
                                        hintText: '30',
                                        prefixIcon: Icon(
                                          Icons.timer_outlined,
                                          size: 18,
                                        ),
                                        isDense: true,
                                      ),
                                      keyboardType: TextInputType.number,
                                      style: AppTypography.body.copyWith(
                                        color: context.isDark
                                            ? AppColors.goldPrimary
                                            : context.colors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 24),

              AppButton(
                label: isEditing ? 'Update Barber' : 'Create Barber',
                isLoading: _isSaving,
                onPressed: _save,
                width: double.infinity,
              ),

              if (isEditing) ...[
                const SizedBox(height: 12),
                AppButton(
                  label: 'Set Working Hours →',
                  isOutlined: true,
                  onPressed: () {
                    context.push(
                      AppRoutes.adminWorkingHours.replaceFirst(
                        ':barberId',
                        widget.barberId!,
                      ),
                    );
                  },
                  width: double.infinity,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: context.colors.surface,
                        title: const Text('Deactivate Barber?'),
                        content: const Text(
                          'The barber will be hidden from booking but all history is preserved.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              if (widget.barberId != null) {
                                ref
                                    .read(barbersProvider.notifier)
                                    .toggleActive(widget.barberId!);
                              }
                              Navigator.pop(ctx);
                              context.pop();
                            },
                            child: const Text(
                              'Deactivate',
                              style: TextStyle(color: AppColors.errorRed),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text(
                    'Deactivate Barber',
                    style: TextStyle(color: AppColors.errorRed),
                  ),
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
