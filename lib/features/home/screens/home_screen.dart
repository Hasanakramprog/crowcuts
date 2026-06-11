import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_extension.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/barber_provider.dart';
import '../../../data/providers/booking_provider.dart';
import '../../../data/models/models.dart';
import '../../../core/theme/theme_provider.dart';
import '../../booking/screens/barber_selection_screen.dart'
    show bookingFlowProvider, BookingFlowState;

/// Customer Home Screen — Premium animated layout
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final barbers = ref.watch(activeBarbersProvider);
    final user = authState.user;

    final upcoming = user != null
        ? ref.read(bookingProvider.notifier).getUpcomingForCustomer(user.id)
        : <BookingModel>[];

    final today = DateTime.now();
    final todaysBookings = ref
        .read(bookingProvider.notifier)
        .getAllBookings()
        .where(
          (b) =>
              DateHelpers.isSameDay(b.date, today) &&
              b.status != BookingStatus.cancelled,
        )
        .length;

    final greeting = _getGreeting();

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Premium header
            SliverToBoxAdapter(
              child: _HomeHeader(
                user: user,
                greeting: greeting,
                hasUpcoming: upcoming.isNotEmpty,
              ),
            ),

            // Stats Strip
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: "Today's Bookings",
                        value: '$todaysBookings',
                        icon: Icons.calendar_today_rounded,
                        delay: 200,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Next Appointment',
                        value: upcoming.isNotEmpty
                            ? upcoming.first.startTime.format(context)
                            : 'None',
                        icon: Icons.schedule_rounded,
                        delay: 300,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Section header — Barbers
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Our Barbers',
                      style: AppTypography.heading1,
                    ).animate(delay: 350.ms).fadeIn(duration: 500.ms),
                    TextButton.icon(
                      onPressed: () => context.go(AppRoutes.barberSelection),
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('Book Now'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.goldPrimary,
                      ),
                    ).animate(delay: 350.ms).fadeIn(duration: 500.ms),
                  ],
                ),
              ),
            ),

            // Barber horizontal list
            SliverToBoxAdapter(
              child: SizedBox(
                height: 230,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: barbers.length,
                  itemBuilder: (context, index) {
                    return _BarberCard(
                      barber: barbers[index],
                      index: index,
                      onTap: () {
                        ref.read(bookingFlowProvider.notifier).state =
                            BookingFlowState(selectedBarber: barbers[index]);
                        context.go(AppRoutes.barberSelection);
                      },
                    );
                  },
                ),
              ),
            ),

            // Upcoming Booking
            if (upcoming.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                  child: Text(
                    'Upcoming Appointment',
                    style: AppTypography.heading1,
                  ).animate(delay: 500.ms).fadeIn(duration: 400.ms),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _UpcomingBookingCard(booking: upcoming.first),
                ),
              ),
            ],

            // Quick actions row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Text(
                  'Quick Actions',
                  style: AppTypography.heading1,
                ).animate(delay: 550.ms).fadeIn(duration: 400.ms),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _QuickAction(
                      icon: Icons.event_available_rounded,
                      label: 'Book Now',
                      color: AppColors.goldPrimary,
                      onTap: () => context.go(AppRoutes.barberSelection),
                      delay: 600,
                    ),
                    const SizedBox(width: 12),
                    _QuickAction(
                      icon: Icons.history_rounded,
                      label: 'History',
                      color: AppColors.successGreen,
                      onTap: () => context.go(AppRoutes.bookingHistory),
                      delay: 700,
                    ),
                    const SizedBox(width: 12),
                    _QuickAction(
                      icon: Icons.star_rounded,
                      label: 'Reviews',
                      color: const Color(0xFF5B8DEF),
                      onTap: () => context.go(AppRoutes.profile),
                      delay: 800,
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
      bottomNavigationBar: _CustomerBottomNav(currentIndex: 0),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}

/// Premium header with gradient overlay
class _HomeHeader extends ConsumerWidget {
  final UserModel? user;
  final String greeting;
  final bool hasUpcoming;

  const _HomeHeader({
    required this.user,
    required this.greeting,
    required this.hasUpcoming,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.colors.surface, context.colors.surface.withAlpha(200)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colors.borderGold, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldShadow.withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          AvatarCircle(name: user?.name ?? 'User', radius: 26).animate().scale(
            begin: const Offset(0.5, 0.5),
            end: const Offset(1.0, 1.0),
            curve: Curves.elasticOut,
            duration: 800.ms,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: AppTypography.caption.copyWith(
                    color: context.colors.textMuted,
                    fontSize: 13,
                  ),
                ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
                Text(
                      user?.name.split(' ').first ?? 'Guest',
                      style: AppTypography.heading1.copyWith(fontSize: 22),
                    )
                    .animate(delay: 150.ms)
                    .fadeIn(duration: 400.ms)
                    .slideX(begin: 0.1, end: 0),
                if (hasUpcoming)
                  Text(
                    'You have an upcoming appointment',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.goldPrimary,
                      fontSize: 11,
                    ),
                  ).animate(delay: 250.ms).fadeIn(duration: 400.ms),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: context.colors.surface2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: context.colors.borderDefault,
                width: 0.5,
              ),
            ),
            child: IconButton(
              icon: Icon(context.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
              color: context.colors.textMuted,
              iconSize: 20,
              onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            ),
          ),
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.colors.surface2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: context.colors.borderDefault,
                    width: 0.5,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  color: context.colors.textMuted,
                  iconSize: 20,
                  onPressed: () {},
                ),
              ),
              if (hasUpcoming)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.goldPrimary,
                    ),
                  ),
                ),
            ],
          ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
        ],
      ),
    );
  }
}

/// Stat card
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final int delay;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.goldDim,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: AppColors.goldPrimary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: AppTypography.heading2.copyWith(
                        color: AppColors.goldPrimary,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      label,
                      style: AppTypography.caption.copyWith(
                        color: context.colors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
  }
}

/// Premium barber card with availability indicator
class _BarberCard extends StatefulWidget {
  final BarberModel barber;
  final int index;
  final VoidCallback onTap;

  const _BarberCard({
    required this.barber,
    required this.index,
    required this.onTap,
  });

  @override
  State<_BarberCard> createState() => _BarberCardState();
}

class _BarberCardState extends State<_BarberCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.96 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: Container(
              width: 148,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: AppRadius.cardBorder,
                border: Border.all(color: context.colors.borderDefault, width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(40),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  // Avatar with golden ring
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.goldPrimary.withAlpha(80),
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Chair icon background
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.colors.surface2,
                          ),
                          child: Icon(
                            Icons.chair_alt_rounded,
                            size: 30,
                            color: AppColors.goldPrimary.withAlpha(180),
                          ),
                        ),
                        // Initials on top
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.colors.surface2.withAlpha(0),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),
                  Text(
                    widget.barber.name.split(' ').first,
                    style: AppTypography.bodyBold.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.barber.experienceYears}y experience',
                    style: AppTypography.caption.copyWith(
                      color: context.colors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: AppColors.goldPrimary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        widget.barber.rating.toStringAsFixed(1),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.goldLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        ' (${widget.barber.reviewCount})',
                        style: AppTypography.caption.copyWith(
                          color: context.colors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.successGreen,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Available',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.successGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        )
        .animate(delay: Duration(milliseconds: 400 + widget.index * 100))
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
  }
}

/// Upcoming booking card
class _UpcomingBookingCard extends StatelessWidget {
  final BookingModel booking;

  const _UpcomingBookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.goldDim.withAlpha(50),
                context.colors.surface,
              ],
            ),
            borderRadius: AppRadius.cardBorder,
            border: Border.all(color: context.colors.borderGold, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Date box
                Container(
                  width: 64,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.goldPrimary.withAlpha(30),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.goldPrimary.withAlpha(80),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateHelpers.formatDateShort(
                          booking.date,
                        ).split(' ').first,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.goldLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${booking.date.day}',
                        style: AppTypography.heading1.copyWith(
                          color: AppColors.goldPrimary,
                          fontSize: 22,
                        ),
                      ),
                      Text(
                        booking.startTime.format(context),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.goldPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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
                        booking.serviceNames.join(', '),
                        style: AppTypography.bodyBold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateHelpers.formatDateFull(booking.date),
                        style: AppTypography.caption.copyWith(
                          color: context.colors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${booking.totalPrice.toStringAsFixed(0)} · ${booking.totalDurationMinutes}min',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.goldLight,
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
          ),
        )
        .animate(delay: 500.ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
  }
}

/// Quick action button
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int delay;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withAlpha(60), width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: AppTypography.caption.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
  }
}

/// Customer Bottom Nav
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
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_outlined),
            activeIcon: Icon(Icons.event_rounded),
            label: 'Book',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
