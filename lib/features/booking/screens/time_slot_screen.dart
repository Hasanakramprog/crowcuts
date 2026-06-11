import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_extension.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../core/utils/slot_engine.dart';
import '../../../data/providers/barber_provider.dart';
import '../../../data/providers/booking_provider.dart';
import '../../../data/models/models.dart';
import 'barber_selection_screen.dart';

/// Step 4 — Time Slot Selection
class TimeSlotScreen extends ConsumerStatefulWidget {
  const TimeSlotScreen({super.key});

  @override
  ConsumerState<TimeSlotScreen> createState() => _TimeSlotScreenState();
}

class _TimeSlotScreenState extends ConsumerState<TimeSlotScreen> {
  final List<DateTime> _nextDays = DateHelpers.getNextDays(7);
  int _selectedDayIndex = 0;
  TimeSlot? _selectedSlot;
  Map<String, List<TimeSlot>> _cachedSlots = {};

  @override
  void initState() {
    super.initState();
    // Upgrade 1: use addPostFrameCallback so ref is fully ready before we read.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _generateSlots());
    });
  }

  void _generateSlots() {
    final flowState = ref.read(bookingFlowProvider);
    final barber = flowState.selectedBarber;
    final bookings = ref.read(bookingProvider);
    if (barber == null) return;

    final slots = <String, List<TimeSlot>>{};
    for (final day in _nextDays) {
      final barberBookings = bookings.where((b) {
        return b.barberId == barber.id &&
            DateHelpers.isSameDay(b.date, day) &&
            // Upgrade 4: also exclude noShow — consistent with SlotEngine._checkOverlap.
            b.status != BookingStatus.cancelled &&
            b.status != BookingStatus.noShow;
      }).toList();

      final daySlots = SlotEngine.generateSlots(
        schedule: barber.schedule,
        date: day,
        existingBookings: barberBookings,
        requiredDurationMinutes: flowState.totalDuration,
      );
      final key = _dateKey(day);
      slots[key] = daySlots;
    }
    _cachedSlots = slots;
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month}-${date.day}';

  String _timeOfDayGroup(TimeOfDay time) {
    final hour = time.hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  @override
  Widget build(BuildContext context) {
    // Upgrade 1: re-generate slots whenever any booking changes in Firestore.
    // ref.listen in build() is the correct Riverpod pattern — registered once
    // per widget lifecycle, not on every rebuild.
    ref.listen<List<BookingModel>>(bookingProvider, (_, __) {
      setState(() => _generateSlots());
    });

    final flowState = ref.watch(bookingFlowProvider);
    final selectedDate = _nextDays[_selectedDayIndex];
    final dateKey = _dateKey(selectedDate);
    final slots = _cachedSlots[dateKey] ?? [];

    // Group slots by time of day
    final morning = slots.where((s) => s.startTime.hour < 12).toList();
    final afternoon = slots
        .where((s) => s.startTime.hour >= 12 && s.startTime.hour < 17)
        .toList();
    final evening = slots.where((s) => s.startTime.hour >= 17).toList();

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Select Time'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.barberSelection),
        ),
      ),
      body: Column(
        children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: StepProgress(currentStep: 4, totalSteps: 5),
          ),

          // Barber summary strip
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: AppRadius.cardBorder,
              border: Border.all(color: context.colors.borderDefault, width: 0.5),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.goldDim,
                  child: Text(
                    flowState.selectedBarber?.name[0] ?? '?',
                    style: AppTypography.bodyBold.copyWith(
                      color: AppColors.goldPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${flowState.selectedBarber?.name ?? ''} · '
                    '${flowState.selectedServices.length} service${flowState.selectedServices.length > 1 ? 's' : ''} · '
                    '~${flowState.totalDuration}min',
                    style: AppTypography.caption.copyWith(
                      color: context.colors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _LegendItem(color: AppColors.goldPrimary, label: 'Free'),
                const SizedBox(width: 12),
                _LegendItem(color: AppColors.warningAmber, label: 'Last slot'),
                const SizedBox(width: 12),
                _LegendItem(color: AppColors.errorRed, label: 'Taken'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Date carousel
          SizedBox(
            height: 54,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _nextDays.length,
              itemBuilder: (context, index) {
                final date = _nextDays[index];
                final isSelected = index == _selectedDayIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDayIndex = index;
                      _selectedSlot = null;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.goldPrimary
                          : context.colors.surface2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.goldPrimary
                            : context.colors.borderDefault,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateHelpers.getDayLabel(date),
                          style: AppTypography.caption.copyWith(
                            color: isSelected
                                ? context.colors.background
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${date.day}',
                          style: AppTypography.caption.copyWith(
                            color: isSelected
                                ? context.colors.background
                                : context.colors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Slot grid label
          Expanded(
            child: slots.isEmpty
                ? Center(
                    child: Text(
                      'No available slots for this day',
                      style: AppTypography.body.copyWith(
                        color: context.colors.textMuted,
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      if (morning.isNotEmpty) ...[
                        Text(
                          'Morning',
                          style: AppTypography.label.copyWith(
                            color: AppColors.goldPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: morning
                              .map((slot) => _SlotTile(
                                    slot: slot,
                                    isSelected: _selectedSlot == slot,
                                    onTap: () {
                                      setState(() {
                                        _selectedSlot = slot;
                                      });
                                      ref.read(bookingFlowProvider.notifier)
                                          .state = flowState.copyWith(
                                        selectedDate: selectedDate,
                                        selectedTime: slot.startTime,
                                      );
                                    },
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (afternoon.isNotEmpty) ...[
                        Text(
                          'Afternoon',
                          style: AppTypography.label.copyWith(
                            color: AppColors.goldPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: afternoon
                              .map((slot) => _SlotTile(
                                    slot: slot,
                                    isSelected: _selectedSlot == slot,
                                    onTap: () {
                                      setState(() {
                                        _selectedSlot = slot;
                                      });
                                      ref.read(bookingFlowProvider.notifier)
                                          .state = flowState.copyWith(
                                        selectedDate: selectedDate,
                                        selectedTime: slot.startTime,
                                      );
                                    },
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (evening.isNotEmpty) ...[
                        Text(
                          'Evening',
                          style: AppTypography.label.copyWith(
                            color: AppColors.goldPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: evening
                              .map((slot) => _SlotTile(
                                    slot: slot,
                                    isSelected: _selectedSlot == slot,
                                    onTap: () {
                                      setState(() {
                                        _selectedSlot = slot;
                                      });
                                      ref.read(bookingFlowProvider.notifier)
                                          .state = flowState.copyWith(
                                        selectedDate: selectedDate,
                                        selectedTime: slot.startTime,
                                      );
                                    },
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                      const SizedBox(height: 100),
                    ],
                  ),
          ),
        ],
      ),
      bottomSheet: _selectedSlot != null
          ? _ConfirmationStrip(
              flowState: flowState,
              selectedDate: selectedDate,
              onContinue: () => context.go(AppRoutes.bookingConfirmation),
            )
          : null,
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: context.colors.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _SlotTile extends StatelessWidget {
  final TimeSlot slot;
  final bool isSelected;
  final VoidCallback onTap;

  const _SlotTile({
    required this.slot,
    required this.isSelected,
    required this.onTap,
  });

  Color _borderColor(BuildContext context) {
    if (isSelected) return AppColors.goldPrimary;
    switch (slot.status) {
      case SlotStatus.free:
        return context.colors.borderDefault;
      case SlotStatus.almostFull:
        return AppColors.warningAmber;
      case SlotStatus.taken:
        return AppColors.errorRed;
      case SlotStatus.selected:
        return AppColors.goldPrimary;
    }
  }

  Color _bgColor(BuildContext context) {
    if (isSelected) return AppColors.goldPrimary;
    switch (slot.status) {
      case SlotStatus.free:
        return context.colors.surface2;
      case SlotStatus.almostFull:
        return context.colors.surface2;
      case SlotStatus.taken:
        return context.colors.surface2;
      case SlotStatus.selected:
        return AppColors.goldPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTaken = slot.status == SlotStatus.taken;

    return GestureDetector(
      onTap: isTaken ? null : onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _bgColor(context),
            borderRadius: AppRadius.slotBorder,
            border: Border.all(
              color: _borderColor(context),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                slot.startLabel,
                style: AppTypography.time.copyWith(
                  color: isSelected
                      ? context.colors.background
                      : isTaken
                          ? AppColors.errorRed
                          : AppColors.textPrimary,
                  decoration:
                      isTaken ? TextDecoration.lineThrough : null,
                  fontWeight: isTaken ? FontWeight.w400 : FontWeight.w600,
                ),
              ),
              if (slot.status == SlotStatus.almostFull) ...[
                const SizedBox(width: 6),
                Text(
                  'LAST!',
                  style: AppTypography.label.copyWith(
                    color: AppColors.warningAmber,
                    fontSize: 9,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Confirmation strip that slides up when a slot is selected
class _ConfirmationStrip extends StatelessWidget {
  final BookingFlowState flowState;
  final DateTime selectedDate;
  final VoidCallback onContinue;

  const _ConfirmationStrip({
    required this.flowState,
    required this.selectedDate,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          top: BorderSide(color: context.colors.borderDefault, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Summary
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${DateHelpers.formatDateFull(selectedDate)} · ${flowState.selectedTime?.format(context) ?? ''}',
                      style: AppTypography.bodyBold,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${flowState.selectedBarber?.name ?? ''} · ${flowState.selectedServices.length} service${flowState.selectedServices.length > 1 ? 's' : ''}',
                      style: AppTypography.caption.copyWith(
                        color: context.colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${flowState.totalPrice.toStringAsFixed(0)}',
                style: AppTypography.priceLarge.copyWith(
                  color: AppColors.goldPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Continue to Confirm',
            onPressed: onContinue,
            width: double.infinity,
          ),
        ],
      ),
    );
  }
}
