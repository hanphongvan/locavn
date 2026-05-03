import 'package:flutter/material.dart';

import '../station_review_compose_theme.dart';

/// Thẻ trạm: ảnh minh họa trái + nội dung phải (chỉ UI — dữ liệu từ caller).
class StationCard extends StatelessWidget {
  const StationCard({
    super.key,
    required this.stationName,
    this.address,
  });

  final String stationName;
  final String? address;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = address?.trim();
    final addrLine = (text == null || text.isEmpty) ? '—' : text;
    final name = stationName.trim().isEmpty ? 'Cây xăng' : stationName.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(StationReviewComposeTheme.cardRadius),
        border: Border.all(color: StationReviewComposeTheme.cardBorder.withValues(alpha: 0.65)),
        boxShadow: StationReviewComposeTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      StationReviewComposeTheme.primary.withValues(alpha: 0.12),
                      StationReviewComposeTheme.accent.withValues(alpha: 0.1),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.local_gas_station_rounded,
                  size: 38,
                  color: StationReviewComposeTheme.primary.withValues(alpha: 0.85),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: StationReviewComposeTheme.textPrimary,
                            height: 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: StationReviewComposeTheme.accent.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Đã chọn',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    addrLine,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: StationReviewComposeTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 18,
                        color: StationReviewComposeTheme.primary.withValues(alpha: 0.75),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Đánh giá công khai',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: StationReviewComposeTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
