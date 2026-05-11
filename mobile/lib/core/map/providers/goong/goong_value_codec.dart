import 'dart:math' as math;

import 'package:maplibre_gl/maplibre_gl.dart' as ml;

import '../../app_lat_lng.dart';
import '../../app_lat_lng_bounds.dart';
import '../../app_map_camera.dart';

abstract final class GoongValueCodec {
  GoongValueCodec._();

  /// Web Mercator / MapLibre thường giới hạn gần cực; tránh NaN/∞ từ dữ liệu API.
  static double _sanitizeLat(double lat) {
    if (!lat.isFinite) return 15.9266657;
    return lat.clamp(-85.05112878, 85.05112878);
  }

  static double _sanitizeLng(double lng) {
    if (!lng.isFinite) return 107.9650855;
    return lng.clamp(-180.0, 180.0);
  }

  static double _sanitizeZoom(double z) {
    if (!z.isFinite) return 13.0;
    return z.clamp(0.0, 22.0);
  }

  static ml.LatLng toLatLng(AppLatLng v) =>
      ml.LatLng(_sanitizeLat(v.latitude), _sanitizeLng(v.longitude));

  static AppLatLng fromLatLng(ml.LatLng v) =>
      AppLatLng(v.latitude, v.longitude);

  static ml.LatLngBounds toBounds(AppLatLngBounds b) {
    // Defense: MapLibre native throw std::domain_error nếu bounds có diện tích = 0
    // (crash hardstop, Dart try/catch không bắt được). Expand epsilon ~10m mỗi cạnh
    // khi degenerate. Phòng case bounds build trực tiếp không qua mapBoundsForPoints.
    const double eps = 0.0001;
    var minLat = b.southwest.latitude;
    var maxLat = b.northeast.latitude;
    var minLng = b.southwest.longitude;
    var maxLng = b.northeast.longitude;
    if (maxLat - minLat < eps) {
      final mid = (minLat + maxLat) / 2;
      minLat = mid - eps;
      maxLat = mid + eps;
    }
    if (maxLng - minLng < eps) {
      final mid = (minLng + maxLng) / 2;
      minLng = mid - eps;
      maxLng = mid + eps;
    }
    return ml.LatLngBounds(
      southwest: ml.LatLng(_sanitizeLat(minLat), _sanitizeLng(minLng)),
      northeast: ml.LatLng(_sanitizeLat(maxLat), _sanitizeLng(maxLng)),
    );
  }

  static AppLatLngBounds fromBounds(ml.LatLngBounds b) => AppLatLngBounds(
        southwest: fromLatLng(b.southwest),
        northeast: fromLatLng(b.northeast),
      );

  static ml.CameraPosition toCameraPosition(AppMapCameraPosition p) =>
      ml.CameraPosition(
        target: toLatLng(p.target),
        zoom: _sanitizeZoom(p.zoom),
        bearing: p.bearing.isFinite ? p.bearing : 0.0,
        tilt: p.tilt.isFinite ? p.tilt.clamp(0.0, 60.0) : 0.0,
      );

  static AppMapCameraPosition fromCameraPosition(ml.CameraPosition p) =>
      AppMapCameraPosition(
        target: fromLatLng(p.target),
        zoom: p.zoom,
        bearing: p.bearing,
        tilt: p.tilt,
      );

  static ml.CameraUpdate toCameraUpdate(AppMapCameraUpdate u) {
    return switch (u) {
      AppMapCameraUpdateNewLatLng() =>
        ml.CameraUpdate.newLatLng(toLatLng(u.latLng)),
      AppMapCameraUpdateNewLatLngZoom() => ml.CameraUpdate.newLatLngZoom(
          toLatLng(u.latLng),
          _sanitizeZoom(u.zoom),
        ),
      AppMapCameraUpdateNewCameraPosition() => ml.CameraUpdate.newCameraPosition(
          toCameraPosition(u.position),
        ),
      // MapLibre native trên iOS 19 / iPhone 17 throw std::domain_error trong
      // `cameraThatFitsCoordinateBounds` (C++ exception, Dart try/catch không bắt được).
      // Convert bounds → center + computed zoom để bypass code path đó.
      AppMapCameraUpdateNewLatLngBounds() => _boundsToLatLngZoom(u.bounds),
      AppMapCameraUpdateZoomTo() => ml.CameraUpdate.zoomTo(_sanitizeZoom(u.zoom)),
    };
  }

  /// Tâm bounds + zoom tính từ longitude span (Web Mercator approx).
  /// Output bằng `newLatLngZoom` (luôn an toàn) thay vì `newLatLngBounds`.
  static ml.CameraUpdate _boundsToLatLngZoom(AppLatLngBounds b) {
    final sw = b.southwest;
    final ne = b.northeast;
    final centerLat = (sw.latitude + ne.latitude) / 2;
    final centerLng = (sw.longitude + ne.longitude) / 2;
    final lngSpan = (ne.longitude - sw.longitude).abs();
    // Web Mercator: zoom z thì world chia thành 2^z tiles, mỗi tile = 360° / 2^z.
    // Để bounds vừa khít ~256px tile width: z = log2(360 / lngSpan).
    // Trừ 0.5 cho padding visual.
    double zoom = 15;
    if (lngSpan > 0) {
      zoom = (math.log(360.0 / lngSpan) / math.ln2 - 0.5).clamp(4.0, 18.0);
    }
    return ml.CameraUpdate.newLatLngZoom(
      ml.LatLng(_sanitizeLat(centerLat), _sanitizeLng(centerLng)),
      _sanitizeZoom(zoom),
    );
  }
}
