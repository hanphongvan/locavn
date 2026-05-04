import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_map_camera.dart';
import 'app_map_marker.dart';
import 'app_map_polyline.dart';
import 'map_provider_adapter.dart';
import 'map_providers.dart';

class AppMap extends ConsumerWidget {
  final AppMapCameraPosition initialCameraPosition;
  final Set<AppMapMarker> markers;
  final Set<AppMapPolyline> polylines;
  final EdgeInsets padding;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final bool zoomControlsEnabled;
  final bool compassEnabled;
  final AppMapCreatedCallback? onMapCreated;
  final AppMapTapCallback? onTap;
  final AppMapCameraIdleCallback? onCameraIdle;

  const AppMap({
    super.key,
    required this.initialCameraPosition,
    this.markers = const {},
    this.polylines = const {},
    this.padding = EdgeInsets.zero,
    this.myLocationEnabled = false,
    this.myLocationButtonEnabled = false,
    this.zoomControlsEnabled = false,
    this.compassEnabled = true,
    this.onMapCreated,
    this.onTap,
    this.onCameraIdle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adapter = ref.watch(currentMapProviderAdapterProvider);
    return adapter.buildMap(
      initialCameraPosition: initialCameraPosition,
      markers: markers,
      polylines: polylines,
      padding: padding,
      myLocationEnabled: myLocationEnabled,
      myLocationButtonEnabled: myLocationButtonEnabled,
      zoomControlsEnabled: zoomControlsEnabled,
      compassEnabled: compassEnabled,
      onMapCreated: onMapCreated,
      onTap: onTap,
      onCameraIdle: onCameraIdle,
    );
  }
}
