import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/portal_loai.dart';
import '../../../core/auth/role_service.dart';
import '../data/leader_ai_providers.dart';
import 'widgets/ai_chat_bubble.dart';
import 'widgets/ai_chat_input_area.dart';
import 'widgets/ai_quick_question_chip.dart';
import 'widgets/leader_ai_palette.dart';

/// Màn chat Loca AI Leader Assistant (Phase 2B).
///
/// Truy cập chỉ khi `Loai == 6` (PortalLoai.leader). Nếu user khác role mở
/// được route bằng deep link / lịch sử → hiển thị inline access denied widget
/// (đồng pattern với LeaderMainScreen).
class LeaderAiChatScreen extends ConsumerStatefulWidget {
  const LeaderAiChatScreen({super.key});

  @override
  ConsumerState<LeaderAiChatScreen> createState() => _LeaderAiChatScreenState();
}

class _LeaderAiChatScreenState extends ConsumerState<LeaderAiChatScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final loai = ref.watch(
      authSessionControllerProvider.select((c) => c.session?.loai),
    );
    if (!RoleService.isLeaderUser(loai)) {
      return _AccessDeniedView();
    }

    // Auto-scroll khi messages / streaming text đổi.
    ref.listen<LeaderAiChatState>(
      leaderAiChatControllerProvider,
      (prev, next) {
        if ((prev?.messages.length ?? 0) != next.messages.length ||
            (prev?.streamingText ?? '') != next.streamingText) {
          _scrollToBottom();
        }
      },
    );

    final state = ref.watch(leaderAiChatControllerProvider);
    final controller = ref.read(leaderAiChatControllerProvider.notifier);

    return Scaffold(
      backgroundColor: LeaderAiPalette.softBlue.withValues(alpha: 0.4),
      appBar: _buildAppBar(state, controller),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (!state.hasMessages)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: AiQuickQuestionRow(
                  onSelected: (q) => controller.sendMessage(q),
                ),
              ),
            Expanded(
              child: state.hasMessages
                  ? ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: state.messages.length,
                      itemBuilder: (context, i) =>
                          AiChatBubble(message: state.messages[i]),
                    )
                  : _EmptyHint(),
            ),
            if (state.suggestedQuestions.isNotEmpty && !state.isStreaming)
              AiSuggestedQuestionsRow(
                suggestions: state.suggestedQuestions,
                onSelected: (q) => controller.sendMessage(q),
              ),
            AiChatInputArea(
              isSending: state.isLoading,
              onSend: (text) => controller.sendMessage(text),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    LeaderAiChatState state,
    LeaderAiChatController controller,
  ) {
    final rate = state.rateLimitInfo;

    return AppBar(
      backgroundColor: LeaderAiPalette.primaryNavy,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Loca AI',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          Text(
            'Trợ lý dữ liệu điều hành',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white70,
            ),
          ),
        ],
      ),
      actions: [
        if (rate != null && rate.isLow)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: LeaderAiPalette.warningAmber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Còn ${rate.remaining}/${rate.maxPerDay}',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        IconButton(
          tooltip: 'Hội thoại mới',
          icon: const Icon(Icons.add_comment_outlined),
          onPressed: state.hasMessages ? controller.newConversation : null,
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 64,
              color: LeaderAiPalette.primaryNavy,
            ),
            const SizedBox(height: 12),
            Text(
              'Hãy đặt câu hỏi cho Loca AI',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: LeaderAiPalette.primaryNavy,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tồn kho · Giá xăng dầu · Mật độ cây xăng · Báo cáo nhanh',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: LeaderAiPalette.textMuted,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessDeniedView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: LeaderAiPalette.primaryNavy,
        foregroundColor: Colors.white,
        title: const Text('Loca AI'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline_rounded,
                  size: 64, color: LeaderAiPalette.primaryNavy),
              const SizedBox(height: 16),
              Text(
                'Bạn không có quyền sử dụng chức năng này.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Loca AI chỉ dành cho tài khoản lãnh đạo (Loai = ${PortalLoai.leader}).',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: LeaderAiPalette.textMuted,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
