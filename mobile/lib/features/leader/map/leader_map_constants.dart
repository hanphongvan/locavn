import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Khung mặc định (toàn quốc), cùng ý với bản đồ trạm chính.
const LatLng kLeaderMapCenterVietnam = LatLng(15.9266657, 107.9650855);

/// Bán kính quanh vị trí người dùng khi bật lớp cửa hàng (m) — giới hạn vùng gọi API.
const double kLeaderRetailStoresViewportRadiusMeters = 500;

/// Padding [CameraUpdate.newLatLngBounds] khi fit 500 m.
const double kLeaderRetailStoresFitBoundsPadding = 48;

/// Hộp lat/lng ~2×[radiusMeters] từ [center] (cùng mô hình [InventoryStockMapGoogleView]).
LatLngBounds leaderLatLngBoundsWithRadiusMeters(LatLng center, double radiusMeters) {
  final latRad = center.latitude * math.pi / 180;
  final cosLat = math.cos(latRad).clamp(0.02, 1.0);
  const mPerDegLat = 111320.0;
  final mPerDegLng = 111320.0 * cosLat;
  final dLat = radiusMeters / mPerDegLat;
  final dLng = radiusMeters / mPerDegLng;
  return LatLngBounds(
    southwest: LatLng(center.latitude - dLat, center.longitude - dLng),
    northeast: LatLng(center.latitude + dLat, center.longitude + dLng),
  );
}
