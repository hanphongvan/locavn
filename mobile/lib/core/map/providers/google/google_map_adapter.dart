import 'package:flutter/widgets.dart';

import '../../app_map_camera.dart';
import '../../app_map_marker.dart';
import '../../app_map_polyline.dart';
import '../../map_capability.dart';
import '../../map_provider_adapter.dart';
import '../../map_provider_kind.dart';
import 'google_map_widget.dart';

class GoogleMapAdapter extends MapProviderAdapter {
  GoogleMapAdapter();

  @override
  MapProviderKind get kind => MapProviderKind.google;

  @override
  String get displayName => 'Google Maps';

  @override
  Set<MapCapability> get capabilities => const {
        MapCapability.nativeClustering,
        MapCapability.heatmap,
        MapCapability.buildings3d,
        MapCapability.traffic,
      };

  @override
  Widget buildMap({
    required AppMapCameraPosition initialCameraPosition,
    Set<AppMapMarker> markers = const {},
    Set<AppMapPolyline> polylines = const {},
    EdgeInsets padding = EdgeInsets.zero,
    bool myLocationEnabled = false,
    bool myLocationButtonEnabled = false,
    bool zoomControlsEnabled = false,
    bool compassEnabled = true,
    double? minZoom,
    double? maxZoom,
    AppMapCreatedCallback? onMapCreated,
    AppMapTapCallback? onTap,
    AppMapCameraIdleCallback? onCameraIdle,
  }) {
    return GoogleMapWidget(
      initialCameraPosition: initialCameraPosition,
      markers: markers,
      polylines: polylines,
      padding: padding,
      myLocationEnabled: myLocationEnabled,
      myLocationButtonEnabled: myLocationButtonEnabled,
      zoomControlsEnabled: zoomControlsEnabled,
      compassEnabled: compassEnabled,
      minZoom: minZoom,
      maxZoom: maxZoom,
      onMapCreated: onMapCreated,
      onTap: onTap,
      onCameraIdle: onCameraIdle,
    );
  }
}
