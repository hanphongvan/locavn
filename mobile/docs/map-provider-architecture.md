# Map provider architecture

Provider chọn tại **deployment time** qua `--dart-define`. KHÔNG có user-facing toggle.

## Goal

Hỗ trợ nhiều map provider cùng codebase, chọn 1 provider áp dụng global cho mobile app, admin web, leader dashboard. Khi đổi provider, chỉ đổi build flag — không sửa feature code.

## Layers

```
features/{map,inventory_stock_map,leader}/   ← chỉ dùng AppMap (KHÔNG import google_maps_flutter / maplibre_gl trực tiếp)
                  │
                  ▼
lib/core/map/app_map.dart                    ← ConsumerWidget public
                  │
                  ▼
lib/core/map/map_providers.dart              ← Riverpod resolves current adapter
                  │
                  ▼
lib/core/map/map_provider_registry.dart      ← Map<Kind, Adapter>
                  │
                  ▼
MapProviderAdapter (interface)               ← google / goong / osm
```

## Files

| File | Trách nhiệm |
|---|---|
| `app_lat_lng.dart`, `app_lat_lng_bounds.dart` | Giá trị vị trí provider-agnostic |
| `app_map_camera.dart` | `AppMapCameraPosition`, `AppMapCameraUpdate` (sealed) |
| `app_map_marker.dart` | Marker + icon (default/asset/bytes) + anchor |
| `app_map_polyline.dart` | Polyline |
| `app_map_controller.dart` | Interface controller |
| `map_provider_kind.dart` | Enum `{google, goong, osm}` + parse từ config |
| `map_capability.dart` | Flags: clustering, vectorStyle, offline, heatmap, … |
| `map_provider_adapter.dart` | Interface mỗi provider phải implement |
| `map_provider_registry.dart` | Lookup adapter theo kind |
| `map_provider_config.dart` | Đọc `--dart-define=MAP_PROVIDER` |
| `map_providers.dart` | Riverpod providers (registry, current kind, current adapter) |
| `app_map.dart` | Widget public — feature code chỉ cần import file này |

## Configuration

```bash
# Mặc định Google (backward compat)
flutter run

# Goong
flutter run --dart-define=MAP_PROVIDER=goong \
  --dart-define-from-file=secrets/dev.json

# OSM (milestone sau)
flutter run --dart-define=MAP_PROVIDER=osm
```

Giá trị không hợp lệ → `MapProviderConfig.parse` throw `StateError` ngay lúc khởi động (fail-fast, không silent fallback).

## Bootstrap (PR4 sẽ wire)

```dart
// main.dart
runApp(
  ProviderScope(
    overrides: [
      mapProviderRegistryProvider.overrideWith((ref) {
        return MapProviderRegistry()
          ..register(GoogleMapAdapter())
          ..register(GoongMapAdapter(
            mapTilesKey: const String.fromEnvironment('GOONG_MAPTILES_KEY'),
            restApiKey: const String.fromEnvironment('GOONG_API_KEY'),
          ));
      }),
    ],
    child: const App(),
  ),
);
```

Chỉ register những adapter dự định dùng. Nếu config trỏ tới adapter chưa register → throw rõ ràng.

## Capability check

Provider không feature-parity. UI phải kiểm tra trước khi gọi tính năng tùy chọn:

```dart
final adapter = ref.watch(currentMapProviderAdapterProvider);
if (adapter.capabilities.contains(MapCapability.heatmap)) {
  // build heatmap UI
}
```

Bảng tham khảo (sẽ cập nhật khi từng adapter merged):

| Capability | Google | Goong (MapLibre) | OSM (flutter_map) |
|---|---|---|---|
| `nativeClustering` | ✓ | ✗ (tự code via symbol expr) | ✓ (plugin) |
| `vectorStyle` | một phần | ✓ | ✗ raster only |
| `offline` | ✗ | ✓ (mbtiles) | ✓ |
| `heatmap` | ✓ | ✓ | plugin |

## Thêm provider mới

1. Tạo class `XxxMapAdapter extends MapProviderAdapter`
2. Implement `kind`, `capabilities`, `displayName`, `buildMap(...)`
3. Thêm giá trị vào `MapProviderKind` (nếu chưa có)
4. Đăng ký trong `main.dart` override
5. Tài liệu hoá capability trong bảng trên

## Restrictions

- 🔴 Feature screens (`features/...`) **KHÔNG** import `google_maps_flutter`, `maplibre_gl`, `flutter_map`. Chỉ dùng `lib/core/map/`.
- 🔴 Adapter mới **KHÔNG** thêm dependency vào `core/map/` interface — chỉ thêm vào package adapter của riêng nó.
- 🟡 Provider không hỗ trợ feature → adapter trả widget vô hại (vd marker mặc định) thay vì throw. UI tự ẩn qua `capabilities`.
