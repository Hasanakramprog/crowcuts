import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_extension.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/providers/booking_provider.dart';
import '../../../data/providers/rating_provider.dart';
import '../../../data/providers/barber_provider.dart';
import '../../../data/models/models.dart';

/// Rating Screen — Star rating after completed booking
class RatingScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const RatingScreen({super.key, required this.bookingId});

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  double _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final booking =
        ref.read(bookingProvider.notifier).getBookingById(widget.bookingId);

    if (booking == null) return;

    // Create rating
    final rating = RatingModel(
      id: 'rating-${DateTime.now().millisecondsSinceEpoch}',
      bookingId: widget.bookingId,
      customerId: booking.customerId,
      customerName: booking.customerName,
      barberId: booking.barberId,
      stars: _rating,
      comment: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
      createdAt: DateTime.now(),
    );

    ref.read(ratingProvider.notifier).addRating(rating);

    // Mark booking as rated
    ref.read(bookingProvider.notifier).markAsRated(widget.bookingId);

    setState(() => _isSubmitting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Thank you for your review!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking =
        ref.watch(bookingProvider.notifier).getBookingById(widget.bookingId);
    final barber = booking != null
        ? ref.watch(barberProvider(booking.barberId))
        : null;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: context.colors.surface2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Barber info
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.goldDim,
                        child: Text(
                          barber?.name[0] ?? '?',
                          style: AppTypography.display.copyWith(
                            color: AppColors.goldPrimary,
                            fontSize: 36,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        barber?.name ?? 'Barber',
                        style: AppTypography.heading1,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'How was your visit?',
                        style: AppTypography.body.copyWith(
                          color: context.colors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Star selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final starValue = (index + 1).toDouble();
                          final filled = _rating >= starValue;
                          final halfFilled =
                              _rating >= starValue - 0.5 && !filled;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                // Toggle: full star on first tap, half on retap
                                if (_rating == starValue) {
                                  _rating = starValue - 0.5;
                                } else if (_rating == starValue - 0.5) {
                                  _rating = starValue;
                                } else {
                                  _rating = starValue;
                                }
                              });
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                filled
                                    ? Icons.star
                                    : halfFilled
                                        ? Icons.star_half
                                        : Icons.star_border,
                                size: 44,
                                color: filled || halfFilled
                                    ? AppColors.goldPrimary
                                    : context.colors.textMuted,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _rating > 0
                            ? '${_rating.toStringAsFixed(1)} out of 5'
                            : 'Tap a star to rate',
                        style: AppTypography.caption.copyWith(
                          color: context.colors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Comment
                      TextField(
                        controller: _commentController,
                        maxLength: 200,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Share your experience (optional)',
                          hintStyle: AppTypography.body.copyWith(
                            color: context.colors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Buttons
              AppButton(
                label: 'Submit Review',
                isLoading: _isSubmitting,
                onPressed: _rating > 0 ? _submit : null,
                width: double.infinity,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(
                  'Skip',
                  style: AppTypography.body.copyWith(
                    color: context.colors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
