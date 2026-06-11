import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_extension.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/rating_provider.dart';

/// Barber Reviews Screen
class BarberReviewsScreen extends ConsumerWidget {
  const BarberReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final barberId = authState.user?.barberId ?? 'barber-1';
    final ratings = ref.read(ratingProvider.notifier).getRatingsForBarber(barberId);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(title: const Text('My Reviews')),
      body: ratings.isEmpty
          ? Center(
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
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: ratings.length,
              itemBuilder: (context, index) {
                final rating = ratings[index];
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
                                final half =
                                    i == rating.stars.floor() &&
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
            ),
    );
  }
}
