import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'admin_platform_env_io.dart'
    if (dart.library.html) 'admin_platform_env_stub.dart' as admin_env;

/// Optional credentials for `GET/POST /api/admin/*` (same schemes as the ASP.NET portal).
///
/// **1 — Compile-time (recommended for device builds):**
/// ```bash
/// flutter run --dart-define=API_BASE_URL=http://192.168.x.x:5112 \
///   --dart-define=ADMIN_API_KEY=your-shared-admin-key
/// ```
/// Value must match server **`Admin:ApiKey`** (header **`X-Admin-Api-Key`**).
///
/// **2 — Shell env (debug / profile only, IO platforms):** set before `flutter run`:
/// `HTTPM_ADMIN_API_KEY` and/or `HTTPM_ADMIN_BEARER_TOKEN`.
///
/// **`ADMIN_BEARER_TOKEN`** / dart-define: JWT from `POST /api/oauth/store-admin/token`.
abstract final class AdminApiCredentials {
  /// Same as server `AdminApiKeyDefaults.ApiKeyHeaderName`.
  static const String apiKeyHeaderName = 'X-Admin-Api-Key';

  /// Trùng `Admin:ApiKey` trong `appsettings.Development.json` — chỉ dùng khi [kDebugMode] và
  /// không có dart-define / env (tránh phải gõ `--dart-define` mỗi lần chạy local).
  static const String kDebugFallbackAdminApiKey = 'local-dev-admin-key';

  /// Giá trị đã gộp từ `--dart-define=ADMIN_API_KEY` / env debug — dùng khi cần biến cấu hình rõ ràng (ví dụ [ApiConfig.adminApiKey]).
  static String get resolvedAdminApiKey => _resolvedApiKey();

  /// JWT từ `--dart-define=ADMIN_BEARER_TOKEN` / env debug.
  static String get resolvedAdminBearer => _resolvedBearer();

  /// Header gửi kèm request admin từ khóa / token đã cấu hình (rỗng nếu chưa set).
  static Map<String, String> buildAdminAuthHeaders() =>
      headersFromKeyAndToken(resolvedAdminApiKey, resolvedAdminBearer);

  /// Ghép header `X-Admin-Api-Key` và `Authorization: Bearer …` từ biến tường minh (thường lấy từ [ApiConfig]).
  static Map<String, String> headersFromKeyAndToken(String apiKey, String bearer) {
    final key = apiKey.trim();
    final token = bearer.trim();
    final m = <String, String>{};
    if (key.isNotEmpty) m[apiKeyHeaderName] = key;
    if (token.isNotEmpty) m['Authorization'] = 'Bearer $token';
    return m;
  }

  static const String _apiKeyDefine = String.fromEnvironment(
    'ADMIN_API_KEY',
    defaultValue: '',
  );

  static const String _bearerDefine = String.fromEnvironment(
    'ADMIN_BEARER_TOKEN',
    defaultValue: '',
  );

  static String _resolvedApiKey() {
    final fromDefine = _apiKeyDefine.trim();
    if (fromDefine.isNotEmpty) return fromDefine;
    if (kReleaseMode) return '';
    final fromEnv = admin_env.adminApiKeyFromRuntimeEnv().trim();
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kDebugMode) return kDebugFallbackAdminApiKey;
    return '';
  }

  static String _resolvedBearer() {
    final fromDefine = _bearerDefine.trim();
    if (fromDefine.isNotEmpty) return fromDefine;
    if (kReleaseMode) return '';
    final fromEnv = admin_env.adminBearerFromRuntimeEnv().trim();
    if (fromEnv.isNotEmpty) return fromEnv;
    return '';
  }

  /// Public registration endpoints (same anonymous key as Angular admin portal).
  static void applyToPublicRegisterUserRequest(RequestOptions options) {
    final key = _resolvedApiKey();
    if (key.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[httm_xangdau] Register-user API: no ADMIN_API_KEY. '
          'Set --dart-define=ADMIN_API_KEY=... matching server Admin:ApiKey.',
        );
      }
      return;
    }
    options.headers[apiKeyHeaderName] = key;
  }

  static void applyToAdminRequest(RequestOptions options) {
    final path = options.uri.path;
    if (!path.contains('/api/admin')) return;

    final key = _resolvedApiKey();
    final token = _resolvedBearer();

    if (key.isEmpty && token.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[httm_xangdau] Admin API: no credential for $path. '
          'Set --dart-define=ADMIN_API_KEY=<Admin:ApiKey from appsettings> '
          'or export HTTPM_ADMIN_API_KEY (debug/profile, native only).',
        );
      }
      return;
    }

    if (key.isNotEmpty) {
      options.headers[apiKeyHeaderName] = key;
    }
    if (token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
  }
}
