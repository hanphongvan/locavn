import 'package:flutter/foundation.dart' show kReleaseMode;

import 'admin_api_credentials.dart';
import 'api_config_host.dart' if (dart.library.html) 'api_config_host_web.dart' as host;

/// Base URL cho REST API (không có `/` cuối).
///
/// **Thứ tự ưu tiên:**
/// 1. `--dart-define=API_BASE_URL=...` (compile-time) — **ghi đè** cả [host.devDefaultBaseUrl].
/// 2. Nếu không truyền `API_BASE_URL`: dùng `api_config_host.dart` (native) hoặc `api_config_host_web.dart` (web).
///
/// Đổi môi trường mà vẫn thấy URL cũ: xóa `API_BASE_URL` trong cấu hình chạy IDE, rồi `flutter clean` + build lại.
///
/// ```bash
/// flutter run --dart-define=API_BASE_URL=http://192.168.x.x:5112
/// ```
///
/// **Android Studio / Gradle:** thêm `API_BASE_URL=...` vào `android/local.properties`
/// (file đã gitignore) — `android/app/build.gradle.kts` gộp vào `dart-defines` cho `flutter assemble`.
///
/// Store-admin JSON (e.g. inventory stock map) needs the same **machine API key** as the
/// server `Admin:ApiKey` — pass **`--dart-define=ADMIN_API_KEY=...`** (header `X-Admin-Api-Key`).
/// Alternatively **`--dart-define=ADMIN_BEARER_TOKEN=...`** for a JWT from the admin OAuth flow.
/// On **native debug/profile**, you may set shell env **`HTTPM_ADMIN_API_KEY`** /
/// **`HTTPM_ADMIN_BEARER_TOKEN`** instead (see `admin_api_credentials.dart`).
class ApiConfig {
  ApiConfig._();

  static const String _fromEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  static String _stripTrailingSlash(String s) {
    var t = s.trim();
    while (t.endsWith('/')) {
      t = t.substring(0, t.length - 1);
    }
    return t;
  }

  static String get baseUrl {
    final fromEnv = _fromEnv.trim();
    if (fromEnv.isNotEmpty) {
      return _stripTrailingSlash(fromEnv);
    }
    // Release build BẮT BUỘC phải truyền `--dart-define=API_BASE_URL=...`
    // Nếu thiếu, fail-fast với message rõ ràng — KHÔNG fallback sang dev IP
    // (bảo vệ tránh APK production gửi request đến IP LAN của developer).
    if (kReleaseMode) {
      throw StateError(
        'API_BASE_URL is required for release builds. '
        'Pass --dart-define=API_BASE_URL=https://api.your-domain.example '
        'when building (flutter build apk / ipa). Refusing to fall back to '
        'dev default to avoid shipping local IP in production.',
      );
    }
    return _stripTrailingSlash(host.devDefaultBaseUrl());
  }

  /// Web-type OAuth Client ID dùng làm `serverClientId` cho Google Sign-In.
  /// Phải khớp với một entry trong `GoogleAuth:AllowedAudiences` ở backend.
  /// Truyền qua `--dart-define=GOOGLE_SERVER_CLIENT_ID=xxxxx.apps.googleusercontent.com`.
  /// Trống → ẩn nút "Đăng nhập với Google" trên login page.
  static String get googleServerClientId => _googleServerClientId.trim();

  /// Trùng `Admin:ApiKey` trên server — nguồn: dart-define / env (xem [AdminApiCredentials]).
  static String get adminApiKey => AdminApiCredentials.resolvedAdminApiKey;

  /// JWT store-admin (nếu dùng Bearer thay vì API key).
  static String get adminBearerToken => AdminApiCredentials.resolvedAdminBearer;

  static const int defaultPageTake = 40;
}
