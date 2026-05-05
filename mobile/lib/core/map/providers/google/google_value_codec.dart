import 'package:google_maps_flutter/google_maps_flutter.dart' as gmf;

import '../../app_lat_lng.dart';
import '../../app_lat_lng_bounds.dart';
import '../../app_map_camera.dart';

abstract final class GoogleValueCodec {
  GoogleValueCodec._();

  static gmf.LatLng toLatLng(AppLatLng v) =>
      gmf.LatLng(v.latitude, v.longitude);

  static AppLatLng fromLatLng(gmf.LatLng v) =>
      AppLatLng(v.latitude, v.longitude);

  static gmf.LatLngBounds toBounds(AppLatLngBounds b) => gmf.LatLngBounds(
        southwest: toLatLng(b.southwest),
        northeast: toLatLng(b.northeast),
      );

  static AppLatLngBounds fromBounds(gmf.LatLngBounds b) => AppLatLngBounds(
        southwest: fromLatLng(b.southwest),
        northeast: fromLatLng(b.northeast),
      );

  static gmf.CameraPosition toCameraPosition(AppMapCameraPosition p) =>
      gmf.CameraPosition(
        target: toLatLng(p.target),
        zoom: p.zoom,
        bearing: p.bearing,
        tilt: p.tilt,
      );

  static AppMapCameraPosition fromCameraPosition(gmf.CameraPosition p) =>
      AppMapCameraPosition(
        target: fromLatLng(p.target),
        zoom: p.zoom,
        bearing: p.bearing,
        tilt: p.tilt,
      );

  static gmf.CameraUpdate toCameraUpdate(AppMapCameraUpdate u) {
    return switch (u) {
      AppMapCameraUpdateNewLatLng() => gmf.CameraUpdate.newLatLng(
          toLatLng(u.latLng),
        ),
      AppMapCameraUpdateNewLatLngZoom() => gmf.CameraUpdate.newLatLngZoom(
          toLatLng(u.latLng),
          u.zoom,
        ),
      AppMapCameraUpdateNewCameraPosition() =>
        gmf.CameraUpdate.newCameraPosition(toCameraPosition(u.position)),
      AppMapCameraUpdateNewLatLngBounds() => gmf.CameraUpdate.newLatLngBounds(
          toBounds(u.bounds),
          u.padding,
        ),
      AppMapCameraUpdateZoomTo() => gmf.CameraUpdate.zoomTo(u.zoom),
    };
  }
}
