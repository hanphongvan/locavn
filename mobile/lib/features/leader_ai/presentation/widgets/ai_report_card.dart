import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'leader_ai_palette.dart';

/// Card báo cáo Markdown từ AI Gateway. Section 7 yêu cầu nút "Sao chép báo cáo".
class AiReportCard extends StatelessWidget {
  const AiReportCard({super.key, required this.markdown});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LeaderAiPalette.cardRadius),
        side: const BorderSide(color: LeaderAiPalette.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            MarkdownBody(
              data: markdown,
              shrinkWrap: true,
              styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                h1: theme.textTheme.titleMedium?.copyWith(
                  color: LeaderAiPalette.primaryNavy,
                  fontWeight: FontWeight.w800,
                ),
                h2: theme.textTheme.titleSmall?.copyWith(
                  color: LeaderAiPalette.primaryNavy,
                  fontWeight: FontWeight.w700,
                ),
                p: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                listBullet:
                    theme.textTheme.bodyMedium?.copyWith(color: Colors.black87),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: markdown));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã sao chép báo cáo'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Sao chép báo cáo'),
                style: TextButton.styleFrom(
                  foregroundColor: LeaderAiPalette.primaryNavy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
