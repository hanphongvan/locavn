import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/map/app_lat_lng.dart';

/// Outcome of requesting the device location for map features (nearest station, etc.).
sealed class MapUserLocationOutcome {}

final class MapUserLocationOk extends MapUserLocationOutcome {
  MapUserLocationOk(this.position);
  final AppLatLng position;
}

final class MapUserLocationDenied extends MapUserLocationOutcome {}

final class MapUserLocationDeniedForever extends MapUserLocationOutcome {}

final class MapUserLocationServiceDisabled extends MapUserLocationOutcome {}

/// GNSS không trả về trong thời gian chờ và không có vị trí cache.
final class MapUserLocationGnssTimeout extends MapUserLocationOutcome {}

/// Requests permission when needed, then a single position (map feature only).
///
/// [acceptLastKnownMaxAge]: nếu > 0, thử [Geolocator.getLastKnownPosition] trước khi gọi GNSS —
/// tránh chờ lây khi vừa lấy vị trí (vd. bật lớp cửa hàng rồi bấm Gần nhất / Rẻ nhất).
///
/// [getCurrentPosition] dùng [LocationAccuracy.low] + [timeLimit] để TTFF nhanh hơn
/// [LocationAccuracy.medium] và không treo vô hạn khi tín hiệu kém.
Future<MapUserLocationOutcome> requestMapUserLocation({
  Duration acceptLastKnownMaxAge = Duration.zero,
}) async {
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

  if (acceptLastKnownMaxAge > Duration.zero) {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        final age = DateTime.now().difference(last.timestamp);
        if (age <= acceptLastKnownMaxAge) {
          return MapUserLocationOk(AppLatLng(last.latitude, last.longitude));
        }
      }
    } catch (_) {}
  }

  try {
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 20),
      ),
    );
    return MapUserLocationOk(AppLatLng(pos.latitude, pos.longitude));
  } on TimeoutException catch (_) {
    final last = await Geolocator.getLastKnownPosition();
    if (last != null) {
      return MapUserLocationOk(AppLatLng(last.latitude, last.longitude));
    }
    return MapUserLocationGnssTimeout();
  }
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
    MapUserLocationGnssTimeout() => SnackBar(
        content: Text(
          'Chậm lấy vị trí GPS. Thử lại sau vài giây hoặc ra nơi sóng tốt hơn để $feature.',
        ),
        duration: const Duration(seconds: 5),
      ),
  };
  if (snack == null) return;
  messenger.showSnackBar(snack);
}
