import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_extension.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../data/providers/booking_provider.dart';
import '../../../data/providers/barber_provider.dart';
import '../../../data/models/models.dart';

/// Booking Detail Screen
class BookingDetailScreen extends ConsumerWidget {
  final String bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref.read(bookingProvider.notifier).getBookingById(bookingId);
    final barber = booking != null
        ? ref.read(barberProvider(booking.barberId))
        : null;

    if (booking == null) {
      return Scaffold(
        backgroundColor: context.colors.background,
        appBar: AppBar(title: const Text('Booking Details')),
        body: const Center(child: Text('Booking not found')),
      );
    }

    final canCancel = booking.status == BookingStatus.confirmed &&
        booking.date.difference(DateTime.now()).inHours > 2;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Booking Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.bookingHistory);
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: booking.status.color.withAlpha(20),
                borderRadius: AppRadius.cardBorder,
                border: Border.all(
                  color: booking.status.color.withAlpha(60),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  StatusBadge(
                    label: booking.status.displayName,
                    color: booking.status.color,
                    isAnimated: true,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Booking #${booking.id.substring(0, booking.id.length < 8 ? booking.id.length : 8)}',
                    style: AppTypography.caption.copyWith(
                      color: context.colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Barber info
            AppCard(
              child: Row(
                children: [
                  AvatarCircle(
                    name: barber?.name ?? 'Barber',
                    radius: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          barber?.name ?? 'Barber',
                          style: AppTypography.heading2,
                        ),
                        if (barber != null)
                          Text(
                            '${barber.experienceYears} years experience',
                            style: AppTypography.caption.copyWith(
                              color: context.colors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Date, time, duration
            _DetailInfo(
              icon: Icons.calendar_today,
              label: 'Date',
              value: DateHelpers.formatDateFull(booking.date),
            ),
            _DetailInfo(
              icon: Icons.schedule,
              label: 'Time',
              value: '${booking.startTime.format(context)} · ${DateHelpers.formatDuration(booking.totalDurationMinutes)}',
            ),
            if (booking.cancellationReason != null)
              _DetailInfo(
                icon: Icons.info_outline,
                label: 'Cancellation Reason',
                value: booking.cancellationReason!,
              ),
            const SizedBox(height: 20),

            // Services
            Text(
              'Services',
              style: AppTypography.label.copyWith(
                color: context.colors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            ...booking.serviceNames.asMap().entries.map((entry) {
              final index = entry.key;
              final name = entry.value;
              final price = booking.servicePrices.length > index
                  ? booking.servicePrices[index]
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: AppColors.goldPrimary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(name, style: AppTypography.body)),
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: AppTypography.bodyBold.copyWith(
                        color: AppColors.goldPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),

            // Total
            const Divider(),
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
            const SizedBox(height: 24),

            // Cancel button
            if (canCancel)
              AppButton(
                label: 'Cancel Booking',
                isOutlined: true,
                onPressed: () => _showCancelDialog(context, ref, booking),
                width: double.infinity,
              ),

            // Review button if applicable
            if (booking.status == BookingStatus.completed && !booking.isRated)
              AppButton(
                label: 'Leave a Review',
                onPressed: () {
                  context.go(
                    AppRoutes.rating.replaceFirst(':bookingId', booking.id),
                  );
                },
                width: double.infinity,
              ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref, BookingModel booking) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: const Text('Cancel Booking?'),
        content: const Text(
          'Are you sure you want to cancel this booking? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Booking'),
          ),
          TextButton(
            onPressed: () {
              ref.read(bookingProvider.notifier).cancelBooking(
                    booking.id,
                    reason: 'Cancelled by customer',
                  );
              Navigator.pop(ctx);
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.bookingHistory);
              }
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: context.colors.textMuted),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: AppTypography.caption.copyWith(
              color: context.colors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.body.copyWith(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
