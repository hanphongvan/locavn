import 'package:flutter/widgets.dart' show Offset;

import 'app_lat_lng.dart';
import 'app_lat_lng_bounds.dart';
import 'app_map_camera.dart';

abstract class AppMapController {
  Future<void> animateCamera(AppMapCameraUpdate update);
  Future<void> moveCamera(AppMapCameraUpdate update);
  Future<AppMapCameraPosition?> getCameraPosition();
  Future<AppLatLngBounds?> getVisibleRegion();
  Future<double?> getZoomLevel();

  /// Geographic point → toạ độ pixel trên màn hình (origin top-left của map view).
  /// Trả về `null` nếu provider không hỗ trợ hoặc point nằm ngoài viewport.
  Future<Offset?> getScreenCoordinate(AppLatLng latLng);
}
