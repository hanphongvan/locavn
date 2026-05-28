import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../telemetry/client_telemetry_providers.dart';

/// Đính 4 header (X-App-Version, X-App-Build, X-App-Platform, X-Client-Id) vào mỗi
/// request. Backend (`ClientVersionLogMiddleware`) sample các request có header này
/// để track adoption phiên bản mobile.
///
/// Tải header lần đầu rồi cache RAM — không hit secure storage / package_info_plus
/// trên mọi request. Nếu lần đầu fail (storage corrupt / quyền), không chặn request.
final class ClientTelemetryInterceptor extends Interceptor {
  ClientTelemetryInterceptor(this._ref);

  final Ref _ref;
  Map<String, String>? _cachedHeaders;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (_cachedHeaders == null) {
      try {
        _cachedHeaders = await _ref.read(clientTelemetryHeadersProvider.future);
      } catch (e, st) {
        // Không chặn request nếu telemetry fail.
        if (kDebugMode) {
          debugPrint('[telemetry] load headers failed: $e\n$st');
        }
      }
    }
    final headers = _cachedHeaders;
    if (headers != null) {
      options.headers.addAll(headers);
    }
    handler.next(options);
  }
}
