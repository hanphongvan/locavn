import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import 'leader_ai_api.dart';
import 'leader_ai_models.dart';

/// State của màn chat — immutable. Pattern giống `LeaderRetailState`.
@immutable
class LeaderAiChatState {
  const LeaderAiChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isStreaming = false,
    this.streamingText = '',
    this.conversationId,
    this.rateLimitInfo,
    this.suggestedQuestions = const [],
    this.errorMessage,
  });

  final List<AiMessageUiModel> messages;
  final bool isLoading; // request đang chạy (gồm streaming).
  final bool isStreaming; // đang nhận text_delta events từ server.
  final String streamingText;
  final String? conversationId;
  final AiRateLimitInfo? rateLimitInfo;
  final List<String> suggestedQuestions;
  final String? errorMessage;

  bool get hasMessages => messages.isNotEmpty;

  LeaderAiChatState copyWith({
    List<AiMessageUiModel>? messages,
    bool? isLoading,
    bool? isStreaming,
    String? streamingText,
    String? conversationId,
    bool clearConversationId = false,
    AiRateLimitInfo? rateLimitInfo,
    List<String>? suggestedQuestions,
    String? errorMessage,
    bool clearError = false,
  }) =>
      LeaderAiChatState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        isStreaming: isStreaming ?? this.isStreaming,
        streamingText: streamingText ?? this.streamingText,
        conversationId:
            clearConversationId ? null : (conversationId ?? this.conversationId),
        rateLimitInfo: rateLimitInfo ?? this.rateLimitInfo,
        suggestedQuestions: suggestedQuestions ?? this.suggestedQuestions,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

/// Controller chat. Riverpod `Notifier<LeaderAiChatState>` — replace bởi
/// `AsyncNotifier` ở Phase 3 nếu cần error/loading wrapping built-in.
class LeaderAiChatController extends Notifier<LeaderAiChatState> {
  StreamSubscription<AiSseEvent>? _streamSub;

  @override
  LeaderAiChatState build() {
    ref.onDispose(() {
      _streamSub?.cancel();
    });
    return const LeaderAiChatState();
  }

  /// Gửi câu hỏi — dùng SSE stream để UI hiển thị text dần dần.
  /// Khi `useStream = false` thì gọi /chat thường (Phase 2B fallback nếu SSE fail).
  Future<void> sendMessage(
    String text, {
    LeaderAiChatContext? context,
    bool useStream = true,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isLoading) return;

    final api = ref.read(leaderAiApiProvider);
    final userMsg = AiMessageUiModel(
      id: 'u-${DateTime.now().microsecondsSinceEpoch}',
      isUser: true,
      text: trimmed,
      createdAt: DateTime.now(),
    );
    final placeholderId = 'a-${DateTime.now().microsecondsSinceEpoch}';
    final placeholder = AiMessageUiModel(
      id: placeholderId,
      isUser: false,
      text: '',
      createdAt: DateTime.now(),
      isStreaming: useStream,
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg, placeholder],
      isLoading: true,
      isStreaming: useStream,
      streamingText: '',
      suggestedQuestions: const [],
      clearError: true,
    );

    final request = LeaderAiChatRequest(
      message: trimmed,
      conversationId: state.conversationId,
      context: context,
    );

    try {
      if (useStream) {
        await _consumeStream(api, request, placeholderId);
      } else {
        final response = await api.sendChat(request);
        _applyCompleteResponse(response, placeholderId);
      }
    } on ApiException catch (e) {
      _onFailure(e.toString(), placeholderId);
    } catch (e) {
      debugPrint('[leader-ai] sendMessage error: $e');
      _onFailure('Hệ thống AI tạm thời không khả dụng. Vui lòng thử lại sau.', placeholderId);
    }
  }

  /// Reset chat — tạo conversation mới ở lần gửi tiếp theo.
  void newConversation() {
    _streamSub?.cancel();
    state = const LeaderAiChatState();
  }

  Future<void> _consumeStream(
    LeaderAiApi api,
    LeaderAiChatRequest request,
    String placeholderId,
  ) async {
    final completer = Completer<void>();
    final buffer = StringBuffer();

    _streamSub?.cancel();
    _streamSub = api.streamChat(request).listen(
      (event) {
        switch (event) {
          case AiSseTextDelta(:final text):
            buffer.write(text);
            final updated = buffer.toString();
            state = state.copyWith(
              streamingText: updated,
              messages: _replaceMessage(
                placeholderId,
                (m) => m.copyWith(text: updated, isStreaming: true),
              ),
            );
          case AiSseComplete(:final response):
            _applyCompleteResponse(response, placeholderId);
          case AiSseError(:final message):
            _onFailure(message, placeholderId);
        }
      },
      onError: (Object e, StackTrace st) {
        debugPrint('[leader-ai] sse onError: $e');
        _onFailure(
          'Hệ thống AI tạm thời không khả dụng. Vui lòng thử lại sau.',
          placeholderId,
        );
        if (!completer.isCompleted) completer.complete();
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete();
      },
      cancelOnError: true,
    );

    await completer.future;
  }

  void _applyCompleteResponse(LeaderAiChatResponse response, String placeholderId) {
    state = state.copyWith(
      messages: _replaceMessage(
        placeholderId,
        (m) => m.copyWith(
          text: response.answerText,
          intent: response.intent,
          data: response.data,
          isStreaming: false,
        ),
      ),
      isLoading: false,
      isStreaming: false,
      streamingText: '',
      conversationId:
          response.conversationId.isEmpty ? state.conversationId : response.conversationId,
      rateLimitInfo: response.rateLimitInfo,
      suggestedQuestions: response.suggestedQuestions,
      clearError: true,
    );
  }

  void _onFailure(String message, String placeholderId) {
    state = state.copyWith(
      messages: _replaceMessage(
        placeholderId,
        (m) => m.copyWith(
          text: message,
          isStreaming: false,
        ),
      ),
      isLoading: false,
      isStreaming: false,
      streamingText: '',
      errorMessage: message,
    );
  }

  List<AiMessageUiModel> _replaceMessage(
    String id,
    AiMessageUiModel Function(AiMessageUiModel) transform,
  ) {
    final list = state.messages;
    final idx = list.indexWhere((m) => m.id == id);
    if (idx < 0) return list;
    final next = [...list];
    next[idx] = transform(list[idx]);
    return next;
  }
}

final leaderAiChatControllerProvider =
    NotifierProvider<LeaderAiChatController, LeaderAiChatState>(
  LeaderAiChatController.new,
);

/// Async list conversations — dùng cho menu lịch sử (Phase 3+).
final leaderAiConversationsProvider =
    FutureProvider.autoDispose<List<AiConversationDto>>((ref) async {
  final api = ref.watch(leaderAiApiProvider);
  return api.getConversations();
});
