import 'package:flutter/foundation.dart' show visibleForTesting;

import '../map/map_provider_config.dart';
import '../map/map_provider_kind.dart';

/// Single source of truth cho compile-time environment values
/// (`--dart-define-from-file=secrets/{dev,prod}.json`).
///
/// Gọi [validateOrThrow] sớm trong `main.dart` (TRƯỚC `runApp`) để fail-fast
/// khi config sai — ví dụ MAP_PROVIDER=goong nhưng thiếu key — thay vì để app
/// chạy với behavior bất ngờ (silent fallback).
abstract final class EnvironmentConfig {
  EnvironmentConfig._();

  static const String _mapProviderRaw =
      String.fromEnvironment('MAP_PROVIDER', defaultValue: '');
  static const String _apiBaseUrlRaw =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');
  static const String _goongMapTilesKeyRaw =
      String.fromEnvironment('GOONG_MAPTILES_KEY', defaultValue: '');
  static const String _goongApiKeyRaw =
      String.fromEnvironment('GOONG_API_KEY', defaultValue: '');
  static const String _adminApiKeyRaw =
      String.fromEnvironment('ADMIN_API_KEY', defaultValue: '');
  static const String _adminBearerTokenRaw =
      String.fromEnvironment('ADMIN_BEARER_TOKEN', defaultValue: '');

  static String? _nonEmpty(String raw) {
    final t = raw.trim();
    return t.isEmpty ? null : t;
  }

  /// Resolved provider (xem `MapProviderConfig`). Default = google.
  static MapProviderKind get mapProvider => MapProviderConfig.resolved;

  /// Backend URL (rỗng = caller tự fallback dev default; release BẮT BUỘC truyền — xem `ApiConfig`).
  static String get apiBaseUrlRaw => _apiBaseUrlRaw;

  /// Map Tiles Key cho render bản đồ Goong (`tiles.goong.io`). Null nếu chưa set.
  static String? get goongMapTilesKey => _nonEmpty(_goongMapTilesKeyRaw);

  /// REST API Key cho Geocoding / Directions / AutoComplete của Goong (`rsapi.goong.io`).
  static String? get goongApiKey => _nonEmpty(_goongApiKeyRaw);

  /// Header X-Admin-Api-Key — trùng `Admin:ApiKey` trên server.
  static String? get adminApiKey => _nonEmpty(_adminApiKeyRaw);

  /// JWT từ store-admin OAuth flow (Bearer token).
  static String? get adminBearerToken => _nonEmpty(_adminBearerTokenRaw);

  /// Throws [StateError] nếu config không hợp lệ. Gọi 1 lần ở startup
  /// **trước `runApp`** để fail-fast thay vì lazy-throw khi user mở map.
  ///
  /// Quy tắc:
  /// - `MAP_PROVIDER=goong` → BẮT BUỘC cả `GOONG_MAPTILES_KEY` (render tile)
  ///   và `GOONG_API_KEY` (REST). Thiếu 1 trong 2 → throw, KHÔNG silent
  ///   fallback Google. Lý do: production VN deploy với Goong, fallback sai
  ///   sẽ làm khách dùng bản đồ không-VN-compliance mà không hay.
  /// - `MAP_PROVIDER=osm` → chưa hỗ trợ (xem milestone OSM).
  static void validateOrThrow() {
    validateConfig(
      kind: mapProvider,
      goongMapTilesKey: goongMapTilesKey,
      goongApiKey: goongApiKey,
    );
  }

  /// Logic validate tách ra để test được (compile-time consts không inject được trong test).
  @visibleForTesting
  static void validateConfig({
    required MapProviderKind kind,
    String? goongMapTilesKey,
    String? goongApiKey,
  }) {
    if (kind == MapProviderKind.goong) {
      if (goongMapTilesKey == null || goongMapTilesKey.trim().isEmpty) {
        throw StateError(
          'MAP_PROVIDER=goong yêu cầu GOONG_MAPTILES_KEY non-empty. '
          'Set trong --dart-define-from-file=secrets/prod.json. '
          'Refusing to fall back to Google để tránh deploy sai compliance VN.',
        );
      }
      if (goongApiKey == null || goongApiKey.trim().isEmpty) {
        throw StateError(
          'MAP_PROVIDER=goong yêu cầu GOONG_API_KEY non-empty (REST API key cho Geocoding/Directions). '
          'Set trong --dart-define-from-file=secrets/prod.json.',
        );
      }
    }
    if (kind == MapProviderKind.osm) {
      throw StateError(
        'MAP_PROVIDER=osm chưa hỗ trợ — OSM provider là milestone riêng '
        '(xem mobile/docs/map-provider-architecture.md).',
      );
    }
  }
}
