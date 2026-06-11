import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_extension.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/booking_provider.dart';
import '../../../data/providers/income_provider.dart';
import '../../../data/providers/barber_provider.dart';
import '../../../data/models/models.dart';
import '../../../core/theme/theme_provider.dart';

/// Admin Home — Navigation Hub with live stats
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final bookings = ref.watch(bookingProvider);
    final income = ref.watch(incomeProvider);
    final barbers = ref.watch(activeBarbersProvider);

    final today = DateTime.now();
    final todaysBookings = bookings
        .where((b) =>
            DateHelpers.isSameDay(b.date, today) &&
            b.status != BookingStatus.cancelled)
        .length;

    final monthStart = DateTime(today.year, today.month, 1);
    final monthIncome = income.where((r) => r.date.isAfter(monthStart)).toList();
    final monthTotal =
        monthIncome.fold<double>(0, (sum, r) => sum + r.amount);

    final pendingBookings = bookings
        .where((b) =>
            b.status == BookingStatus.confirmed ||
            b.status == BookingStatus.pending)
        .where((b) => b.date.isAfter(today))
        .length;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: _AdminHeader(
                user: user,
                onLogout: () {
                  ref.read(authProvider.notifier).logout();
                  context.go(AppRoutes.login);
                },
              ),
            ),

            // Live stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _LiveStatCard(
                            label: "Today's Bookings",
                            value: '$todaysBookings',
                            icon: Icons.calendar_today_rounded,
                            color: AppColors.goldPrimary,
                            delay: 200,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _LiveStatCard(
                            label: 'Month Income',
                            value: '\$${monthTotal.toStringAsFixed(0)}',
                            icon: Icons.trending_up_rounded,
                            color: AppColors.successGreen,
                            delay: 300,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _LiveStatCard(
                            label: 'Active Barbers',
                            value: '${barbers.length}',
                            icon: Icons.content_cut_rounded,
                            color: const Color(0xFF5B8DEF),
                            delay: 400,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _LiveStatCard(
                            label: 'Pending',
                            value: '$pendingBookings',
                            icon: Icons.pending_actions_rounded,
                            color: AppColors.warningAmber,
                            delay: 500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Section title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Text(
                  'Management',
                  style: AppTypography.heading1,
                ).animate(delay: 550.ms).fadeIn(duration: 400.ms),
              ),
            ),

            // Nav grid
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.05,
                ),
                delegate: SliverChildListDelegate([
                  _AdminTile(
                    icon: Icons.person_outlined,
                    label: 'Barbers',
                    subtitle: 'Manage barber profiles',
                    color: const Color(0xFF5B8DEF),
                    onTap: () => context.push(AppRoutes.adminBarbers),
                    delay: 600,
                  ),
                  _AdminTile(
                    icon: Icons.content_cut_outlined,
                    label: 'Services',
                    subtitle: 'Service catalog',
                    color: AppColors.goldPrimary,
                    onTap: () => context.push(AppRoutes.adminServices),
                    delay: 650,
                  ),
                  _AdminTile(
                    icon: Icons.schedule_outlined,
                    label: 'Working Hours',
                    subtitle: 'Set schedules',
                    color: AppColors.warningAmber,
                    onTap: () => context.push(
                        AppRoutes.adminBarbers),
                    delay: 700,
                  ),
                  _AdminTile(
                    icon: Icons.calendar_today_outlined,
                    label: 'All Bookings',
                    subtitle: 'View & manage',
                    color: AppColors.successGreen,
                    onTap: () => context.push(AppRoutes.adminBookings),
                    delay: 750,
                  ),
                  _AdminTile(
                    icon: Icons.monetization_on_outlined,
                    label: 'Accounting',
                    subtitle: 'Income & reports',
                    color: const Color(0xFF9B59B6),
                    onTap: () => context.push(AppRoutes.adminAccounting),
                    delay: 800,
                  ),
                  _AdminTile(
                    icon: Icons.assessment_outlined,
                    label: 'Export',
                    subtitle: 'PDF & CSV',
                    color: const Color(0xFF1ABC9C),
                    onTap: () => context.push(AppRoutes.adminExport),
                    delay: 850,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminHeader extends ConsumerWidget {
  final UserModel? user;
  final VoidCallback onLogout;

  const _AdminHeader({required this.user, required this.onLogout});

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
            child: const Icon(Icons.admin_panel_settings_rounded,
                color: AppColors.goldPrimary, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Panel',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.goldLight,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  user?.name ?? 'Admin',
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

class _LiveStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int delay;

  const _LiveStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withAlpha(50),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTypography.heading2.copyWith(
                    color: color,
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
        .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic);
  }
}

class _AdminTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final int delay;

  const _AdminTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    required this.delay,
  });

  @override
  State<_AdminTile> createState() => _AdminTileState();
}

class _AdminTileState extends State<_AdminTile> {
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
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.color.withAlpha(50),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: widget.color.withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(widget.icon, color: widget.color, size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                widget.label,
                style: AppTypography.heading2.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                style: AppTypography.caption.copyWith(
                  color: context.colors.textMuted,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.delay))
        .fadeIn(duration: 400.ms)
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1.0, 1.0),
          curve: Curves.easeOutCubic,
        );
  }
}
