import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_extension.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';

import '../../../core/widgets/status_badge.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../data/providers/booking_provider.dart';
import '../../../data/providers/barber_provider.dart';
import '../../../data/models/models.dart';

/// Admin — All Bookings View with filtering and admin cancel
class AllBookingsScreen extends ConsumerStatefulWidget {
  const AllBookingsScreen({super.key});

  @override
  ConsumerState<AllBookingsScreen> createState() => _AllBookingsScreenState();
}

class _AllBookingsScreenState extends ConsumerState<AllBookingsScreen> {
  String _statusFilter = 'All';
  String _barberFilter = 'All';
  bool _showFilters = false;

  final List<String> _statusFilters = [
    'All',
    'Confirmed',
    'In Progress',
    'Completed',
    'Cancelled',
  ];

  List<String> get _barberFilters {
    final barbers = ref.read(barbersProvider);
    return ['All', ...barbers.map((b) => b.name)];
  }

  void _cancelBooking(BookingModel booking) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: const Text('Cancel Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cancel booking for ${booking.customerName}?',
              style: AppTypography.body,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Cancellation reason (required)',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss'),
          ),
          TextButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              ref
                  .read(bookingProvider.notifier)
                  .adminCancelBooking(booking.id, reason);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Booking cancelled'),
                  backgroundColor: AppColors.successGreen,
                ),
              );
            },
            child: const Text(
              'Cancel Booking',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allBookings = ref.watch(bookingProvider);
    final barbers = ref.watch(barbersProvider);

    // Apply filters
    var filtered = allBookings.toList();

    if (_statusFilter != 'All') {
      filtered = filtered
          .where((b) => b.status.displayName == _statusFilter)
          .toList();
    }

    if (_barberFilter != 'All') {
      final barber = barbers.firstWhere(
        (b) => b.name == _barberFilter,
        orElse: () => barbers.first,
      );
      filtered =
          filtered.where((b) => b.barberId == barber.id).toList();
    }

    filtered.sort((a, b) => b.date.compareTo(a.date));

    // Stats
    final total = allBookings.length;
    final confirmed =
        allBookings.where((b) => b.status == BookingStatus.confirmed).length;
    final completed =
        allBookings.where((b) => b.status == BookingStatus.completed).length;
    final cancelled =
        allBookings.where((b) => b.status == BookingStatus.cancelled).length;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('All Bookings'),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
            tooltip: 'Toggle filters',
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Row(
              children: [
                _MiniStat('$total', 'Total', AppColors.goldPrimary),
                const SizedBox(width: 6),
                _MiniStat('$confirmed', 'Active', AppColors.successGreen),
                const SizedBox(width: 6),
                _MiniStat('$completed', 'Done', context.colors.textMuted),
                const SizedBox(width: 6),
                _MiniStat('$cancelled', 'Cancelled', AppColors.errorRed),
              ],
            ),
          ),

          // Filter chips
          if (_showFilters) ...[
            // Status filter
            SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _statusFilters.length,
                itemBuilder: (context, index) {
                  final filter = _statusFilters[index];
                  final isSelected = _statusFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _statusFilter = filter),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.goldPrimary
                              : context.colors.surface2,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.goldPrimary
                                : context.colors.borderDefault,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          filter,
                          style: AppTypography.caption.copyWith(
                            color: isSelected
                                ? context.colors.background
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // Barber filter
            SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _barberFilters.length,
                itemBuilder: (context, index) {
                  final filter = _barberFilters[index];
                  final isSelected = _barberFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _barberFilter = filter),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.goldPrimary
                              : context.colors.surface2,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.goldPrimary
                                : context.colors.borderDefault,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          filter,
                          style: AppTypography.caption.copyWith(
                            color: isSelected
                                ? context.colors.background
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
          ],

          const SizedBox(height: 4),

          // Booking list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 48,
                            color: context.colors.textMuted.withAlpha(60)),
                        const SizedBox(height: 12),
                        Text('No bookings found',
                            style: AppTypography.body.copyWith(
                                color: context.colors.textMuted)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final booking = filtered[index];
                      final barber = barbers.firstWhere(
                        (b) => b.id == booking.barberId,
                        orElse: () => barbers.first,
                      );
                      final canCancel = booking.status ==
                              BookingStatus.confirmed ||
                          booking.status == BookingStatus.pending ||
                          booking.status == BookingStatus.inProgress;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top row: date + status
                              Row(
                                children: [
                                  // Date column
                                  Container(
                                    width: 48,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8),
                                    decoration: BoxDecoration(
                                      color: booking.status.color
                                          .withAlpha(20),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          '${booking.date.day}',
                                          style:
                                              AppTypography.heading2.copyWith(
                                            color: booking.status.color,
                                          ),
                                        ),
                                        Text(
                                          DateHelpers.getMonthShortName(
                                              booking.date.month),
                                          style: AppTypography.caption
                                              .copyWith(
                                            color: booking.status.color,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          booking.customerName,
                                          style: AppTypography.bodyBold,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${barber.name}',
                                          style:
                                              AppTypography.caption.copyWith(
                                            color: AppColors.goldPrimary,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          '${booking.serviceNames.join(', ')} · ${booking.startTime.format(context)}',
                                          style: AppTypography.caption
                                              .copyWith(
                                            color: context.colors.textMuted,
                                            fontSize: 11,
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

                              // Bottom row: total + cancel
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    '\$${booking.totalPrice.toStringAsFixed(0)}',
                                    style: AppTypography.price.copyWith(
                                      fontSize: 14,
                                      color: AppColors.goldPrimary,
                                    ),
                                  ),
                                  Text(
                                    ' · ${booking.totalDurationMinutes}min',
                                    style: AppTypography.caption.copyWith(
                                      color: context.colors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (canCancel)
                                    GestureDetector(
                                      onTap: () =>
                                          _cancelBooking(booking),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.errorRed
                                              .withAlpha(20),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Cancel',
                                          style:
                                              AppTypography.caption.copyWith(
                                            color: AppColors.errorRed,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ).animate()
                          .fadeIn(duration: 300.ms, delay: (index * 50).ms)
                          .slideX(begin: 0.1, end: 0,
                              curve: Curves.easeOutCubic);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _MiniStat(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(40), width: 0.5),
        ),
        child: Column(
          children: [
            Text(value,
                style: AppTypography.heading2.copyWith(
                    color: color, fontSize: 15)),
            Text(label,
                style: AppTypography.caption.copyWith(
                    color: context.colors.textMuted, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
