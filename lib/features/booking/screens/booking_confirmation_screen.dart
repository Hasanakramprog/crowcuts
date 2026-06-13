import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_extension.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/booking_provider.dart';
import '../../../data/models/models.dart';
import '../../../features/booking/screens/barber_selection_screen.dart';

/// Step 5 — Booking Confirmation
class BookingConfirmationScreen extends ConsumerWidget {
  const BookingConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flowState = ref.watch(bookingFlowProvider);
    final authState = ref.watch(authProvider);
    final barber = flowState.selectedBarber;
    final services = flowState.selectedServices;
    final user = authState.user;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Confirm Booking'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.timeSlots),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress bar
            StepProgress(currentStep: 5, totalSteps: 5),
            const SizedBox(height: 20),

            // Summary Card
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Barber info
                  Row(
                    children: [
                      AvatarCircle(
                        name: barber?.name ?? '',
                        radius: 24,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              barber?.name ?? '',
                              style: AppTypography.heading2,
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 14,
                                  color: AppColors.goldPrimary,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${barber?.rating.toStringAsFixed(1) ?? ''} · ${barber?.experienceYears ?? 0} years',
                                  style: AppTypography.caption.copyWith(
                                    color: context.colors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Date & Time
                  _InfoRow(
                    icon: Icons.calendar_today,
                    label: 'Date & Time',
                    value: '${DateHelpers.formatDateFull(flowState.selectedDate ?? DateTime.now())} · '
                        '${flowState.selectedTime?.format(context) ?? ''}',
                  ),
                  const SizedBox(height: 12),

                  // Duration
                  _InfoRow(
                    icon: Icons.timer_outlined,
                    label: 'Duration',
                    value: '~${flowState.totalDuration} minutes',
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Services
                  Text(
                    'Services',
                    style: AppTypography.label.copyWith(
                      color: context.colors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...services.map((service) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: AppColors.goldPrimary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                service.name,
                                style: AppTypography.body,
                              ),
                            ),
                            Text(
                              '\$${service.price.toStringAsFixed(2)}',
                              style: AppTypography.bodyBold.copyWith(
                                color: AppColors.goldPrimary,
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Price',
                        style: AppTypography.heading2,
                      ),
                      Text(
                        '\$${flowState.totalPrice.toStringAsFixed(2)}',
                        style: AppTypography.priceLarge.copyWith(
                          color: AppColors.goldPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Confirm Button
            AppButton(
              label: 'Confirm Booking',
              onPressed: () async {
                if (user == null || barber == null) return;

                final now = DateTime.now();
                final bookingId = const Uuid().v4();

                final booking = BookingModel(
                  id: bookingId,
                  customerId: user.id,
                  customerName: user.name,
                  customerPhone: user.phone ?? '',
                  barberId: barber.id,
                  serviceIds: services.map((s) => s.serviceId).toList(),
                  serviceNames: services.map((s) => s.name).toList(),
                  servicePrices: services.map((s) => s.price).toList(),
                  serviceDurations: services.map((s) => s.durationMinutes).toList(),
                  date: flowState.selectedDate ?? now,
                  startTime: flowState.selectedTime ??
                      const TimeOfDay(hour: 9, minute: 0),
                  totalDurationMinutes: flowState.totalDuration,
                  totalPrice: flowState.totalPrice,
                  status: BookingStatus.confirmed,
                  createdAt: now,
                );

                ref.read(bookingProvider.notifier).addBooking(booking);

                if (context.mounted) {
                  context.go(AppRoutes.bookingSuccess);
                }
              },
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            const SizedBox(height: 12),

            TextButton(
              onPressed: () => context.go(AppRoutes.timeSlots),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.goldDim,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.goldPrimary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: context.colors.textMuted,
                ),
              ),
              Text(
                value,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
