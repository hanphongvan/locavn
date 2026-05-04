import 'map_provider_kind.dart';

/// Chọn provider tại deployment time qua `--dart-define=MAP_PROVIDER=google|goong|osm`.
/// Áp dụng global, KHÔNG cho user toggle ở runtime (xem
/// `mobile/docs/map-provider-architecture.md`).
abstract final class MapProviderConfig {
  static const String _fromEnv = String.fromEnvironment(
    'MAP_PROVIDER',
    defaultValue: '',
  );

  static const MapProviderKind defaultKind = MapProviderKind.google;

  static MapProviderKind get resolved => parse(_fromEnv);

  static String get rawConfig => _fromEnv;

  /// Tách logic parse khỏi compile-time `_fromEnv` để test được.
  static MapProviderKind parse(
    String? raw, {
    MapProviderKind fallback = defaultKind,
  }) {
    if (raw == null || raw.trim().isEmpty) return fallback;
    final parsed = MapProviderKind.fromConfigValue(raw);
    if (parsed == null) {
      throw StateError(
        'Unknown MAP_PROVIDER value "$raw". '
        'Valid: ${MapProviderKind.values.map((e) => e.configValue).join(", ")}.',
      );
    }
    return parsed;
  }
}
