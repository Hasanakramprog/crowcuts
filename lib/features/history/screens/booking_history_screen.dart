import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_extension.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/booking_provider.dart';
import '../../../data/models/models.dart';
import '../../../features/home/screens/home_screen.dart';

/// Booking History Screen
class BookingHistoryScreen extends ConsumerWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final bookings = user != null
        ? ref.read(bookingProvider.notifier).getBookingsForCustomer(user.id)
        : <BookingModel>[];

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Booking History'),
      ),
      body: bookings.isEmpty
          ? const EmptyState(
              icon: Icons.history,
              title: 'No bookings yet',
              subtitle: 'Book your first appointment to get started!',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return _BookingHistoryCard(
                  booking: booking,
                  onTap: () {
                    context.push(
                      AppRoutes.bookingDetail.replaceFirst(
                        ':bookingId',
                        booking.id,
                      ),
                    );
                  },
                );
              },
            ),
      bottomNavigationBar: const _CustomerBottomNav(currentIndex: 2),
    );
  }
}

class _BookingHistoryCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;

  const _BookingHistoryCard({
    required this.booking,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPast = booking.date.isBefore(DateTime.now()) &&
        booking.status != BookingStatus.confirmed &&
        booking.status != BookingStatus.pending;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.serviceNames.join(', '),
                        style: AppTypography.bodyBold,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateHelpers.formatDateFull(booking.date),
                        style: AppTypography.caption.copyWith(
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
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: context.colors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  '${booking.startTime.format(context)} · ${DateHelpers.formatDuration(booking.totalDurationMinutes)}',
                  style: AppTypography.caption.copyWith(
                    color: context.colors.textMuted,
                  ),
                ),
                const Spacer(),
                Text(
                  '\$${booking.totalPrice.toStringAsFixed(0)}',
                  style: AppTypography.price.copyWith(
                    color: AppColors.goldPrimary,
                  ),
                ),
              ],
            ),
            // Show rate button for completed unrated bookings
            if (booking.status == BookingStatus.completed &&
                !booking.isRated) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      context.go(
                        AppRoutes.rating.replaceFirst(':bookingId', booking.id),
                      );
                    },
                    icon: const Icon(Icons.star_border, size: 16),
                    label: const Text('Leave a Review'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Customer Bottom Nav (same as home)
class _CustomerBottomNav extends StatelessWidget {
  final int currentIndex;

  const _CustomerBottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: context.colors.borderDefault, width: 0.5),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go(AppRoutes.customerHome);
              break;
            case 1:
              context.go(AppRoutes.barberSelection);
              break;
            case 2:
              context.go(AppRoutes.bookingHistory);
              break;
            case 3:
              context.go(AppRoutes.profile);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.event_outlined), label: 'Book'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
