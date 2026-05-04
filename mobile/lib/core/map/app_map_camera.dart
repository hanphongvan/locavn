import 'app_lat_lng.dart';
import 'app_lat_lng_bounds.dart';

class AppMapCameraPosition {
  final AppLatLng target;
  final double zoom;
  final double bearing;
  final double tilt;

  const AppMapCameraPosition({
    required this.target,
    this.zoom = 13,
    this.bearing = 0,
    this.tilt = 0,
  });
}

sealed class AppMapCameraUpdate {
  const AppMapCameraUpdate();

  const factory AppMapCameraUpdate.newLatLng(AppLatLng latLng) =
      AppMapCameraUpdateNewLatLng;
  const factory AppMapCameraUpdate.newLatLngZoom(
    AppLatLng latLng,
    double zoom,
  ) = AppMapCameraUpdateNewLatLngZoom;
  const factory AppMapCameraUpdate.newCameraPosition(
    AppMapCameraPosition position,
  ) = AppMapCameraUpdateNewCameraPosition;
  const factory AppMapCameraUpdate.newLatLngBounds({
    required AppLatLngBounds bounds,
    double padding,
  }) = AppMapCameraUpdateNewLatLngBounds;
}

class AppMapCameraUpdateNewLatLng extends AppMapCameraUpdate {
  final AppLatLng latLng;
  const AppMapCameraUpdateNewLatLng(this.latLng);
}

class AppMapCameraUpdateNewLatLngZoom extends AppMapCameraUpdate {
  final AppLatLng latLng;
  final double zoom;
  const AppMapCameraUpdateNewLatLngZoom(this.latLng, this.zoom);
}

class AppMapCameraUpdateNewCameraPosition extends AppMapCameraUpdate {
  final AppMapCameraPosition position;
  const AppMapCameraUpdateNewCameraPosition(this.position);
}

class AppMapCameraUpdateNewLatLngBounds extends AppMapCameraUpdate {
  final AppLatLngBounds bounds;
  final double padding;
  const AppMapCameraUpdateNewLatLngBounds({
    required this.bounds,
    this.padding = 50,
  });
}
