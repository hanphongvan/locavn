import 'dart:math' as math;

import '../../../core/map/app_lat_lng.dart';
import '../../../core/map/app_lat_lng_bounds.dart';

/// Index nhánh **Bản đồ** trong shell tab lãnh đạo (`StatefulShellRoute.indexedStack`) —
/// phải khớp thứ tự `branches` trong `go_router` (0=Tổng quan, 1=Bản đồ, …).
///
/// Dùng để **không mount** `AppMap` khi tab khác đang active: `IndexedStack` vẫn build
/// mọi nhánh; Google Map platform view offstage trên Android dễ gây crash resize
/// (`SurfaceProducer` null).
const int kLeaderMapShellBranchIndex = 1;

/// Khung mặc định (toàn quốc), cùng ý với bản đồ trạm chính.
const AppLatLng kLeaderMapCenterVietnam = AppLatLng(15.9266657, 107.9650855);

/// Bán kính quanh vị trí người dùng khi bật lớp cửa hàng (m) — giới hạn vùng gọi API.
const double kLeaderRetailStoresViewportRadiusMeters = 500;

/// Padding `AppMapCameraUpdate.newLatLngBounds` khi fit 500 m.
const double kLeaderRetailStoresFitBoundsPadding = 48;

/// Hộp lat/lng ~2×[radiusMeters] từ [center] (cùng mô hình `InventoryStockMapGoogleView`).
AppLatLngBounds leaderLatLngBoundsWithRadiusMeters(AppLatLng center, double radiusMeters) {
  final latRad = center.latitude * math.pi / 180;
  final cosLat = math.cos(latRad).clamp(0.02, 1.0);
  const mPerDegLat = 111320.0;
  final mPerDegLng = 111320.0 * cosLat;
  final dLat = radiusMeters / mPerDegLat;
  final dLng = radiusMeters / mPerDegLng;
  return AppLatLngBounds(
    southwest: AppLatLng(center.latitude - dLat, center.longitude - dLng),
    northeast: AppLatLng(center.latitude + dLat, center.longitude + dLng),
  );
}
