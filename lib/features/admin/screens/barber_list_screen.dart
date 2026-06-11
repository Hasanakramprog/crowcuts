import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_extension.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';

import '../../../core/widgets/status_badge.dart';
import '../../../core/router/app_router.dart';
import '../../../data/providers/barber_provider.dart';


/// Admin — Barber List with full CRUD (edit, deactivate, activate)
class BarberListScreen extends ConsumerWidget {
  const BarberListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final barbers = ref.watch(barbersProvider);
    final activeCount = barbers.where((b) => b.isActive).length;
    final inactiveCount = barbers.length - activeCount;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Barbers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push(AppRoutes.adminAddBarber),
            tooltip: 'Add Barber',
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats strip
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                _StatChip(
                  label: '${barbers.length}',
                  subtitle: 'Total',
                  color: AppColors.goldPrimary,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: '$activeCount',
                  subtitle: 'Active',
                  color: AppColors.successGreen,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: '$inactiveCount',
                  subtitle: 'Inactive',
                  color: context.colors.textMuted,
                ),
              ],
            ),
          ),

          // Barber list
          Expanded(
            child: barbers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_outline,
                            size: 48, color: context.colors.textMuted.withAlpha(60)),
                        const SizedBox(height: 12),
                        Text('No barbers yet',
                            style: AppTypography.body.copyWith(
                                color: context.colors.textMuted)),
                        const SizedBox(height: 4),
                        Text('Tap + to add your first barber',
                            style: AppTypography.caption.copyWith(
                                color: context.colors.textMuted)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: barbers.length,
                    itemBuilder: (context, index) {
                      final barber = barbers[index];
                      final avatarColor = AppColors.avatarColors[
                          index % AppColors.avatarColors.length];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          onTap: () {
                            context.push(
                              AppRoutes.adminEditBarber.replaceFirst(
                                  ':barberId', barber.id),
                            );
                          },
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: avatarColor.withAlpha(40),
                                    child: Text(
                                      barber.name[0],
                                      style: AppTypography.heading2.copyWith(
                                        color: avatarColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(barber.name,
                                            style: AppTypography.bodyBold),
                                        Text(
                                          '${barber.services.length} services · ${barber.experienceYears} years',
                                          style: AppTypography.caption.copyWith(
                                            color: context.colors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star,
                                          size: 14,
                                          color: AppColors.goldPrimary),
                                      const SizedBox(width: 2),
                                      Text(
                                        barber.rating.toStringAsFixed(1),
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.goldPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  if (!barber.isActive)
                                    StatusBadge(
                                      label: 'Inactive',
                                      color: context.colors.textMuted,
                                    ),
                                ],
                              ),
                              // Service chips
                              if (barber.services.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 28,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: barber.services.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 6),
                                    itemBuilder: (context, i) {
                                      final svc = barber.services[i];
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: context.colors.surface2,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          svc.name,
                                          style: AppTypography.caption.copyWith(
                                            fontSize: 11,
                                            color: context.colors.textMuted,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ).animate()
                          .fadeIn(duration: 300.ms, delay: (index * 80).ms)
                          .slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String subtitle;
  final Color color;

  const _StatChip({
    required this.label,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(40), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.heading2.copyWith(
              color: color,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            subtitle,
            style: AppTypography.caption.copyWith(
              color: context.colors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
