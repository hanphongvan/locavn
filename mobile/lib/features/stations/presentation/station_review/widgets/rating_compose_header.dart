import 'package:flutter/material.dart';

import '../station_review_compose_theme.dart';

class RatingComposeHeader extends StatelessWidget {
  const RatingComposeHeader({
    super.key,
    required this.onBack,
    this.backEnabled = true,
  });

  final VoidCallback onBack;
  final bool backEnabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Đánh giá cây xăng',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: StationReviewComposeTheme.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  'Ý kiến của bạn giúp cộng đồng có trải nghiệm tốt hơn',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: StationReviewComposeTheme.textSecondary,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: StationReviewComposeTheme.primary.withValues(alpha: 0.08),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: IconButton(
                onPressed: backEnabled ? onBack : null,
                icon: const Icon(Icons.arrow_back_rounded),
                color: StationReviewComposeTheme.primary,
                tooltip: 'Quay lại',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
