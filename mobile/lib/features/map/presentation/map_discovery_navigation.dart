import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/map/app_lat_lng.dart';
import '../../stations/data/models/station_map_item.dart';
import '../data/map_discovery.dart';
import 'map_providers.dart';
import 'station_map_preview_sheet.dart';

/// Move camera, highlight marker, open summary — used from discovery results.
Future<void> focusMapStationAndOpenSummary(
  BuildContext context,
  WidgetRef ref,
  StationMapItem item, {
  double? distanceKm,
}) async {
  ref.read(mapDiscoveryShortcutProvider.notifier).state = MapDiscoveryShortcut.none;
  ref.read(mapHighlightStationIdProvider.notifier).state = item.stationId;
  ref.read(mapCameraTargetProvider.notifier).state = AppLatLng(item.latitude, item.longitude);
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
