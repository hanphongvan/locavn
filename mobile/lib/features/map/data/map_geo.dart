import 'dart:math' as math;

import '../../../core/map/app_lat_lng.dart';
import '../../../core/map/app_lat_lng_bounds.dart';

/// Great-circle distance in km (WGS84), same idea as the server spotlight query.
double mapHaversineKm(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const earthKm = 6371.0;
  final p1 = lat1 * math.pi / 180.0;
  final p2 = lat2 * math.pi / 180.0;
  final dP = p2 - p1;
  final dL = (lon2 - lon1) * math.pi / 180.0;
  final a = math.sin(dP / 2) * math.sin(dP / 2) +
      math.cos(p1) * math.cos(p2) * math.sin(dL / 2) * math.sin(dL / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(math.max(0, 1 - a)));
  return earthKm * c;
}

/// Min/max của tập điểm thành [AppLatLngBounds] — dùng để [animateCamera] fit bounds
/// (vd. khung vừa "vị trí của bạn" + "trạm gần nhất").
///
/// Không xử lý anti-meridian (VN cách xa đường đổi ngày).
AppLatLngBounds mapBoundsForPoints(List<AppLatLng> points) {
  assert(points.isNotEmpty, 'mapBoundsForPoints called with empty list');
  var minLat = points.first.latitude;
  var maxLat = points.first.latitude;
  var minLng = points.first.longitude;
  var maxLng = points.first.longitude;
  for (final p in points.skip(1)) {
    if (p.latitude < minLat) minLat = p.latitude;
    if (p.latitude > maxLat) maxLat = p.latitude;
    if (p.longitude < minLng) minLng = p.longitude;
    if (p.longitude > maxLng) maxLng = p.longitude;
  }
  return AppLatLngBounds(
    southwest: AppLatLng(minLat, minLng),
    northeast: AppLatLng(maxLat, maxLng),
  );
}
