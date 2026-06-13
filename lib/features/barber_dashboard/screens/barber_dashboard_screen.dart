import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_extension.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/barber_scoped_providers.dart';
import '../../../data/models/models.dart';
import '../../../core/theme/theme_provider.dart';

/// Barber Dashboard — Tabbed Shell with Schedule, Earnings, and Reviews.
class BarberDashboardScreen extends ConsumerStatefulWidget {
  const BarberDashboardScreen({super.key});

  @override
  ConsumerState<BarberDashboardScreen> createState() =>
      _BarberDashboardScreenState();
}

class _BarberDashboardScreenState
    extends ConsumerState<BarberDashboardScreen> {
  int _currentTab = 0;
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final barberId = user?.barberId ?? 'barber-1';

    final screens = [
      _ScheduleTab(barberId: barberId, selectedDate: _selectedDate, onDateChanged: (d) {
        setState(() => _selectedDate = d);
      }),
      _EarningsTab(barberId: barberId),
      _ReviewsTab(barberId: barberId),
    ];

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _BarberHeader(
              user: user,
              onLogout: () {
                ref.read(authProvider.notifier).logout();
                context.go(AppRoutes.login);
              },
            ),
            Expanded(
              child: IndexedStack(
                index: _currentTab,
                children: screens,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: context.colors.surface,
        selectedItemColor: AppColors.goldPrimary,
        unselectedItemColor: context.colors.textMuted,
        currentIndex: _currentTab,
        onTap: (index) => setState(() => _currentTab = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monetization_on_outlined),
            activeIcon: Icon(Icons.monetization_on),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_outline),
            activeIcon: Icon(Icons.star),
            label: 'Reviews',
          ),
        ],
      ),
    );
  }
}

class _BarberHeader extends ConsumerWidget {
  final UserModel? user;
  final VoidCallback onLogout;

  const _BarberHeader({required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.goldDim.withAlpha(50),
            context.colors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colors.borderGold, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.goldDim,
              border: Border.all(color: AppColors.goldPrimary, width: 1.5),
            ),
            child: const Icon(Icons.content_cut_rounded,
                color: AppColors.goldPrimary, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Barber Dashboard',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.goldLight,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  user?.name ?? 'Barber',
                  style: AppTypography.heading2.copyWith(fontSize: 18),
                ),
                Text(
                  'Crown Cuts Management',
                  style: AppTypography.caption.copyWith(
                    color: context.colors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            icon: Icon(context.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            color: context.colors.textMuted,
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            onPressed: () => context.push(AppRoutes.barberSettings),
            icon: const Icon(Icons.settings_rounded),
            color: context.colors.textMuted,
            tooltip: 'Settings',
          ),
          IconButton(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
            color: context.colors.textMuted,
            tooltip: 'Logout',
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: -0.2, end: 0, curve: Curves.easeOutCubic);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: Schedule
// ─────────────────────────────────────────────────────────────────────────────

class _ScheduleTab extends ConsumerWidget {
  final String barberId;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const _ScheduleTab({
    required this.barberId,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(barberBookingsProvider);

    final bookings = bookingAsync.maybeWhen(
      data: (b) => b,
      orElse: () => <BookingModel>[],
    );

    final dayBookings = bookings.where((b) {
      return DateHelpers.isSameDay(b.date, selectedDate);
    }).toList()
      ..sort((a, b) => a.startTime.hour.compareTo(b.startTime.hour));

    final completed = dayBookings
        .where((b) => b.status == BookingStatus.completed)
        .length;
    final pending = dayBookings
        .where((b) => b.status == BookingStatus.confirmed)
        .length;
    final inProgress = dayBookings
        .where((b) => b.status == BookingStatus.inProgress)
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly day strip
          _DayStrip(
            selectedDate: selectedDate,
            onDateChanged: onDateChanged,
          ),
          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              _MiniStat(label: 'Total', value: '${dayBookings.length}'),
              const SizedBox(width: 12),
              _MiniStat(label: 'Pending', value: '$pending', color: AppColors.warningAmber),
              const SizedBox(width: 12),
              _MiniStat(label: 'In Progress', value: '$inProgress', color: AppColors.goldPrimary),
              const SizedBox(width: 12),
              _MiniStat(label: 'Done', value: '$completed', color: AppColors.successGreen),
            ],
          ),
          const SizedBox(height: 24),

          // Date header
          Text(
            DateHelpers.isSameDay(selectedDate, DateTime.now())
                ? "Today's Schedule"
                : DateHelpers.formatDateFull(selectedDate),
            style: AppTypography.heading1,
          ),
          const SizedBox(height: 16),

          // Appointments list
          if (dayBookings.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 48,
                    color: context.colors.textMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No appointments for this day',
                    style: AppTypography.body.copyWith(
                      color: context.colors.textMuted,
                    ),
                  ),
                ],
              ),
            )
          else
            ...dayBookings.map((booking) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AppointmentCard(
                  booking: booking,
                  onTap: () => context.push(
                    AppRoutes.barberAppointmentDetail.replaceFirst(
                      ':bookingId',
                      booking.id,
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Day Strip
// ─────────────────────────────────────────────────────────────────────────────

class _DayStrip extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const _DayStrip({
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(7, (i) => today.add(Duration(days: i)));

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = DateHelpers.isSameDay(day, selectedDate);
          final isToday = DateHelpers.isSameDay(day, today);
          final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day.weekday - 1];

          return GestureDetector(
            onTap: () => onDateChanged(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.goldPrimary : context.colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.goldPrimary
                      : isToday
                          ? AppColors.goldPrimary.withAlpha(80)
                          : context.colors.borderDefault,
                  width: isSelected ? 1.5 : 0.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: AppTypography.caption.copyWith(
                      color: isSelected
                          ? context.colors.background
                          : context.colors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: AppTypography.heading2.copyWith(
                      color: isSelected
                          ? context.colors.background
                          : AppColors.textPrimary,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Earnings
// ─────────────────────────────────────────────────────────────────────────────

class _EarningsTab extends ConsumerWidget {
  final String barberId;

  const _EarningsTab({required this.barberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomeAsync = ref.watch(barberIncomeProvider);

    final barberIncome = incomeAsync.maybeWhen(
      data: (records) => records,
      orElse: () => <IncomeRecord>[],
    );

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);

    final todayIncome =
        barberIncome.where((r) => r.date.isAfter(todayStart.subtract(const Duration(days: 1)))).toList();
    final monthIncome =
        barberIncome.where((r) => r.date.isAfter(monthStart.subtract(const Duration(days: 1)))).toList();

    final todayTotal = barberIncome.fold<double>(0, (sum, r) => sum + r.amount);
    final monthTotal = monthIncome.fold<double>(0, (sum, r) => sum + r.amount);

    // Service breakdown inline
    final serviceBreakdown = <String, double>{};
    for (final record in monthIncome) {
      for (final name in record.serviceNames) {
        serviceBreakdown[name] =
            (serviceBreakdown[name] ?? 0) + (record.amount / record.serviceNames.length);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today's earnings
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Earnings",
                  style: AppTypography.caption.copyWith(
                    color: context.colors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${todayTotal.toStringAsFixed(0)}',
                  style: AppTypography.priceLarge.copyWith(
                    color: AppColors.goldPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${todayIncome.length} appointment${todayIncome.length != 1 ? 's' : ''}',
                  style: AppTypography.caption.copyWith(
                    color: context.colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // This month
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This Month',
                  style: AppTypography.caption.copyWith(
                    color: context.colors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${monthTotal.toStringAsFixed(0)}',
                  style: AppTypography.priceLarge.copyWith(
                    color: AppColors.goldPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${monthIncome.length} appointment${monthIncome.length != 1 ? 's' : ''}',
                  style: AppTypography.caption.copyWith(
                    color: context.colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Breakdown by service
          Text(
            'Breakdown by Service',
            style: AppTypography.heading1,
          ),
          const SizedBox(height: 12),
          ...serviceBreakdown.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(entry.key, style: AppTypography.body),
                  ),
                  Text(
                    '\$${entry.value.toStringAsFixed(0)}',
                    style: AppTypography.price.copyWith(
                      color: AppColors.goldPrimary,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (serviceBreakdown.isEmpty)
            Text(
              'No data yet this month',
              style: AppTypography.body.copyWith(
                color: context.colors.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3: Reviews
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewsTab extends ConsumerWidget {
  final String barberId;

  const _ReviewsTab({required this.barberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingsAsync = ref.watch(barberRatingsProvider(barberId));

    final barberRatings = ratingsAsync.maybeWhen(
      data: (ratings) => [...ratings]..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      orElse: () => <RatingModel>[],
    );

    if (barberRatings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_border,
              size: 48,
              color: context.colors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'No reviews yet',
              style: AppTypography.body.copyWith(
                color: context.colors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: barberRatings.length,
      itemBuilder: (context, index) {
        final rating = barberRatings[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AvatarCircle(
                      name: rating.customerName,
                      radius: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rating.customerName,
                            style: AppTypography.bodyBold,
                          ),
                          Text(
                            '${rating.createdAt.day}/${rating.createdAt.month}/${rating.createdAt.year}',
                            style: AppTypography.caption.copyWith(
                              color: context.colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        final filled = i < rating.stars.floor();
                        final half = i == rating.stars.floor() &&
                            rating.stars - i >= 0.5;
                        return Icon(
                          filled
                              ? Icons.star
                              : half
                                  ? Icons.star_half
                                  : Icons.star_border,
                          size: 16,
                          color: AppColors.goldPrimary,
                        );
                      }),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating.stars.toStringAsFixed(1),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.goldPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (rating.comment != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    rating.comment!,
                    style: AppTypography.body.copyWith(
                      color: context.colors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mini Stat Card (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _MiniStat({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (color ?? context.colors.textMuted).withAlpha(40),
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTypography.heading1.copyWith(
                color: color ?? (context.isDark ? AppColors.goldPrimary : context.colors.textPrimary),
              ),
            ),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: context.colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Appointment Card (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _AppointmentCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;

  const _AppointmentCard({
    required this.booking,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: booking.status.color.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  booking.startTime.format(context).split(' ').first,
                  style: AppTypography.time.copyWith(
                    color: booking.status.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  booking.startTime.format(context).split(' ').last,
                  style: AppTypography.caption.copyWith(
                    color: booking.status.color,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.customerName,
                  style: AppTypography.bodyBold,
                ),
                const SizedBox(height: 2),
                Text(
                  booking.serviceNames.join(', '),
                  style: AppTypography.caption.copyWith(
                    color: context.colors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateHelpers.formatDuration(booking.totalDurationMinutes)} · \$${booking.totalPrice.toStringAsFixed(0)}',
                  style: AppTypography.caption.copyWith(
                    color: context.colors.textMuted,
                    fontSize: 12,
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
    );
  }
}
