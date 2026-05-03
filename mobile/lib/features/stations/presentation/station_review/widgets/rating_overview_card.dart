import 'package:flutter/material.dart';

import '../station_review_compose_theme.dart';
import 'star_rating.dart';

/// Khối “Đánh giá chung” — bọc [StarRating] trong thẻ trắng.
class RatingOverviewCard extends StatelessWidget {
  const RatingOverviewCard({
    super.key,
    required this.rating,
    required this.onRatingChanged,
  });

  final int? rating;
  final ValueChanged<int> onRatingChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(StationReviewComposeTheme.cardRadius),
        border: Border.all(color: StationReviewComposeTheme.cardBorder.withValues(alpha: 0.65)),
        boxShadow: StationReviewComposeTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Đánh giá chung',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: StationReviewComposeTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            StarRating(
              rating: rating,
              onRatingChanged: onRatingChanged,
            ),
          ],
        ),
      ),
    );
  }
}
