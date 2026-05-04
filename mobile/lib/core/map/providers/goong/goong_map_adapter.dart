import 'package:flutter/widgets.dart';

import '../../app_map_camera.dart';
import '../../app_map_marker.dart';
import '../../app_map_polyline.dart';
import '../../map_capability.dart';
import '../../map_provider_adapter.dart';
import '../../map_provider_kind.dart';
import 'goong_map_widget.dart';
import 'goong_style.dart';

enum GoongStyleVariant { highlight, satellite }

class GoongMapAdapter extends MapProviderAdapter {
  final String mapTilesKey;
  final String? restApiKey;
  final GoongStyleVariant styleVariant;

  GoongMapAdapter({
    required this.mapTilesKey,
    this.restApiKey,
    this.styleVariant = GoongStyleVariant.highlight,
  }) {
    if (mapTilesKey.trim().isEmpty) {
      throw ArgumentError(
        'GoongMapAdapter requires non-empty mapTilesKey '
        '(--dart-define=GOONG_MAPTILES_KEY=...).',
      );
    }
  }

  @override
  MapProviderKind get kind => MapProviderKind.goong;

  @override
  String get displayName => 'Goong (MapLibre)';

  @override
  Set<MapCapability> get capabilities => const {
        MapCapability.vectorStyle,
        MapCapability.offline,
      };

  String get _styleUrl => switch (styleVariant) {
        GoongStyleVariant.highlight => GoongStyle.highlight(mapTilesKey),
        GoongStyleVariant.satellite => GoongStyle.satellite(mapTilesKey),
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
    return GoongMapWidget(
      styleUrl: _styleUrl,
      initialCameraPosition: initialCameraPosition,
      markers: markers,
      polylines: polylines,
      padding: padding,
      myLocationEnabled: myLocationEnabled,
      compassEnabled: compassEnabled,
      minZoom: minZoom,
      maxZoom: maxZoom,
      onMapCreated: onMapCreated,
      onTap: onTap,
      onCameraIdle: onCameraIdle,
    );
  }
}
