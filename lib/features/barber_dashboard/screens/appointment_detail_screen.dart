import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_extension.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../data/repositories/firebase_firestore_repository.dart';
import '../../../data/models/models.dart';

/// Appointment Detail Screen (Barber view)
class AppointmentDetailScreen extends ConsumerWidget {
  final String bookingId;

  const AppointmentDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingFuture =
        ref.read(firebaseFirestoreRepositoryProvider).getBooking(bookingId);

    return FutureBuilder<BookingModel?>(
      future: bookingFuture,
      builder: (context, snapshot) {
        final booking = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: context.colors.background,
            appBar: AppBar(title: const Text('Appointment')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (booking == null) {
          return Scaffold(
            backgroundColor: context.colors.background,
            appBar: AppBar(title: const Text('Appointment')),
            body: const Center(child: Text('Appointment not found')),
          );
        }

        return Scaffold(
          backgroundColor: context.colors.background,
          appBar: AppBar(
            title: Text('Appointment with ${booking.customerName}'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Customer info
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.goldDim,
                            child: Text(
                              booking.customerName[0],
                              style: AppTypography.heading2.copyWith(
                                color: AppColors.goldPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(booking.customerName,
                                    style: AppTypography.heading2),
                                Text(
                                  booking.customerPhone,
                                  style: AppTypography.body.copyWith(
                                    color: context.colors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(
                            label: booking.status.displayName,
                            color: booking.status.color,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Date & Time
                      _InfoRow(
                        icon: Icons.calendar_today,
                        label: DateHelpers.formatDateFull(booking.date),
                      ),
                      const SizedBox(height: 6),
                      _InfoRow(
                        icon: Icons.schedule,
                        label:
                            '${booking.startTime.format(context)} · ${DateHelpers.formatDuration(booking.totalDurationMinutes)}',
                      ),

                      const SizedBox(height: 16),
                      Text('Services',
                          style: AppTypography.label.copyWith(
                              color: context.colors.textMuted)),
                      const SizedBox(height: 8),
                      ...booking.serviceNames.map((name) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.check,
                                    size: 14, color: AppColors.goldPrimary),
                                const SizedBox(width: 8),
                                Text(name, style: AppTypography.body),
                              ],
                            ),
                          )),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total', style: AppTypography.heading2),
                          Text(
                            '\$${booking.totalPrice.toStringAsFixed(2)}',
                            style: AppTypography.priceLarge.copyWith(
                              color: AppColors.goldPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action buttons
                if (booking.status == BookingStatus.confirmed) ...[
                  AppButton(
                    label: 'Mark In Progress',
                    onPressed: () {
                      ref.read(firebaseFirestoreRepositoryProvider)
                        .updateBookingStatus(booking.id, BookingStatus.inProgress);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${booking.customerName} marked as In Progress'),
                          backgroundColor: AppColors.goldPrimary,
                        ),
                      );
                      context.pop();
                    },
                    width: double.infinity,
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    label: 'Mark No Show',
                    onPressed: () {
                      ref.read(firebaseFirestoreRepositoryProvider)
                        .cancelBooking(booking.id, reason: 'No show');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${booking.customerName} marked as No Show'),
                          backgroundColor: AppColors.errorRed,
                        ),
                      );
                      context.pop();
                    },
                    width: double.infinity,
                  ),
                ],
                if (booking.status == BookingStatus.inProgress)
                  AppButton(
                    label: 'Mark Completed',
                    onPressed: () {
                      final repo = ref.read(firebaseFirestoreRepositoryProvider);
                      repo.updateBookingStatus(booking.id, BookingStatus.completed);

                      // Income goes to barber when they mark completed
                      final record = IncomeRecord(
                        id: 'inc-${DateTime.now().millisecondsSinceEpoch}',
                        bookingId: booking.id,
                        barberId: booking.barberId,
                        barberName: booking.barberId, // barber name resolved via provider
                        serviceIds: booking.serviceIds,
                        serviceNames: booking.serviceNames,
                        amount: booking.totalPrice,
                        date: DateTime.now(),
                      );
                      repo.createIncomeRecord(record);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '${booking.customerName}\'s appointment completed!'),
                          backgroundColor: AppColors.successGreen,
                        ),
                      );
                      context.pop();
                    },
                    width: double.infinity,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: context.colors.textMuted),
        const SizedBox(width: 8),
        Text(label, style: AppTypography.body),
      ],
    );
  }
}
