import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/network/json_utils.dart';

/// Cờ cấu hình runtime do backend điều khiển (`GET /api/app/config`).
class AppConfig {
  const AppConfig({required this.feedbackEnabled});

  final bool feedbackEnabled;

  /// Fail-open: khi backend lỗi/không tải được, vẫn hiện FAB góp ý.
  static const AppConfig fallback = AppConfig(feedbackEnabled: true);

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      feedbackEnabled:
          JsonUtils.readBool(json['feedbackEnabled']) ?? JsonUtils.readBool(json['FeedbackEnabled']) ?? true,
    );
  }
}

/// Tải cờ cấu hình một lần khi mở app. Không throw — lỗi → [AppConfig.fallback].
final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get<dynamic>(ApiEndpoints.appConfig);
    return ApiResponseHandler.decode(response, (data) {
      final m = JsonUtils.readMap(data);
      return m == null ? AppConfig.fallback : AppConfig.fromJson(m);
    });
  } catch (_) {
    return AppConfig.fallback;
  }
});
