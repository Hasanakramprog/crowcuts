import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_extension.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/router/app_router.dart';
import '../../../data/providers/booking_provider.dart';
import '../../../data/providers/barber_provider.dart';
import '../../../data/providers/income_provider.dart';
import '../../../data/models/models.dart';
import '../../../core/utils/date_helpers.dart';

/// Period enum for accounting filter
enum AccountingPeriod { today, thisWeek, thisMonth, thisYear, custom }

/// Admin — Accounting Overview with Charts and Breakdowns
class AccountingOverviewScreen extends ConsumerStatefulWidget {
  const AccountingOverviewScreen({super.key});

  @override
  ConsumerState<AccountingOverviewScreen> createState() =>
      _AccountingOverviewScreenState();
}

class _AccountingOverviewScreenState
    extends ConsumerState<AccountingOverviewScreen> {
  AccountingPeriod _selectedPeriod = AccountingPeriod.thisMonth;
  DateTime? _customStart;
  DateTime? _customEnd;

  List<IncomeRecord> _getFilteredRecords(IncomeNotifier notifier) {
    switch (_selectedPeriod) {
      case AccountingPeriod.today:
        return notifier.getTodayIncome();
      case AccountingPeriod.thisWeek:
        return notifier.getThisWeekIncome();
      case AccountingPeriod.thisMonth:
        return notifier.getThisMonthIncome();
      case AccountingPeriod.thisYear:
        return notifier.getThisYearIncome();
      case AccountingPeriod.custom:
        if (_customStart != null && _customEnd != null) {
          return notifier.getIncomeForRange(_customStart!, _customEnd!);
        }
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final incomeNotifier = ref.read(incomeProvider.notifier);
    final records = _getFilteredRecords(incomeNotifier);
    final allBarbers = ref.watch(barbersProvider);

    final totalIncome = incomeNotifier.calculateTotal(records);
    final serviceBreakdown = incomeNotifier.breakdownByService(records);
    final barberBreakdown = incomeNotifier.breakdownByBarber(records);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(title: const Text('Accounting')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period tabs
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: AccountingPeriod.values.map((period) {
                  final isSelected = _selectedPeriod == period;
                  final label = period.name
                      .replaceAllMapped(
                          RegExp(r'[A-Z]'), (m) => ' ${m.group(0)}')
                      .trim();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedPeriod = period);
                        if (period == AccountingPeriod.custom) {
                          _pickCustomRange();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.goldDim.withAlpha(40)
                              : context.colors.surface2,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? context.colors.borderGold
                                : context.colors.borderDefault,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          period == AccountingPeriod.custom
                              ? 'Custom'
                              : label,
                          style: AppTypography.caption.copyWith(
                            color: isSelected
                                ? (context.isDark ? AppColors.goldPrimary : context.colors.textPrimary)
                                : context.colors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Main income card
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Income',
                    style: AppTypography.caption.copyWith(
                      color: context.colors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${totalIncome.toStringAsFixed(2)}',
                    style: AppTypography.display.copyWith(
                      color: AppColors.goldPrimary,
                      fontSize: 36,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${records.length} appointments',
                    style: AppTypography.caption.copyWith(
                      color: context.colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Service breakdown
            Text(
              'Service Breakdown',
              style: AppTypography.heading1,
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.2,
              children: serviceBreakdown.entries.map((entry) {
                return AppCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        entry.key,
                        style: AppTypography.caption.copyWith(
                          color: context.colors.textMuted,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${entry.value.toStringAsFixed(2)}',
                        style: AppTypography.price.copyWith(
                          color: AppColors.goldPrimary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            if (serviceBreakdown.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'No data for this period',
                  style: AppTypography.body.copyWith(
                    color: context.colors.textMuted,
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Barber breakdown
            Text(
              'Barber Breakdown',
              style: AppTypography.heading1,
            ),
            const SizedBox(height: 12),
            ...barberBreakdown.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.goldDim,
                        child: Text(
                          entry.key[0],
                          style: AppTypography.caption.copyWith(
                            color: AppColors.goldPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(entry.key, style: AppTypography.bodyBold),
                      ),
                      Text(
                        '\$${entry.value.toStringAsFixed(2)}',
                        style: AppTypography.price.copyWith(
                          color: AppColors.goldPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (barberBreakdown.isEmpty)
              Text(
                'No data for this period',
                style: AppTypography.body.copyWith(
                  color: context.colors.textMuted,
                ),
              ),
            const SizedBox(height: 24),

            // Export button
            AppButton(
              label: 'Export Report',
              icon: Icons.download_outlined,
              onPressed: () => context.go(AppRoutes.adminExport),
              width: double.infinity,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: context.isDark
                ? const ColorScheme.dark(primary: AppColors.goldPrimary)
                : const ColorScheme.light(primary: AppColors.goldPrimary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _customStart = picked.start;
        _customEnd = picked.end;
      });
    }
  }
}
