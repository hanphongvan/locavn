import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'app_lat_lng.dart';

@immutable
class AppMapPolylineId {
  final String value;
  const AppMapPolylineId(this.value);

  @override
  bool operator ==(Object other) =>
      other is AppMapPolylineId && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

class AppMapPolyline {
  final AppMapPolylineId id;
  final List<AppLatLng> points;
  final Color color;
  final double width;
  final bool geodesic;

  const AppMapPolyline({
    required this.id,
    required this.points,
    this.color = const Color(0xFF1976D2),
    this.width = 4,
    this.geodesic = false,
  });
}
