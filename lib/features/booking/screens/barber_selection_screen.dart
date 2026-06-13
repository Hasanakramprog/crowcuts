import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_extension.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../../core/router/app_router.dart';
import '../../../data/providers/barber_provider.dart';
import '../../../data/models/models.dart';

/// Booking flow state shared across steps
class BookingFlowState {
  final BarberModel? selectedBarber;
  final List<BarberService> selectedServices;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final int totalDuration;
  final double totalPrice;

  const BookingFlowState({
    this.selectedBarber,
    this.selectedServices = const [],
    this.selectedDate,
    this.selectedTime,
    this.totalDuration = 0,
    this.totalPrice = 0.0,
  });

  BookingFlowState copyWith({
    BarberModel? selectedBarber,
    List<BarberService>? selectedServices,
    DateTime? selectedDate,
    TimeOfDay? selectedTime,
    int? totalDuration,
    double? totalPrice,
  }) {
    return BookingFlowState(
      selectedBarber: selectedBarber ?? this.selectedBarber,
      selectedServices: selectedServices ?? this.selectedServices,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      totalDuration: totalDuration ?? this.totalDuration,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}

/// Provider to share booking flow state across screens.
final bookingFlowProvider = StateProvider<BookingFlowState>(
  (ref) => const BookingFlowState(),
);

/// Step 2 & 3 — Barber Selection + Service Selection
class BarberSelectionScreen extends ConsumerStatefulWidget {
  const BarberSelectionScreen({super.key});

  @override
  ConsumerState<BarberSelectionScreen> createState() =>
      _BarberSelectionScreenState();
}

class _BarberSelectionScreenState extends ConsumerState<BarberSelectionScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.72);
  int _currentPage = 0;
  BarberModel? _selectedBarber;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final barbers = ref.read(activeBarbersProvider);
      if (barbers.isEmpty) return;

      // Check if a barber was pre-selected from the home screen
      final flowBarber = ref.read(bookingFlowProvider).selectedBarber;
      final preSelectedIndex = flowBarber != null
          ? barbers.indexWhere((b) => b.id == flowBarber.id)
          : -1;

      final idx = preSelectedIndex >= 0 ? preSelectedIndex : 0;
      setState(() {
        _currentPage = idx;
        _selectedBarber = barbers[idx];
      });
      // Scroll the carousel to the pre-selected barber
      _pageController.animateToPage(
        idx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      ref.read(bookingFlowProvider.notifier).state = BookingFlowState(
        selectedBarber: barbers[idx],
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barbers = ref.watch(activeBarbersProvider);
    final flowState = ref.watch(bookingFlowProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Book Appointment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.customerHome),
        ),
        actions: [
          TextButton(
            onPressed: () => context.go(AppRoutes.customerHome),
            child: const Text('Cancel'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar — Step 2 of 5
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: StepProgress(currentStep: 2, totalSteps: 5),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text('Choose Your Barber', style: AppTypography.heading1),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 16),

          // ── Carousel ──────────────────────────────────────────────
          SizedBox(
            height: 210,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Radial glow behind selected chair
                AnimatedBuilder(
                  animation: const AlwaysStoppedAnimation(1),
                  builder: (context, _) {
                    return CustomPaint(
                      size: const Size(double.infinity, 210),
                      painter: _CarouselGlowPainter(
                        centerX: MediaQuery.of(context).size.width / 2,
                      ),
                    );
                  },
                ),

                PageView.builder(
                  controller: _pageController,
                  itemCount: barbers.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                      _selectedBarber = barbers[index];
                    });
                    ref.read(bookingFlowProvider.notifier).state = flowState
                        .copyWith(
                          selectedBarber: barbers[index],
                          selectedServices: [],
                        );
                  },
                  itemBuilder: (context, index) {
                    final barber = barbers[index];
                    final isSelected = index == _currentPage;
                    return _ChairCard(
                      barber: barber,
                      isSelected: isSelected,
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOutCubic,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          // Page indicator dots
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(barbers.length, (i) {
              final isSelected = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isSelected ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.goldPrimary
                      : context.colors.borderDefault,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),

          const SizedBox(height: 16),

          // ── Barber detail + services ───────────────────────────────
          if (_selectedBarber != null)
            Expanded(
              child: _BarberDetailSheet(
                barber: _selectedBarber!,
                flowState: flowState,
                onServicesChanged: (services) {
                  final totalDuration = services.fold<int>(
                    0,
                    (sum, s) => sum + s.durationMinutes,
                  );
                  final totalPrice = services.fold<double>(
                    0,
                    (sum, s) => sum + s.price,
                  );
                  ref.read(bookingFlowProvider.notifier).state = flowState
                      .copyWith(
                        selectedServices: services,
                        totalDuration: totalDuration,
                        totalPrice: totalPrice,
                      );
                },
              ),
            ),

          // Bottom action bar
          if (_selectedBarber != null) _buildBottomBar(context, flowState),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, BookingFlowState flowState) {
    final hasServices = flowState.selectedServices.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          top: BorderSide(color: context.colors.borderDefault, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          if (hasServices) ...[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${flowState.selectedServices.length} service${flowState.selectedServices.length > 1 ? 's' : ''}',
                    style: AppTypography.caption.copyWith(
                      color: context.colors.textMuted,
                    ),
                  ),
                  Text(
                    '\$${flowState.totalPrice.toStringAsFixed(0)} · ~${flowState.totalDuration}min',
                    style: AppTypography.bodyBold.copyWith(
                      color: AppColors.goldPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Expanded(
              child: Text(
                'Select at least one service',
                style: AppTypography.caption.copyWith(
                  color: context.colors.textMuted,
                ),
              ),
            ),
          ],
          AppButton(
            label: 'Choose Time →',
            onPressed: hasServices
                ? () => context.go(AppRoutes.timeSlots)
                : null,
          ),
        ],
      ),
    );
  }
}

/// Gold radial glow behind the center chair
class _CarouselGlowPainter extends CustomPainter {
  final double centerX;

  _CarouselGlowPainter({required this.centerX});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(centerX, size.height / 2);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [AppColors.goldPrimary.withAlpha(35), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: 120));
    canvas.drawCircle(center, 120, paint);
  }

  @override
  bool shouldRepaint(_CarouselGlowPainter old) => old.centerX != centerX;
}

/// Animated barber chair card
class _ChairCard extends StatelessWidget {
  final BarberModel barber;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChairCard({
    required this.barber,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.08 : 0.88,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: isSelected ? 1.0 : 0.38,
          duration: const Duration(milliseconds: 250),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected
                    ? AppColors.goldPrimary
                    : context.colors.borderDefault,
                width: isSelected ? 2 : 0.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.goldShadow,
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Barber avatar with glow ring
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isSelected)
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.goldPrimary.withAlpha(15),
                        ),
                      ),
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.goldPrimary
                              : context.colors.borderDefault,
                          width: isSelected ? 2.5 : 1,
                        ),
                      ),
                      child: ClipOval(
                        child: barber.avatarUrl.isNotEmpty
                            ? Image.network(
                                barber.avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _BarberInitialAvatar(
                                      name: barber.name,
                                      isSelected: isSelected,
                                    ),
                              )
                            : _BarberInitialAvatar(
                                name: barber.name,
                                isSelected: isSelected,
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  barber.name,
                  style: AppTypography.heading2.copyWith(
                    color: isSelected
                        ? (context.isDark
                              ? AppColors.goldPrimary
                              : context.colors.textPrimary)
                        : context.colors.textMuted,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 12,
                      color: isSelected
                          ? AppColors.goldPrimary
                          : context.colors.textMuted,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      barber.rating.toStringAsFixed(1),
                      style: AppTypography.caption.copyWith(
                        color: isSelected
                            ? AppColors.goldLight
                            : context.colors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppColors.successGreen
                            : context.colors.textMuted.withAlpha(80),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Available',
                      style: AppTypography.caption.copyWith(
                        color: isSelected
                            ? AppColors.successGreen
                            : context.colors.textMuted.withAlpha(80),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Barber detail + service selection sheet
class _BarberDetailSheet extends StatelessWidget {
  final BarberModel barber;
  final BookingFlowState flowState;
  final ValueChanged<List<BarberService>> onServicesChanged;

  const _BarberDetailSheet({
    required this.barber,
    required this.flowState,
    required this.onServicesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedIds = flowState.selectedServices
        .map((s) => s.serviceId)
        .toSet();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(barber.id),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: AppRadius.cardBorder,
          border: Border.all(color: context.colors.borderDefault, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barber header
            Row(
              children: [
                AvatarCircle(name: barber.name, radius: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(barber.name, style: AppTypography.heading2),
                      Text(
                        '${barber.experienceYears} yrs experience · ${barber.services.length} services',
                        style: AppTypography.caption.copyWith(
                          color: context.colors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.goldDim,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: AppColors.goldPrimary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${barber.rating.toStringAsFixed(1)} (${barber.reviewCount})',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.goldPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Text(
              'SELECT SERVICES',
              style: AppTypography.label.copyWith(
                color: context.colors.textMuted,
                fontSize: 10,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),

            // Service grid
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: barber.services.length,
                itemBuilder: (context, index) {
                  final service = barber.services[index];
                  final isSelected = selectedIds.contains(service.serviceId);
                  return _ServiceCard(
                    service: service,
                    isSelected: isSelected,
                    onTap: () {
                      final current = List<BarberService>.from(
                        flowState.selectedServices,
                      );
                      if (isSelected) {
                        current.removeWhere(
                          (s) => s.serviceId == service.serviceId,
                        );
                      } else {
                        current.add(service);
                      }
                      onServicesChanged(current);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Service selection card
class _ServiceCard extends StatelessWidget {
  final BarberService service;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.service,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: service.isAvailable ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldDim : context.colors.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.goldPrimary
                : context.colors.borderDefault,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    service.name,
                    style: AppTypography.caption.copyWith(
                      color: isSelected
                          ? AppColors.textPrimary
                          : context.colors.textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '\$${service.price.toStringAsFixed(0)} · ${service.durationMinutes}min',
                    style: AppTypography.caption.copyWith(
                      color: isSelected
                          ? AppColors.goldPrimary
                          : context.colors.textMuted.withAlpha(160),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? const Icon(
                      Icons.check_circle_rounded,
                      key: ValueKey('checked'),
                      color: AppColors.goldPrimary,
                      size: 18,
                    )
                  : Icon(
                      Icons.radio_button_unchecked_rounded,
                      key: const ValueKey('unchecked'),
                      color: context.colors.textMuted.withAlpha(100),
                      size: 18,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fallback avatar showing barber initials when no photo is available
class _BarberInitialAvatar extends StatelessWidget {
  final String name;
  final bool isSelected;

  const _BarberInitialAvatar({
    required this.name,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'B';
    return Container(
      color: isSelected
          ? AppColors.goldPrimary.withAlpha(30)
          : context.colors.surface2,
      child: Center(
        child: Text(
          initial,
          style: AppTypography.heading1.copyWith(
            color: isSelected ? AppColors.goldPrimary : context.colors.textMuted,
            fontSize: 26,
          ),
        ),
      ),
    );
  }
}
