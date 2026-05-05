import 'providers/goong/goong_map_adapter.dart';
import 'providers/google/google_map_adapter.dart';
import 'map_provider_registry.dart';

/// Build registry từ env values (đọc bởi main.dart qua `String.fromEnvironment`).
/// Tách hàm để test được — `String.fromEnvironment` là compile-time constant.
///
/// Quy tắc:
/// - Google luôn được đăng ký (không cần key Dart-side, key Google native config).
/// - Goong CHỈ được đăng ký khi có `goongMapTilesKey` non-empty.
///   Nếu `MAP_PROVIDER=goong` mà thiếu key → adapter throw lúc create
///   `currentMapProviderAdapterProvider` (fail-fast khi mở map đầu tiên).
MapProviderRegistry buildMapProviderRegistry({
  String? goongMapTilesKey,
  String? goongRestApiKey,
}) {
  final registry = MapProviderRegistry()..register(GoogleMapAdapter());

  final mapTilesKey = goongMapTilesKey?.trim() ?? '';
  if (mapTilesKey.isNotEmpty) {
    final restKey = goongRestApiKey?.trim() ?? '';
    registry.register(
      GoongMapAdapter(
        mapTilesKey: mapTilesKey,
        restApiKey: restKey.isEmpty ? null : restKey,
      ),
    );
  }
  return registry;
}
