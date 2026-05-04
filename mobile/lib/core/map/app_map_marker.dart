import 'package:flutter/foundation.dart';

import 'app_lat_lng.dart';

@immutable
class AppMapMarkerId {
  final String value;
  const AppMapMarkerId(this.value);

  @override
  bool operator ==(Object other) =>
      other is AppMapMarkerId && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

class AppMapAnchor {
  final double x;
  final double y;
  const AppMapAnchor(this.x, this.y);

  static const center = AppMapAnchor(0.5, 0.5);
  static const bottom = AppMapAnchor(0.5, 1.0);
  static const top = AppMapAnchor(0.5, 0.0);
}

sealed class AppMapMarkerIcon {
  const AppMapMarkerIcon();
}

class AppMapMarkerIconDefault extends AppMapMarkerIcon {
  /// Hue 0..360 trên Google `BitmapDescriptor.defaultMarkerWithHue`.
  /// Provider không hỗ trợ hue (vd MapLibre) sẽ dùng marker mặc định của SDK.
  final double hue;
  const AppMapMarkerIconDefault({this.hue = 0});
}

class AppMapMarkerIconAsset extends AppMapMarkerIcon {
  final String assetPath;
  final double devicePixelRatio;
  const AppMapMarkerIconAsset({
    required this.assetPath,
    this.devicePixelRatio = 1.0,
  });
}

class AppMapMarkerIconBytes extends AppMapMarkerIcon {
  final Uint8List pngBytes;
  final double devicePixelRatio;
  const AppMapMarkerIconBytes({
    required this.pngBytes,
    this.devicePixelRatio = 1.0,
  });
}

class AppMapInfoWindow {
  final String? title;
  final String? snippet;
  const AppMapInfoWindow({this.title, this.snippet});
}

class AppMapMarker {
  final AppMapMarkerId id;
  final AppLatLng position;
  final AppMapMarkerIcon icon;
  final AppMapAnchor anchor;
  final int zIndex;
  final bool consumeTapEvents;
  final AppMapInfoWindow? infoWindow;
  final VoidCallback? onTap;

  const AppMapMarker({
    required this.id,
    required this.position,
    this.icon = const AppMapMarkerIconDefault(),
    this.anchor = AppMapAnchor.bottom,
    this.zIndex = 0,
    this.consumeTapEvents = false,
    this.infoWindow,
    this.onTap,
  });
}
