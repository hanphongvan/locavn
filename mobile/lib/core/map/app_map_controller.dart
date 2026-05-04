import 'app_lat_lng_bounds.dart';
import 'app_map_camera.dart';

abstract class AppMapController {
  Future<void> animateCamera(AppMapCameraUpdate update);
  Future<void> moveCamera(AppMapCameraUpdate update);
  Future<AppMapCameraPosition?> getCameraPosition();
  Future<AppLatLngBounds?> getVisibleRegion();
  Future<double?> getZoomLevel();
}
