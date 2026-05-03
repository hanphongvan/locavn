import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Defaults for the inventory stock map ([google_maps_flutter]).
abstract final class InventoryStockMapConfig {
  /// Approximate visual center of Vietnam at [initialZoom] (country-scale on phones).
  static const double initialLatitude = 15.93;
  static const double initialLongitude = 106.45;

  static const double initialZoom = 6;
  static const double minZoom = 4;
  static const double maxZoom = 18;

  /// Viền khi [CameraUpdate.newLatLngBounds] (logical px).
  static const double fitBoundsPadding = 56;

  /// Bán kính (m) quanh GPS khi mở bản đồ — khung camera ~1 km quanh vị trí hiện tại.
  static const double userLocationRadiusMeters = 1000;

  /// Neo nhãn bản đồ (Hoàng Sa / Trường Sa) — trùng tọa độ đã dùng trên OSM cũ.
  static const LatLng maritimeHoangSa = LatLng(16.45, 111.85);
  static const LatLng maritimeTruongSa = LatLng(9.75, 114.15);
}
