import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmf;

import '../../app_map_camera.dart';
import '../../app_map_marker.dart';
import '../../app_map_polyline.dart';
import '../../map_provider_adapter.dart';
import 'google_map_controller.dart';
import 'google_value_codec.dart';

class GoogleMapWidget extends StatelessWidget {
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

  const GoogleMapWidget({
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
  Widget build(BuildContext context) {
    return gmf.GoogleMap(
      initialCameraPosition:
          GoogleValueCodec.toCameraPosition(initialCameraPosition),
      markers: markers.map(_toGoogleMarker).toSet(),
      polylines: polylines.map(_toGooglePolyline).toSet(),
      padding: padding,
      mapToolbarEnabled: false,
      zoomControlsEnabled: zoomControlsEnabled,
      compassEnabled: compassEnabled,
      myLocationEnabled: myLocationEnabled,
      myLocationButtonEnabled: myLocationButtonEnabled,
      onMapCreated: (c) {
        onMapCreated?.call(GoogleAppMapController(c));
      },
      onTap: onTap == null
          ? null
          : (gmf.LatLng pos) => onTap!(GoogleValueCodec.fromLatLng(pos)),
      onCameraIdle: onCameraIdle,
    );
  }
}

gmf.Marker _toGoogleMarker(AppMapMarker m) {
  final iw = m.infoWindow;
  return gmf.Marker(
    markerId: gmf.MarkerId(m.id.value),
    position: GoogleValueCodec.toLatLng(m.position),
    icon: _resolveIcon(m.icon),
    anchor: Offset(m.anchor.x, m.anchor.y),
    zIndexInt: m.zIndex,
    consumeTapEvents: m.consumeTapEvents,
    infoWindow: iw == null
        ? gmf.InfoWindow.noText
        : gmf.InfoWindow(title: iw.title, snippet: iw.snippet),
    onTap: m.onTap,
  );
}

/// `BytesMapBitmap` / `AssetMapBitmap` đều dựng descriptor đồng bộ — platform tự
/// load asset / decode PNG khi marker render. Không cần async pre-resolve.
gmf.BitmapDescriptor _resolveIcon(AppMapMarkerIcon icon) {
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

gmf.Polyline _toGooglePolyline(AppMapPolyline p) {
  return gmf.Polyline(
    polylineId: gmf.PolylineId(p.id.value),
    points: p.points.map(GoogleValueCodec.toLatLng).toList(),
    color: p.color,
    width: p.width.round(),
    geodesic: p.geodesic,
  );
}
