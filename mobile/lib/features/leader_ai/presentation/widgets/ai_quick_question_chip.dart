import 'package:flutter/material.dart';

import 'leader_ai_palette.dart';

/// Danh sách 5 câu hỏi mẫu Section 18 — hiện horizontal scroll khi chưa có message nào.
const kLeaderAiQuickQuestions = <String>[
  'Tồn kho xăng dầu toàn quốc hôm nay thế nào?',
  'Doanh nghiệp nào có tồn kho xăng thấp nhất?',
  'Giá RON95 trong 3 kỳ gần nhất biến động ra sao?',
  'Hiển thị tỉnh có mật độ cây xăng thấp.',
  'Tạo báo cáo nhanh tình hình tồn kho cho lãnh đạo.',
];

class AiQuickQuestionRow extends StatelessWidget {
  const AiQuickQuestionRow({super.key, required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: kLeaderAiQuickQuestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final q = kLeaderAiQuickQuestions[i];
          return _Chip(
            text: q,
            onTap: () => onSelected(q),
            primary: true,
          );
        },
      ),
    );
  }
}

/// Hàng "Câu hỏi gợi ý" sau mỗi response AI — màu nhạt phân biệt với quick questions.
class AiSuggestedQuestionsRow extends StatelessWidget {
  const AiSuggestedQuestionsRow({
    super.key,
    required this.suggestions,
    required this.onSelected,
  });

  final List<String> suggestions;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Text(
              'Gợi ý câu hỏi tiếp theo',
              style: TextStyle(
                color: LeaderAiPalette.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: suggestions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                return _Chip(
                  text: suggestions[i],
                  onTap: () => onSelected(suggestions[i]),
                  primary: false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.text,
    required this.onTap,
    required this.primary,
  });

  final String text;
  final VoidCallback onTap;

  /// `true` cho quick questions (border navy), `false` cho suggestions (nền nhạt).
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primary ? Colors.white : LeaderAiPalette.softBlue,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: primary
              ? LeaderAiPalette.primaryNavy.withValues(alpha: 0.4)
              : LeaderAiPalette.borderLight,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            text,
            style: const TextStyle(
              color: LeaderAiPalette.primaryNavy,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
