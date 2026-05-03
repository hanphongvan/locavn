import 'dart:math' as math;

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
