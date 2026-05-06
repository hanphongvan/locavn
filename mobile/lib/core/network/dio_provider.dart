import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_config.dart';
import 'auth_http_interceptor.dart';

String _dioSafeRequestUrl(Uri u) =>
    '${u.scheme}://${u.host}${u.hasPort && u.port != 0 ? ':${u.port}' : ''}${u.path}';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      /// Upload (vd ảnh khi backend hỗ trợ multipart) — 60s đủ cho 5 ảnh @1-2MB qua 4G.
      sendTimeout: const Duration(seconds: 60),
      /// Map và một số báo cáo có thể truy vấn lớn; 30s dễ vượt trên máy dev/DB xa.
      receiveTimeout: const Duration(seconds: 120),
      headers: {'Accept': 'application/json'},
    ),
  );
  dio.interceptors.add(AuthHttpInterceptor(ref));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (kDebugMode) {
          final u = options.uri;
          debugPrint(
            '[httm_xangdau] API ${options.method} ${_dioSafeRequestUrl(u)}',
          );
        }
        handler.next(options);
      },
      onError: (e, handler) {
        if (kDebugMode) {
          final req = e.requestOptions;
          final u = req.uri;
          // Sanitize URL — strip query string vì có thể chứa token nhạy cảm
          // (vd `?token=...` ở reset-password, hoặc query có id/email PII).
          // KHÔNG log toàn bộ DioException qua toString() vì nó in cả URI gốc + headers.
          final safeUrl = '${u.scheme}://${u.host}:${u.port}${u.path}';
          debugPrint(
            '[httm_xangdau] Dio ${req.method} $safeUrl '
            '— status=${e.response?.statusCode} type=${e.type} message=${e.message}',
          );
          debugPrintStack(
            stackTrace: e.stackTrace,
            label: '[httm_xangdau] dio stack',
          );
        }
        return handler.next(e);
      },
    ),
  );
  return dio;
});
