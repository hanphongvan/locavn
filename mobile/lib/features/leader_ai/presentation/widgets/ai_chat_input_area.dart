import 'package:flutter/material.dart';

import 'leader_ai_palette.dart';

/// Input bar dưới cùng — text field + nút gửi. Tự động co theo bàn phím.
class AiChatInputArea extends StatefulWidget {
  const AiChatInputArea({
    super.key,
    required this.onSend,
    required this.isSending,
  });

  final ValueChanged<String> onSend;
  final bool isSending;

  @override
  State<AiChatInputArea> createState() => _AiChatInputAreaState();
}

class _AiChatInputAreaState extends State<AiChatInputArea> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isSending) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = !_hasText || widget.isSending;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submit(),
                enabled: !widget.isSending,
                decoration: InputDecoration(
                  hintText: 'Nhập câu hỏi cho Loca AI...',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:
                        const BorderSide(color: LeaderAiPalette.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:
                        const BorderSide(color: LeaderAiPalette.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                        color: LeaderAiPalette.primaryNavy, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: disabled
                  ? LeaderAiPalette.primaryNavy.withValues(alpha: 0.4)
                  : LeaderAiPalette.primaryNavy,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: disabled ? null : _submit,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: widget.isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
