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

### Dev

Copy `secrets/dev.json.example` → `secrets/dev.json` (gitignored), điền giá trị, rồi:

```bash
# Mặc định Google (backward compat — không cần MAP_PROVIDER trong file)
flutter run --dart-define-from-file=secrets/dev.json

# Goong: trong dev.json đặt MAP_PROVIDER=goong + GOONG_MAPTILES_KEY=... + GOONG_API_KEY=...
flutter run --dart-define-from-file=secrets/dev.json

# Override nhanh không sửa file:
flutter run --dart-define-from-file=secrets/dev.json --dart-define=MAP_PROVIDER=goong
```

### Production

Copy `secrets/prod.json.example` → `secrets/prod.json` (gitignored), điền key thật, rồi:

```bash
# Android
flutter build apk --release --dart-define-from-file=secrets/prod.json
flutter build appbundle --release --dart-define-from-file=secrets/prod.json

# iOS
flutter build ipa --release --dart-define-from-file=secrets/prod.json
```

CI/CD: inject `secrets/prod.json` từ secret store (GitHub Actions secret, GitLab CI variable, …) trước build step.

### Validation (fail-fast)

`EnvironmentConfig.validateOrThrow()` (gọi 1 lần ở `main.dart` trước `runApp`) throw `StateError` nếu:

| Trường hợp | Hệ quả |
|---|---|
| `MAP_PROVIDER` không hợp lệ (≠ google/goong/osm) | throw từ `MapProviderConfig.parse` |
| `MAP_PROVIDER=goong` nhưng `GOONG_MAPTILES_KEY` rỗng | throw — KHÔNG silent fallback Google |
| `MAP_PROVIDER=goong` nhưng `GOONG_API_KEY` rỗng | throw |
| `MAP_PROVIDER=osm` | throw — milestone chưa hỗ trợ |

🔴 Nguyên tắc: **không silent fallback Google** ở production VN — sai compliance map mà khách dùng không hay.

### OSM (milestone sau)

```bash
flutter run --dart-define=MAP_PROVIDER=osm   # ← hiện tại sẽ throw, milestone OSM chưa làm
```

## Bootstrap (đã wire ở `main.dart`)

```
main.dart
  ├─ EnvironmentConfig.validateOrThrow()  ← fail-fast TRƯỚC runApp
  └─ buildMapProviderRegistry(...)         ← register Google + Goong (nếu có key)
       │
       └─ ProviderScope override mapProviderRegistryProvider
```

- `EnvironmentConfig` (`lib/core/config/environment_config.dart`): single source of truth
  cho mọi `--dart-define`. Tránh scattered `String.fromEnvironment` rải rác.
- `buildMapProviderRegistry` (`lib/core/map/map_provider_bootstrap.dart`): Google luôn
  được đăng ký (key inject native Android Manifest / xcconfig). Goong đăng ký khi
  `GOONG_MAPTILES_KEY` non-empty.
- Khi thêm OSM (milestone sau), update `buildMapProviderRegistry` thêm
  `..register(OsmMapAdapter())` + nới `EnvironmentConfig.validateConfig` cho `osm`.

## Native config

**Android** (`android/app/src/main/AndroidManifest.xml`):

| Key | Cần cho | Trạng thái |
|---|---|---|
| `INTERNET` | All | ✓ đã có |
| `ACCESS_COARSE_LOCATION` + `ACCESS_FINE_LOCATION` | All (my-location) | ✓ đã có |
| meta-data `com.google.android.geo.API_KEY` | Google only | ✓ inject qua `${GOOGLE_MAPS_API_KEY}` từ Gradle |

→ **Goong KHÔNG cần thêm permission/meta-data** trên Android (key nằm trong style URL).

🟡 MapLibre yêu cầu Android API ≥ 21 và Kotlin 2.1.0+ (xem pubspec maplibre_gl). Verify `android/app/build.gradle.kts` `minSdk` + Kotlin version trước build Goong lần đầu.

**iOS** (`ios/Runner/Info.plist`):

| Key | Cần cho | Trạng thái |
|---|---|---|
| `NSLocationWhenInUseUsageDescription` | All (my-location) | ✓ đã có |
| `GMSApiKey` | Google only | ✓ inject từ `Flutter/Local.xcconfig` (`GMS_API_KEY`) |
| `NSAppTransportSecurity` | Local network dev | ✓ đã có |

→ **Goong KHÔNG cần thêm Info.plist key** trên iOS.

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
