import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_extension.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/providers/barber_scoped_providers.dart';
import '../../../data/models/models.dart';

/// Barber Earnings Summary — powered by Firebase
class BarberEarningsScreen extends ConsumerWidget {
  const BarberEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomeAsync = ref.watch(barberIncomeProvider);
    final allIncome = incomeAsync.maybeWhen(
      data: (records) => records,
      orElse: () => <IncomeRecord>[],
    );

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);

    final barberTodayIncome = allIncome
        .where((r) => r.date.isAfter(todayStart.subtract(const Duration(days: 1))))
        .toList();
    final barberMonthIncome = allIncome
        .where((r) => r.date.isAfter(monthStart.subtract(const Duration(days: 1))))
        .toList();

    final todayTotal = barberTodayIncome.fold<double>(0, (sum, r) => sum + r.amount);
    final monthTotal = barberMonthIncome.fold<double>(0, (sum, r) => sum + r.amount);

    final serviceBreakdown = <String, double>{};
    for (final record in barberMonthIncome) {
      for (final name in record.serviceNames) {
        serviceBreakdown[name] =
            (serviceBreakdown[name] ?? 0) + (record.amount / record.serviceNames.length);
      }
    }

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(title: const Text('My Earnings')),
      body: SingleChildScrollView(
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
                    Formatters.currency(todayTotal),
                    style: AppTypography.priceLarge.copyWith(
                      color: AppColors.goldPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${barberTodayIncome.length} appointment${barberTodayIncome.length != 1 ? 's' : ''}',
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
                    Formatters.currency(monthTotal),
                    style: AppTypography.priceLarge.copyWith(
                      color: AppColors.goldPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${barberMonthIncome.length} appointment${barberMonthIncome.length != 1 ? 's' : ''}',
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
                      Formatters.currency(entry.value),
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
      ),
    );
  }
}
