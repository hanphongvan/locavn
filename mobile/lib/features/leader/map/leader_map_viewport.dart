import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../stations/data/models/station_map_item.dart';

/// Giới hạn marker theo zoom (cùng ý tưởng với [MapStationMapBody]).
int leaderMapCapForZoom(double zoom) {
  if (zoom < 7.5) return 240;
  if (zoom < 9.5) return 420;
  if (zoom < 11.5) return 650;
  if (zoom < 13) return 900;
  if (zoom < 14.5) return 360;
  if (zoom < 16) return 220;
  return 160;
}

double _dist2(StationMapItem a, LatLng c) {
  final dx = a.latitude - c.latitude;
  final dy = a.longitude - c.longitude;
  return dx * dx + dy * dy;
}

/// Trạm trong khung nhìn, giới hạn số lượng — ưu tiên gần tâm bounds.
List<StationMapItem> leaderStationsInViewport(
  List<StationMapItem> all,
  LatLngBounds bounds,
  double zoom,
) {
  final inside = <StationMapItem>[];
  for (final e in all) {
    final p = LatLng(e.latitude, e.longitude);
    if (bounds.contains(p)) {
      inside.add(e);
    }
  }
  final cap = math.min(leaderMapCapForZoom(zoom), 2000);
  if (inside.length <= cap) {
    return inside;
  }
  final sw = bounds.southwest;
  final ne = bounds.northeast;
  final c = LatLng((sw.latitude + ne.latitude) / 2, (sw.longitude + ne.longitude) / 2);
  inside.sort((a, b) => _dist2(a, c).compareTo(_dist2(b, c)));
  return inside.take(cap).toList(growable: false);
}
