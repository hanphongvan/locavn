import 'package:flutter/widgets.dart' show Offset;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmf;

import '../../app_map_marker.dart';

/// Convert `AppMapMarkerIcon` → `gmf.BitmapDescriptor`. Để code chưa migrate
/// sang `AppMap` (vẫn dùng `GoogleMap` widget trực tiếp) tận dụng được helper
/// dùng chung như `MapStationMarkerFactory.iconFor` / `MapStationMarkerComposer.buildIcon`.
gmf.BitmapDescriptor googleBitmapFromAppIcon(AppMapMarkerIcon icon) {
  switch (icon) {
    case AppMapMarkerIconDefault():
      return gmf.BitmapDescriptor.defaultMarkerWithHue(icon.hue);
    case AppMapMarkerIconBytes():
      return gmf.BytesMapBitmap(
        icon.pngBytes,
        imagePixelRatio: icon.devicePixelRatio,
      );
    case AppMapMarkerIconAsset():
      return gmf.AssetMapBitmap(
        icon.assetPath,
        imagePixelRatio: icon.devicePixelRatio,
      );
  }
}

/// `AppMapAnchor` (x, y trong [0..1]) → `Offset` (x, y) cho `gmf.Marker.anchor`.
Offset googleAnchorFromApp(AppMapAnchor a) => Offset(a.x, a.y);
