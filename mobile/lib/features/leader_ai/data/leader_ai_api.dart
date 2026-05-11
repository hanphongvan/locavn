import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/network/json_utils.dart';
import 'leader_ai_models.dart';

/// HTTP client cho Loca AI Leader (`/api/leader-ai/*`) — Bearer JWT qua
/// `dioProvider` (interceptor tự gắn token).
///
/// SSE stream parser: mỗi event format `data: {...}\n\n` (Section 4.4 tài liệu thiết kế).
/// Phase 2B nhận `text_delta`/`complete`/`error` events.
class LeaderAiApi {
  LeaderAiApi(this._dio);

  final Dio _dio;

  Future<LeaderAiChatResponse> sendChat(LeaderAiChatRequest request) async {
    debugPrint('[leader-ai] api.sendChat → POST ${ApiEndpoints.leaderAiChat}');
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.leaderAiChat,
        data: request.toJson(),
      );
      debugPrint('[leader-ai] api.sendChat ← status=${response.statusCode}');
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          throw const FormatException('leader-ai-chat: data not a map');
        }
        return LeaderAiChatResponse.fromJson(m);
      });
    } on DioException catch (e) {
      debugPrint(
        '[leader-ai] api.sendChat DioException type=${e.type} '
        'status=${e.response?.statusCode} message=${e.message}',
      );
      throw ApiException.fromDio(e);
    }
  }

  /// Stream `text_delta` chunks, kết thúc bằng `complete` event mang full response.
  ///
  /// Flutter consumer `await for (final ev in streamChat(...))` để cập nhật UI
  /// theo từng delta. Cancel bằng cách break khỏi `await for`.
  Stream<AiSseEvent> streamChat(LeaderAiChatRequest request) async* {
    debugPrint(
      '[leader-ai] api.streamChat → POST ${ApiEndpoints.leaderAiChatStream}',
    );
    final cancelToken = CancelToken();
    try {
      final response = await _dio.post<ResponseBody>(
        ApiEndpoints.leaderAiChatStream,
        data: request.toJson(),
        options: Options(
          responseType: ResponseType.stream,
          headers: <String, String>{
            'Accept': 'text/event-stream',
            'Cache-Control': 'no-cache',
          },
          // SSE pipeline 45s + buffer mạng — cho phép idle lâu hơn default Dio.
          receiveTimeout: const Duration(seconds: 60),
        ),
        cancelToken: cancelToken,
      );

      final stream = response.data?.stream;
      if (stream == null) {
        throw const FormatException('leader-ai-stream: empty body');
      }

      final buffer = StringBuffer();
      await for (final chunk in stream) {
        // chunk là Uint8List → decode UTF-8 (server emit JSON Vietnamese).
        buffer.write(utf8.decode(chunk, allowMalformed: true));

        while (true) {
          final raw = buffer.toString();
          final sep = raw.indexOf('\n\n');
          if (sep < 0) break;

          final eventText = raw.substring(0, sep).trim();
          final remaining = raw.substring(sep + 2);
          buffer
            ..clear()
            ..write(remaining);

          if (eventText.isEmpty) continue;
          final parsed = _parseSseEvent(eventText);
          if (parsed != null) yield parsed;
        }
      }
    } on DioException catch (e) {
      debugPrint(
        '[leader-ai] api.streamChat DioException type=${e.type} '
        'status=${e.response?.statusCode} message=${e.message}',
      );
      throw ApiException.fromDio(e);
    } finally {
      if (!cancelToken.isCancelled) {
        cancelToken.cancel('done');
      }
    }
  }

  /// Upload audio file (m4a/mp3/wav) lên `/api/leader-ai/voice/transcribe` → text từ Whisper.
  /// Mobile sau đó auto-submit text vào AI chat (UX C1).
  Future<String> transcribeVoice({
    required String filePath,
    required String contentType,
  }) async {
    debugPrint(
      '[leader-ai] api.transcribeVoice → POST ${ApiEndpoints.leaderAiVoiceTranscribe} ($contentType)',
    );
    try {
      final form = FormData.fromMap(<String, dynamic>{
        'file': await MultipartFile.fromFile(
          filePath,
          contentType: DioMediaType.parse(contentType),
        ),
      });
      final response = await _dio.post<dynamic>(
        ApiEndpoints.leaderAiVoiceTranscribe,
        data: form,
        options: Options(
          // Whisper transcribe ~1-3s, mạng + upload ~5-10s — đặt 30s là dư.
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      debugPrint('[leader-ai] api.transcribeVoice ← status=${response.statusCode}');
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          throw const FormatException('voice-transcribe: data not a map');
        }
        final err = m['error'] as String?;
        if (err != null && err.isNotEmpty) {
          throw _voiceTranscribeException(err);
        }
        final text = (m['text'] as String?)?.trim();
        if (text == null || text.isEmpty) {
          throw ApiException('Không nghe được nội dung — vui lòng thử lại.');
        }
        return text;
      });
    } on DioException catch (e) {
      debugPrint(
        '[leader-ai] api.transcribeVoice DioException type=${e.type} '
        'status=${e.response?.statusCode} message=${e.message}',
      );
      throw ApiException.fromDio(e);
    }
  }

  static ApiException _voiceTranscribeException(String code) {
    final msg = switch (code) {
      'audio_empty' => 'File ghi âm trống.',
      'audio_too_large' => 'File ghi âm quá lớn (tối đa 5MB).',
      'audio_format_unsupported' => 'Định dạng audio không được hỗ trợ.',
      'whisper_timeout' => 'Máy chủ chuyển giọng nói quá lâu, thử lại.',
      'whisper_unreachable' => 'Không kết nối được máy chủ chuyển giọng nói.',
      'transcribe_empty' => 'Không nghe được nội dung — vui lòng thử lại.',
      _ => 'Chuyển giọng nói thất bại ($code).',
    };
    return ApiException(msg);
  }

  Future<List<AiConversationDto>> getConversations() async {
    debugPrint(
      '[leader-ai] api.getConversations → GET ${ApiEndpoints.leaderAiConversations}',
    );
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.leaderAiConversations);
      return ApiResponseHandler.decode(response, (data) {
        final list = JsonUtils.readList(data);
        if (list == null) return const <AiConversationDto>[];
        return list
            .whereType<Map>()
            .map((m) => AiConversationDto.fromJson(m.cast<String, dynamic>()))
            .toList(growable: false);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Parse `data: {...}` line theo SSE Section 4.4. Trả null nếu không phải data event.
  AiSseEvent? _parseSseEvent(String eventText) {
    // Mỗi line trong block — chỉ quan tâm `data: ...`. Bỏ comment / id / event lines.
    final dataLines = <String>[];
    for (final line in const LineSplitter().convert(eventText)) {
      if (line.startsWith('data: ')) {
        dataLines.add(line.substring(6));
      } else if (line.startsWith('data:')) {
        dataLines.add(line.substring(5));
      }
    }
    if (dataLines.isEmpty) return null;

    final payload = dataLines.join('\n');
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return null;
      final map = decoded.cast<String, dynamic>();
      final eventName = (map['event'] as String?) ?? 'text_delta';
      switch (eventName) {
        case 'text_delta':
          return AiSseEvent.textDelta((map['text'] as String?) ?? '');
        case 'complete':
          final completeData = map['data'];
          if (completeData is Map<String, dynamic>) {
            return AiSseEvent.complete(LeaderAiChatResponse.fromJson(completeData));
          }
          if (completeData is Map) {
            return AiSseEvent.complete(
              LeaderAiChatResponse.fromJson(completeData.cast<String, dynamic>()),
            );
          }
          return null;
        case 'error':
          return AiSseEvent.error((map['message'] as String?) ?? 'Unknown error');
      }
    } catch (e) {
      debugPrint('[leader-ai] sse.parse_error payload=${payload.substring(0, payload.length.clamp(0, 200))} err=$e');
    }
    return null;
  }
}

/// SSE event union — Phase 2B chỉ 3 loại (text_delta / complete / error).
sealed class AiSseEvent {
  const AiSseEvent();

  const factory AiSseEvent.textDelta(String text) = AiSseTextDelta;
  const factory AiSseEvent.complete(LeaderAiChatResponse response) = AiSseComplete;
  const factory AiSseEvent.error(String message) = AiSseError;
}

class AiSseTextDelta extends AiSseEvent {
  const AiSseTextDelta(this.text);
  final String text;
}

class AiSseComplete extends AiSseEvent {
  const AiSseComplete(this.response);
  final LeaderAiChatResponse response;
}

class AiSseError extends AiSseEvent {
  const AiSseError(this.message);
  final String message;
}

final leaderAiApiProvider = Provider<LeaderAiApi>((ref) {
  return LeaderAiApi(ref.watch(dioProvider));
});
