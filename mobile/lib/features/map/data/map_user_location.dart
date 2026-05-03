import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Outcome of requesting the device location for map features (nearest station, etc.).
sealed class MapUserLocationOutcome {}

final class MapUserLocationOk extends MapUserLocationOutcome {
  MapUserLocationOk(this.position);
  final LatLng position;
}

final class MapUserLocationDenied extends MapUserLocationOutcome {}

final class MapUserLocationDeniedForever extends MapUserLocationOutcome {}

final class MapUserLocationServiceDisabled extends MapUserLocationOutcome {}

/// Requests permission when needed, then a single current position (map feature only).
Future<MapUserLocationOutcome> requestMapUserLocation() async {
  var perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) {
    perm = await Geolocator.requestPermission();
  }
  if (perm == LocationPermission.denied) {
    return MapUserLocationDenied();
  }
  if (perm == LocationPermission.deniedForever) {
    return MapUserLocationDeniedForever();
  }

  final serviceOn = await Geolocator.isLocationServiceEnabled();
  if (!serviceOn) {
    return MapUserLocationServiceDisabled();
  }

  final pos = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
  );
  return MapUserLocationOk(LatLng(pos.latitude, pos.longitude));
}

/// Hiển thị snackbar phù hợp cho từng [MapUserLocationOutcome] không-OK.
///
/// - `Denied`: thông báo (không có action — user có thể thử lại sau).
/// - `DeniedForever`: thông báo + nút **Mở Cài đặt** → [Geolocator.openAppSettings].
/// - `ServiceDisabled`: thông báo + nút **Bật GPS** → [Geolocator.openLocationSettings].
/// - `Ok`: không làm gì (caller xử lý).
///
/// Caller pass thêm [featureLabel] để cá nhân hóa message (ví dụ "tìm cây xăng gần nhất").
void showMapUserLocationOutcomeSnackbar(
  BuildContext context,
  MapUserLocationOutcome outcome, {
  String? featureLabel,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  final feature = featureLabel ?? 'tính năng này';
  final SnackBar? snack = switch (outcome) {
    MapUserLocationOk() => null,
    MapUserLocationDenied() => SnackBar(
        content: Text('Cần quyền vị trí để $feature.'),
      ),
    MapUserLocationDeniedForever() => SnackBar(
        content: Text('Quyền vị trí đang bị tắt. Bật trong Cài đặt để $feature.'),
        action: SnackBarAction(
          label: 'Mở Cài đặt',
          onPressed: Geolocator.openAppSettings,
        ),
        duration: const Duration(seconds: 6),
      ),
    MapUserLocationServiceDisabled() => SnackBar(
        content: Text('GPS đang tắt. Bật Dịch vụ Vị trí để $feature.'),
        action: SnackBarAction(
          label: 'Bật GPS',
          onPressed: Geolocator.openLocationSettings,
        ),
        duration: const Duration(seconds: 6),
      ),
  };
  if (snack == null) return;
  messenger.showSnackBar(snack);
}
