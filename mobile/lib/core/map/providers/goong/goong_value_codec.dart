import 'package:maplibre_gl/maplibre_gl.dart' as ml;

import '../../app_lat_lng.dart';
import '../../app_lat_lng_bounds.dart';
import '../../app_map_camera.dart';

abstract final class GoongValueCodec {
  GoongValueCodec._();

  static ml.LatLng toLatLng(AppLatLng v) => ml.LatLng(v.latitude, v.longitude);

  static AppLatLng fromLatLng(ml.LatLng v) =>
      AppLatLng(v.latitude, v.longitude);

  static ml.LatLngBounds toBounds(AppLatLngBounds b) => ml.LatLngBounds(
        southwest: toLatLng(b.southwest),
        northeast: toLatLng(b.northeast),
      );

  static AppLatLngBounds fromBounds(ml.LatLngBounds b) => AppLatLngBounds(
        southwest: fromLatLng(b.southwest),
        northeast: fromLatLng(b.northeast),
      );

  static ml.CameraPosition toCameraPosition(AppMapCameraPosition p) =>
      ml.CameraPosition(
        target: toLatLng(p.target),
        zoom: p.zoom,
        bearing: p.bearing,
        tilt: p.tilt,
      );

  static AppMapCameraPosition fromCameraPosition(ml.CameraPosition p) =>
      AppMapCameraPosition(
        target: fromLatLng(p.target),
        zoom: p.zoom,
        bearing: p.bearing,
        tilt: p.tilt,
      );

  static ml.CameraUpdate toCameraUpdate(AppMapCameraUpdate u) {
    return switch (u) {
      AppMapCameraUpdateNewLatLng() =>
        ml.CameraUpdate.newLatLng(toLatLng(u.latLng)),
      AppMapCameraUpdateNewLatLngZoom() =>
        ml.CameraUpdate.newLatLngZoom(toLatLng(u.latLng), u.zoom),
      AppMapCameraUpdateNewCameraPosition() => ml.CameraUpdate.newCameraPosition(
          toCameraPosition(u.position),
        ),
      AppMapCameraUpdateNewLatLngBounds() =>
        ml.CameraUpdate.newLatLngBounds(
          toBounds(u.bounds),
          left: u.padding,
          right: u.padding,
          top: u.padding,
          bottom: u.padding,
        ),
      AppMapCameraUpdateZoomTo() => ml.CameraUpdate.zoomTo(u.zoom),
    };
  }
}
