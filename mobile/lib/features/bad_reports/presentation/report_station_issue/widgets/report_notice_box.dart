import 'package:flutter/material.dart';

/// Light warning / guidance panel (#FFF7E6).
class ReportNoticeBox extends StatelessWidget {
  const ReportNoticeBox({super.key});

  static const Color _bg = Color(0xFFFFF7E6);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFE0B2).withValues(alpha: 0.9),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 22,
              color: Colors.orange.shade800,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Thông tin bạn cung cấp sẽ được gửi tới cơ quan quản lý.\n'
                'Vui lòng cung cấp thông tin chính xác để hỗ trợ xử lý nhanh chóng.',
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.4,
                  color: const Color(0xFF92400E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
