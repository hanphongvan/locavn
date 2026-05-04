import 'package:flutter/widgets.dart';

import 'app_lat_lng.dart';
import 'app_map_camera.dart';
import 'app_map_controller.dart';
import 'app_map_marker.dart';
import 'app_map_polyline.dart';
import 'map_capability.dart';
import 'map_provider_kind.dart';

typedef AppMapCreatedCallback = void Function(AppMapController controller);
typedef AppMapTapCallback = void Function(AppLatLng position);
typedef AppMapCameraIdleCallback = void Function();

abstract class MapProviderAdapter {
  MapProviderKind get kind;
  Set<MapCapability> get capabilities;
  String get displayName;

  Widget buildMap({
    required AppMapCameraPosition initialCameraPosition,
    Set<AppMapMarker> markers = const {},
    Set<AppMapPolyline> polylines = const {},
    EdgeInsets padding = EdgeInsets.zero,
    bool myLocationEnabled = false,
    bool myLocationButtonEnabled = false,
    bool zoomControlsEnabled = false,
    bool compassEnabled = true,
    AppMapCreatedCallback? onMapCreated,
    AppMapTapCallback? onTap,
    AppMapCameraIdleCallback? onCameraIdle,
  });
}
