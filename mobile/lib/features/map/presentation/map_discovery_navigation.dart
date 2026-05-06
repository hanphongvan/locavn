import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/map/app_lat_lng.dart';
import '../../../core/map/app_map_camera.dart';
import '../../stations/data/models/station_map_item.dart';
import '../data/map_discovery.dart';
import '../data/map_geo.dart';
import 'map_providers.dart';
import 'station_map_preview_sheet.dart';

/// Khi station cách [framingOrigin] xa hơn ngưỡng này, dùng `newLatLngBounds(user, station)`
/// để cả vị trí người dùng và trạm cùng nằm trong khung — tránh "kết quả ở đâu đó ngoài kia,
/// không thấy đường đến". Ngưỡng đặt ở 5 km cho hợp với mật độ cây xăng đô thị VN.
const double kMapFramingBoundsThresholdKm = 5.0;

/// Move camera, highlight marker, open summary — used from discovery results.
///
/// [framingOrigin] (nếu có cùng [distanceKm]): khi trạm cách origin > [kMapFramingBoundsThresholdKm]
/// thì dùng `animateCamera(newLatLngBounds(...))` qua [mapAppMapControllerProvider] để khung
/// vừa cả 2 điểm; còn lại giữ hành vi cũ (zoom 13 quanh trạm).
Future<void> focusMapStationAndOpenSummary(
  BuildContext context,
  WidgetRef ref,
  StationMapItem item, {
  double? distanceKm,
  AppLatLng? framingOrigin,
}) async {
  ref.read(mapDiscoveryShortcutProvider.notifier).state = MapDiscoveryShortcut.none;
  ref.read(mapHighlightStationIdProvider.notifier).state = item.stationId;

  final stationLatLng = AppLatLng(item.latitude, item.longitude);
  final shouldFitBounds = framingOrigin != null
      && distanceKm != null
      && distanceKm > kMapFramingBoundsThresholdKm;
  final controller = shouldFitBounds ? ref.read(mapAppMapControllerProvider) : null;
  if (shouldFitBounds && controller != null) {
    final bounds = mapBoundsForPoints([framingOrigin, stationLatLng]);
    // padding = 80 px để 2 marker không dính sát mép (chrome trên + sheet dưới sẽ che thêm).
    unawaited(controller.animateCamera(
      AppMapCameraUpdate.newLatLngBounds(bounds: bounds, padding: 80),
    ));
  } else {
    // Fallback (controller chưa ready hoặc trạm gần): provider-based single-target zoom.
    ref.read(mapCameraTargetProvider.notifier).state = stationLatLng;
  }
  await Future<void>.delayed(const Duration(milliseconds: 420));
  if (!context.mounted) return;
  try {
    await showStationMapPreviewSheet(
      context: context,
      station: item,
      spotlightDistanceKm: distanceKm,
    );
  } finally {
    if (context.mounted) {
      ref.read(mapHighlightStationIdProvider.notifier).state = null;
      ref.read(mapEphemeralStationProvider.notifier).state = null;
      mapClearCheapSpotlightMarker(ref);
    }
  }
}
