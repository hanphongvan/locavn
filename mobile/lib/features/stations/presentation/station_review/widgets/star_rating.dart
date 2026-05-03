import 'package:flutter/material.dart';

import '../station_review_compose_theme.dart';

const Map<int, String> kStationStarLabels = {
  1: 'Rất không hài lòng',
  2: 'Không hài lòng',
  3: 'Bình thường',
  4: 'Hài lòng',
  5: 'Rất hài lòng',
};

/// Sao lớn (1–5), [rating] đến khi người dùng chọn.
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.rating,
    required this.onRatingChanged,
  });

  final int? rating;
  final ValueChanged<int> onRatingChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = rating;
    const starSize = 52.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = _boundedWidth(context, constraints.maxWidth);

        Widget starButton(int value, bool selected) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onRatingChanged(value),
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: AnimatedScale(
                    scale: selected ? 1.08 : 1.0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      selected ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: starSize,
                      color: selected
                          ? StationReviewComposeTheme.starSelected
                          : StationReviewComposeTheme.starUnselected,
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        final row = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (i) {
            final value = i + 1;
            final selected = r != null && value <= r;
            return starButton(value, selected);
          }),
        );

        return Column(
          children: [
            SizedBox(
              width: maxW,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: row,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: maxW,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  r == null ? '— / 5' : '$r.0 / 5',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: r == null ? StationReviewComposeTheme.textSecondary : StationReviewComposeTheme.accent,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: maxW,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  r == null ? 'Chạm vào ngôi sao để chọn mức độ' : (kStationStarLabels[r] ?? ''),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: r == null ? StationReviewComposeTheme.textSecondary : StationReviewComposeTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// [LayoutBuilder] đôi khi nhận maxWidth không hữu hạn; cần giá trị hữu hạn để [FittedBox]/[Text] không tràn ngang.
  static double _boundedWidth(BuildContext context, double layoutMaxWidth) {
    if (layoutMaxWidth.isFinite && layoutMaxWidth > 0) {
      return layoutMaxWidth;
    }
    final mq = MediaQuery.sizeOf(context).width;
    return mq.isFinite && mq > 0 ? mq : 320;
  }
}
