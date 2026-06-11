import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_extension.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';

/// Admin — Accounting Export Screen (PDF + CSV)
class AccountingExportScreen extends ConsumerWidget {
  const AccountingExportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(title: const Text('Export Report')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Icon(
              Icons.assessment_outlined,
              size: 64,
              color: AppColors.goldPrimary,
            ),
            const SizedBox(height: 24),
            Text(
              'Export Income Report',
              style: AppTypography.heading1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a format to export your accounting data.',
              style: AppTypography.body.copyWith(
                color: context.colors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // PDF Export
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf,
                      color: AppColors.errorRed,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PDF Report', style: AppTypography.bodyBold),
                        Text(
                          'Formatted report with charts',
                          style: AppTypography.caption.copyWith(
                            color: context.colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download),
                    color: AppColors.goldPrimary,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('PDF export (demo — Phase 2)'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // CSV Export
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.table_chart_outlined,
                      color: AppColors.successGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CSV Export', style: AppTypography.bodyBold),
                        Text(
                          'Raw data rows for spreadsheets',
                          style: AppTypography.caption.copyWith(
                            color: context.colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download),
                    color: AppColors.goldPrimary,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('CSV export (demo — Phase 2)'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Text(
              'Note: Export functionality is a preview in this demo.\n'
              'Full PDF and CSV generation coming in Phase 2.',
              style: AppTypography.caption.copyWith(
                color: context.colors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
