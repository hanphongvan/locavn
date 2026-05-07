import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/leader_ai_models.dart';
import 'ai_chart_card.dart';
import 'ai_map_preview_card.dart';
import 'ai_report_card.dart';
import 'ai_table_card.dart';
import 'leader_ai_palette.dart';

/// Bubble chat — Section 7 yêu cầu navy #1B3A6B cho user, trắng + border cho AI.
///
/// Khi `message.isStreaming = true`: hiện cursor nhấp nháy cuối text.
/// AI bubble có thể render thêm cards (table/chart/map/report) ngay sau.
class AiChatBubble extends StatelessWidget {
  const AiChatBubble({super.key, required this.message});

  final AiMessageUiModel message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.84,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? LeaderAiPalette.primaryNavy : Colors.white,
                border: isUser
                    ? null
                    : Border.all(color: LeaderAiPalette.borderLight),
                borderRadius: BorderRadius.circular(LeaderAiPalette.cardRadius),
                boxShadow: isUser
                    ? null
                    : const [
                        BoxShadow(
                          color: Color(0x140B2F6B),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
              ),
              child: _BubbleText(message: message, isUser: isUser),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('HH:mm').format(message.createdAt.toLocal()),
            style: theme.textTheme.bodySmall?.copyWith(
              color: LeaderAiPalette.textMuted,
              fontSize: 11,
            ),
          ),
          if (!isUser && message.data != null) ...[
            const SizedBox(height: 8),
            ..._buildDataCards(context, message.data!),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildDataCards(BuildContext context, AiChatData data) {
    final cards = <Widget>[];
    if (data.chart != null) {
      cards.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: AiChartCard(chart: data.chart!),
      ));
    }
    if (data.table != null && data.table!.isNotEmpty) {
      cards.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: AiTableCard(rows: data.table!),
      ));
    }
    if (data.map != null) {
      cards.add(const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: AiMapPreviewCard(),
      ));
    }
    if (data.reportMarkdown != null && data.reportMarkdown!.isNotEmpty) {
      cards.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: AiReportCard(markdown: data.reportMarkdown!),
      ));
    }
    return cards;
  }
}

class _BubbleText extends StatefulWidget {
  const _BubbleText({required this.message, required this.isUser});

  final AiMessageUiModel message;
  final bool isUser;

  @override
  State<_BubbleText> createState() => _BubbleTextState();
}

class _BubbleTextState extends State<_BubbleText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cursor;

  @override
  void initState() {
    super.initState();
    _cursor = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cursor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isUser ? LeaderAiPalette.onPrimary : Colors.black87;
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: color,
          height: 1.4,
        );

    if (!widget.message.isStreaming) {
      // AI bubble rỗng (chưa có chunk nào) → hiện 3 dấu chấm.
      if (!widget.isUser && widget.message.text.isEmpty) {
        return _TypingDots();
      }
      return Text(widget.message.text, style: textStyle);
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(widget.message.text, style: textStyle),
        FadeTransition(
          opacity: _cursor,
          child: Container(
            margin: const EdgeInsets.only(left: 2),
            width: 2,
            height: 14,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (t + i * 0.2) % 1.0;
            final scale = 0.6 + 0.4 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: LeaderAiPalette.primaryNavy,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
