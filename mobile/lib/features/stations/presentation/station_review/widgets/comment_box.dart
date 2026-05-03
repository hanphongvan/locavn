import 'package:flutter/material.dart';

import '../station_review_compose_theme.dart';

/// Ô nhận xét + bộ đếm ký tự.
class CommentBox extends StatelessWidget {
  const CommentBox({
    super.key,
    required this.controller,
    required this.maxLength,
  });

  final TextEditingController controller;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nhận xét (tuỳ chọn)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: StationReviewComposeTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final n = value.text.characters.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: controller,
                  minLines: 5,
                  maxLines: 8,
                  maxLength: maxLength,
                  buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                      const SizedBox.shrink(),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: StationReviewComposeTheme.textPrimary,
                    height: 1.45,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Bạn có thể chia sẻ thêm trải nghiệm tại cây xăng này...',
                    hintStyle: TextStyle(
                      color: StationReviewComposeTheme.textSecondary.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(StationReviewComposeTheme.inputRadius),
                      borderSide: const BorderSide(color: StationReviewComposeTheme.inputBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(StationReviewComposeTheme.inputRadius),
                      borderSide: const BorderSide(color: StationReviewComposeTheme.inputBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(StationReviewComposeTheme.inputRadius),
                      borderSide: const BorderSide(
                        color: StationReviewComposeTheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$n/$maxLength',
                  textAlign: TextAlign.right,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: StationReviewComposeTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
