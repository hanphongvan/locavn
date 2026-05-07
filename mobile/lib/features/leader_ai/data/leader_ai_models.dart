/// Models cho Loca AI Leader Assistant — Section 4.2/4.3 tài liệu thiết kế.
///
/// Wire format: backend trả camelCase qua System.Text.Json (JsonNamingPolicy.CamelCase).
/// Mọi `fromJson` ở đây dùng key camelCase đồng nhất với .NET API.
library;

import 'package:flutter/foundation.dart';

/// Context client gửi kèm câu hỏi (Section 4.2). Tuỳ chọn — null khi
/// user chưa chọn vùng/tỉnh/loại nhiên liệu cụ thể.
@immutable
class LeaderAiChatContext {
  const LeaderAiChatContext({
    this.screen,
    this.provinceId,
    this.regionId,
    this.fuelType,
    this.selectedLayer,
    this.selectedEntityId,
    this.selectedEntityType,
  });

  final String? screen;
  final int? provinceId;
  final int? regionId;
  final String? fuelType;
  final String? selectedLayer;
  final int? selectedEntityId;
  final String? selectedEntityType;

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (screen != null) 'screen': screen,
        if (provinceId != null) 'provinceId': provinceId,
        if (regionId != null) 'regionId': regionId,
        if (fuelType != null) 'fuelType': fuelType,
        if (selectedLayer != null) 'selectedLayer': selectedLayer,
        if (selectedEntityId != null) 'selectedEntityId': selectedEntityId,
        if (selectedEntityType != null) 'selectedEntityType': selectedEntityType,
      };
}

/// Request body cho POST /api/leader-ai/chat.
@immutable
class LeaderAiChatRequest {
  const LeaderAiChatRequest({
    required this.message,
    this.conversationId,
    this.context,
  });

  final String message;
  final String? conversationId;
  final LeaderAiChatContext? context;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'message': message,
        if (conversationId != null) 'conversationId': conversationId,
        if (context != null) 'context': context!.toJson(),
      };
}

/// Trạng thái context AI trả về (Section 4.3).
@immutable
class AiContextState {
  const AiContextState({
    this.lastIntent,
    this.lastTopic,
    this.lastRegionId,
    this.lastProvinceId,
    this.lastFuelType,
    this.lastProductCode,
    this.lastResultRef,
  });

  final String? lastIntent;
  final String? lastTopic;
  final int? lastRegionId;
  final int? lastProvinceId;
  final String? lastFuelType;
  final String? lastProductCode;
  final String? lastResultRef;

  factory AiContextState.fromJson(Map<String, dynamic> json) => AiContextState(
        lastIntent: json['lastIntent'] as String?,
        lastTopic: json['lastTopic'] as String?,
        lastRegionId: (json['lastRegionId'] as num?)?.toInt(),
        lastProvinceId: (json['lastProvinceId'] as num?)?.toInt(),
        lastFuelType: json['lastFuelType'] as String?,
        lastProductCode: json['lastProductCode'] as String?,
        lastResultRef: json['lastResultRef'] as String?,
      );
}

/// 1 series trong biểu đồ (Section 4.3 chart.series[].values).
@immutable
class AiChartSeries {
  const AiChartSeries({required this.name, required this.values});

  final String name;
  final List<double> values;

  factory AiChartSeries.fromJson(Map<String, dynamic> json) => AiChartSeries(
        name: (json['name'] as String?) ?? '',
        values: ((json['values'] as List?) ?? const [])
            .map<double>((v) => (v as num).toDouble())
            .toList(growable: false),
      );
}

/// Mô tả biểu đồ (Section 4.3 data.chart).
@immutable
class AiChartData {
  const AiChartData({
    required this.type,
    required this.title,
    required this.categories,
    required this.series,
  });

  /// `bar` | `line` | `pie` | `area` (Phase 2B chỉ render bar/line — Section 5 yêu cầu).
  final String type;
  final String title;
  final List<String> categories;
  final List<AiChartSeries> series;

  factory AiChartData.fromJson(Map<String, dynamic> json) => AiChartData(
        type: (json['type'] as String?) ?? 'bar',
        title: (json['title'] as String?) ?? '',
        categories: ((json['categories'] as List?) ?? const [])
            .map<String>((c) => c?.toString() ?? '')
            .toList(growable: false),
        series: ((json['series'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(AiChartSeries.fromJson)
            .toList(growable: false),
      );
}

/// Khối `data` trong response — null cho tin nhắn text thuần.
@immutable
class AiChatData {
  const AiChatData({
    this.summary,
    this.table,
    this.chart,
    this.map,
    this.reportMarkdown,
  });

  final Map<String, dynamic>? summary;
  final List<Map<String, dynamic>>? table;
  final AiChartData? chart;
  final Map<String, dynamic>? map;
  final String? reportMarkdown;

  factory AiChatData.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AiChatData();
    return AiChatData(
      summary: (json['summary'] as Map?)?.cast<String, dynamic>(),
      table: (json['table'] as List?)
          ?.whereType<Map>()
          .map((m) => m.cast<String, dynamic>())
          .toList(growable: false),
      chart: json['chart'] is Map<String, dynamic>
          ? AiChartData.fromJson(json['chart'] as Map<String, dynamic>)
          : null,
      map: (json['map'] as Map?)?.cast<String, dynamic>(),
      reportMarkdown: json['reportMarkdown'] as String?,
    );
  }
}

/// Quota request hôm nay (Section 4.3 rateLimitInfo).
@immutable
class AiRateLimitInfo {
  const AiRateLimitInfo({required this.requestsToday, required this.maxPerDay});

  final int requestsToday;
  final int maxPerDay;

  int get remaining => (maxPerDay - requestsToday).clamp(0, maxPerDay);
  bool get isLow => remaining < 10;

  factory AiRateLimitInfo.fromJson(Map<String, dynamic> json) => AiRateLimitInfo(
        requestsToday: ((json['requestsToday'] as num?) ?? 0).toInt(),
        maxPerDay: ((json['maxPerDay'] as num?) ?? 50).toInt(),
      );
}

/// Response Section 4.3 đầy đủ.
@immutable
class LeaderAiChatResponse {
  const LeaderAiChatResponse({
    required this.success,
    required this.conversationId,
    required this.intent,
    required this.resolvedQuestion,
    required this.answerText,
    required this.answerType,
    required this.confidence,
    required this.contextState,
    required this.data,
    required this.suggestedQuestions,
    required this.rateLimitInfo,
  });

  final bool success;
  final String conversationId;
  final String intent;
  final String resolvedQuestion;
  final String answerText;
  final String answerType; // text | chart | map | mixed | report
  final double confidence;
  final AiContextState contextState;
  final AiChatData data;
  final List<String> suggestedQuestions;
  final AiRateLimitInfo rateLimitInfo;

  factory LeaderAiChatResponse.fromJson(Map<String, dynamic> json) =>
      LeaderAiChatResponse(
        success: (json['success'] as bool?) ?? false,
        conversationId: (json['conversationId'] as String?) ?? '',
        intent: (json['intent'] as String?) ?? 'UNKNOWN',
        resolvedQuestion: (json['resolvedQuestion'] as String?) ?? '',
        answerText: (json['answerText'] as String?) ?? '',
        answerType: (json['answerType'] as String?) ?? 'text',
        confidence: ((json['confidence'] as num?) ?? 0.0).toDouble(),
        contextState: AiContextState.fromJson(
          (json['contextState'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        data: AiChatData.fromJson(
          (json['data'] as Map?)?.cast<String, dynamic>(),
        ),
        suggestedQuestions: ((json['suggestedQuestions'] as List?) ?? const [])
            .map<String>((s) => s?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList(growable: false),
        rateLimitInfo: AiRateLimitInfo.fromJson(
          (json['rateLimitInfo'] as Map?)?.cast<String, dynamic>() ??
              const {'requestsToday': 0, 'maxPerDay': 50},
        ),
      );
}

/// 1 conversation trong list `/api/leader-ai/conversations`.
@immutable
class AiConversationDto {
  const AiConversationDto({
    required this.id,
    required this.createdAt,
    this.title,
    this.updatedAt,
  });

  final String id;
  final String? title;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory AiConversationDto.fromJson(Map<String, dynamic> json) =>
      AiConversationDto(
        id: (json['id'] as String?) ?? '',
        title: json['title'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        updatedAt: json['updatedAt'] is String
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
      );
}

/// 1 message trong UI — bao gồm streaming flag.
@immutable
class AiMessageUiModel {
  const AiMessageUiModel({
    required this.id,
    required this.isUser,
    required this.text,
    required this.createdAt,
    this.intent,
    this.data,
    this.isStreaming = false,
  });

  final String id;
  final bool isUser;
  final String text;
  final DateTime createdAt;
  final String? intent;
  final AiChatData? data;
  final bool isStreaming;

  AiMessageUiModel copyWith({
    String? text,
    bool? isStreaming,
    AiChatData? data,
    String? intent,
  }) =>
      AiMessageUiModel(
        id: id,
        isUser: isUser,
        text: text ?? this.text,
        createdAt: createdAt,
        intent: intent ?? this.intent,
        data: data ?? this.data,
        isStreaming: isStreaming ?? this.isStreaming,
      );
}
