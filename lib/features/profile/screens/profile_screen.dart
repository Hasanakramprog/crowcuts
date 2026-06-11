import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_extension.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/router/app_router.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/booking_provider.dart';
import '../../../data/models/models.dart';
import '../../../core/utils/date_helpers.dart';

/// Helper: converts UserRole enum to a display label string
String _roleLabel(UserRole? role) {
  switch (role) {
    case UserRole.admin:
      return 'ADMIN';
    case UserRole.barber:
      return 'BARBER';
    case UserRole.customer:
    default:
      return 'CUSTOMER';
  }
}

/// Customer Profile Screen — Premium design with theme toggle
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final bookings = ref.watch(bookingProvider);
    final themeMode = ref.watch(themeModeProvider);
    final c = context.colors;

    // Stats for the customer
    final customerBookings = user != null
        ? bookings.where((b) => b.customerId == user.id).toList()
        : <BookingModel>[];
    final completedCount = customerBookings
        .where((b) => b.status == BookingStatus.completed)
        .length;
    final cancelledCount = customerBookings
        .where((b) => b.status == BookingStatus.cancelled)
        .length;
    final upcomingCount = customerBookings
        .where(
          (b) =>
              (b.status == BookingStatus.confirmed ||
                  b.status == BookingStatus.pending) &&
              b.date.isAfter(DateTime.now()),
        )
        .length;

    final initials = (user?.name ?? 'U')
        .split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Profile header
            SliverToBoxAdapter(
              child: _ProfileHeader(
                user: user,
                initials: initials,
                onLogout: () {
                  ref.read(authProvider.notifier).logout();
                  context.go(AppRoutes.login);
                },
              ),
            ),

            // Stats row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Row(
                  children: [
                    _StatPill(
                      value: '$completedCount',
                      label: 'Completed',
                      color: AppColors.successGreen,
                      delay: 300,
                    ),
                    const SizedBox(width: 10),
                    _StatPill(
                      value: '$upcomingCount',
                      label: 'Upcoming',
                      color: AppColors.goldPrimary,
                      delay: 400,
                    ),
                    const SizedBox(width: 10),
                    _StatPill(
                      value: '$cancelledCount',
                      label: 'Cancelled',
                      color: AppColors.errorRed,
                      delay: 500,
                    ),
                  ],
                ),
              ),
            ),

            // Account Info section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'Account Info',
                  style: AppTypography.heading1.copyWith(color: c.textPrimary),
                ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _InfoTile(
                      icon: Icons.person_outline_rounded,
                      label: 'Full Name',
                      value: user?.name ?? '—',
                      delay: 450,
                    ),
                    const SizedBox(height: 8),
                    _InfoTile(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: user?.email ?? '—',
                      delay: 500,
                    ),
                    const SizedBox(height: 8),
                    _InfoTile(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: user?.phone ?? '—',
                      delay: 550,
                    ),
                    const SizedBox(height: 8),
                    _InfoTile(
                      icon: Icons.calendar_month_outlined,
                      label: 'Member Since',
                      value: user != null
                          ? DateHelpers.formatDateFull(user.createdAt)
                          : '—',
                      delay: 600,
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Appearance section ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'Appearance',
                  style: AppTypography.heading1.copyWith(color: c.textPrimary),
                ).animate(delay: 620.ms).fadeIn(duration: 400.ms),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AppCard(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.goldDim,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isDark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          size: 20,
                          color: AppColors.goldPrimary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Theme',
                              style: AppTypography.caption.copyWith(
                                color: c.textMuted,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              isDark ? 'Dark Mode' : 'Light Mode',
                              style: AppTypography.body
                                  .copyWith(color: c.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      Transform.scale(
                        scale: 0.85,
                        child: Switch(
                          value: isDark,
                          onChanged: (_) {
                            ref
                                .read(themeModeProvider.notifier)
                                .toggle();
                          },
                          activeColor: AppColors.goldPrimary,
                          activeTrackColor:
                              AppColors.goldPrimary.withAlpha(60),
                          inactiveThumbColor: c.textMuted,
                          inactiveTrackColor: c.surface2,
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: 640.ms).fadeIn(duration: 400.ms),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Logout
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AppButton(
                  label: 'Log Out',
                  isOutlined: true,
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                    context.go(AppRoutes.login);
                  },
                  width: double.infinity,
                ).animate(delay: 700.ms).fadeIn(duration: 400.ms),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
      bottomNavigationBar: _CustomerBottomNav(currentIndex: 3),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserModel? user;
  final String initials;
  final VoidCallback onLogout;

  const _ProfileHeader({
    required this.user,
    required this.initials,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = context.isDark;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.surface2, c.surface],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.borderGold, width: 1),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: AppColors.goldShadow.withAlpha(40),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : c.cardShadow,
      ),
      child: Column(
        children: [
          // Avatar
          Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [AppColors.goldDim, c.surface],
                  ),
                  border: Border.all(color: AppColors.goldPrimary, width: 2),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: AppTypography.display.copyWith(
                      color: AppColors.goldPrimary,
                      fontSize: 28,
                    ),
                  ),
                ),
              )
              .animate()
              .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1.0, 1.0),
                curve: Curves.elasticOut,
                duration: 900.ms,
              )
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 14),

          Text(
            user?.name ?? 'User',
            style:
                AppTypography.heading1.copyWith(fontSize: 20, color: c.textPrimary),
          ).animate(delay: 150.ms).fadeIn(duration: 400.ms),

          const SizedBox(height: 4),

          Text(
            user?.email ?? '',
            style: AppTypography.caption.copyWith(color: c.textMuted),
          ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

          const SizedBox(height: 12),

          Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.goldDim,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.goldPrimary.withAlpha(80),
                  ),
                ),
                child: Text(
                  _roleLabel(user?.role),
                  style: AppTypography.label.copyWith(
                    color: AppColors.goldPrimary,
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
              )
              .animate(delay: 250.ms)
              .fadeIn(duration: 400.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
                curve: Curves.elasticOut,
              ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final int delay;

  const _StatPill({
    required this.value,
    required this.label,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withAlpha(60), width: 1),
            ),
            child: Column(
              children: [
                Text(
                  value,
                  style: AppTypography.heading1.copyWith(color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: c.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final int delay;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.goldDim,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: AppColors.goldPrimary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.caption.copyWith(
                        color: c.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      value,
                      style: AppTypography.body.copyWith(color: c.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 400.ms)
        .slideX(begin: -0.1, end: 0, curve: Curves.easeOutCubic);
  }
}

class _DemoRoleSwitcher extends ConsumerWidget {
  final UserModel? user;

  const _DemoRoleSwitcher({required this.user});

  void _switchRole(BuildContext context, WidgetRef ref, UserRole target) {
    ref.read(authProvider.notifier).switchRole(target);
    final route = switch (target) {
      UserRole.barber => AppRoutes.barberDashboard,
      UserRole.admin => AppRoutes.adminHome,
      UserRole.customer => AppRoutes.customerHome,
    };
    context.go(route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.borderGold, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.goldDim,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  size: 18,
                  color: AppColors.goldPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Demo Role Switcher',
                style: AppTypography.label.copyWith(
                  color: AppColors.goldPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Tap to switch views for the demo presentation:',
            style: AppTypography.caption.copyWith(
              color: c.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _RoleButton(
                label: 'Customer',
                icon: Icons.person_rounded,
                isActive: user?.role == UserRole.customer,
                color: const Color(0xFF5B8DEF),
                onTap: () => _switchRole(context, ref, UserRole.customer),
              ),
              const SizedBox(width: 8),
              _RoleButton(
                label: 'Barber',
                icon: Icons.content_cut_rounded,
                isActive: user?.role == UserRole.barber,
                color: AppColors.successGreen,
                onTap: () => _switchRole(context, ref, UserRole.barber),
              ),
              const SizedBox(width: 8),
              _RoleButton(
                label: 'Admin',
                icon: Icons.admin_panel_settings_rounded,
                isActive: user?.role == UserRole.admin,
                color: AppColors.goldPrimary,
                onTap: () => _switchRole(context, ref, UserRole.admin),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _RoleButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? color.withAlpha(30) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? color : c.borderDefault,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? color : c.textMuted,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: isActive ? color : c.textMuted,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Customer Bottom Nav
class _CustomerBottomNav extends StatelessWidget {
  final int currentIndex;

  const _CustomerBottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: c.borderDefault, width: 0.5),
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
