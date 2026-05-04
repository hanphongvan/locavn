import 'app_lat_lng.dart';

class AppLatLngBounds {
  final AppLatLng southwest;
  final AppLatLng northeast;

  const AppLatLngBounds({
    required this.southwest,
    required this.northeast,
  });

  bool contains(AppLatLng point) {
    final inLat =
        point.latitude >= southwest.latitude && point.latitude <= northeast.latitude;
    final inLng = southwest.longitude <= northeast.longitude
        ? (point.longitude >= southwest.longitude &&
            point.longitude <= northeast.longitude)
        // Bao quanh kinh tuyến 180°: sw>ne nghĩa là vùng đi qua đường đổi ngày.
        : (point.longitude >= southwest.longitude ||
            point.longitude <= northeast.longitude);
    return inLat && inLng;
  }

  @override
  bool operator ==(Object other) =>
      other is AppLatLngBounds &&
      other.southwest == southwest &&
      other.northeast == northeast;

  @override
  int get hashCode => Object.hash(southwest, northeast);
}
