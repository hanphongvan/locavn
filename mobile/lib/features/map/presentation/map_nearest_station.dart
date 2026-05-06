import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/map/app_lat_lng.dart';
import '../../../core/network/api_exception.dart';
import '../../stations/data/models/station_map_item.dart';
import '../../stations/data/stations_api.dart';
import '../data/map_discovery.dart';
import '../data/map_geo.dart';
import '../data/map_user_location.dart';
import 'map_discovery_navigation.dart';
import 'map_discovery_results_sheet.dart';
import 'map_providers.dart';
import 'map_spotlight_station.dart';

/// Resolves nearest station: `GET /api/stations/nearest` first; on recoverable API errors, rank [loadedItems] locally.
Future<
    ({
      StationMapItem item,
      double? distanceKm,
      bool needsEphemeralMarker,
      double? spotlightAverageRating,
      int? spotlightReviewCount,
    })?> resolveNearestStation({
  required WidgetRef ref,
  required AppLatLng user,
  required List<StationMapItem> loadedItems,
}) async {
  final api = ref.read(stationsApiProvider);

  try {
    final spot = await api.getNearestSpotlight(lat: user.latitude, lng: user.longitude);
    final mapped = await resolveSpotlightToMapItem(api, spot, loadedItems);
    if (mapped != null) {
      final double? distKm = spot.distanceKm;
      return (
        item: mapped.$1,
        distanceKm: distKm,
        needsEphemeralMarker: mapped.$2,
        spotlightAverageRating: spot.averageRating,
        spotlightReviewCount: spot.reviewCount,
      );
    }
    return _localNearest(user, loadedItems);
  } on ApiException catch (e) {
    if (e.statusCode == 404) {
      return null;
    }
    return _localNearest(user, loadedItems);
  } catch (_) {
    return _localNearest(user, loadedItems);
  }
}

({
  StationMapItem item,
  double? distanceKm,
  bool needsEphemeralMarker,
  double? spotlightAverageRating,
  int? spotlightReviewCount,
})? _localNearest(
  AppLatLng user,
  List<StationMapItem> loadedItems,
) {
  if (loadedItems.isEmpty) return null;
  final ranked = MapDiscovery.nearest(loadedItems, user);
  if (ranked.isEmpty) return null;
  final item = ranked.first;
  final km = mapHaversineKm(user.latitude, user.longitude, item.latitude, item.longitude);
  return (
    item: item,
    distanceKm: km,
    needsEphemeralMarker: false,
    spotlightAverageRating: null,
    spotlightReviewCount: null,
  );
}

/// Permission → nearest (API or local on loaded markers) → move map, highlight, bottom sheet.
///
/// [onResolveDone] (nếu có) được gọi đúng một lần khi giai đoạn xử lý GPS + API kết thúc —
/// bất kể tiếp theo là mở sheet, snackbar lỗi, hay return sớm — để caller tắt spinner trên chip.
Future<void> presentNearestPetrolStation(
  BuildContext context,
  WidgetRef ref, {
  VoidCallback? onResolveDone,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  var resolveDoneFired = false;
  void fireResolveDone() {
    if (resolveDoneFired) return;
    resolveDoneFired = true;
    onResolveDone?.call();
  }

  final items = ref.read(stationMapMarkersProvider).asData?.value.items ?? const <StationMapItem>[];
  if (items.isEmpty) {
    fireResolveDone();
    messenger?.showSnackBar(
      const SnackBar(content: Text('Chưa có dữ liệu cây xăng trên bản đồ — tải xong rồi thử lại.')),
    );
    return;
  }

  final loc = await requestMapUserLocation(
    acceptLastKnownMaxAge: const Duration(minutes: 2),
  );
  if (!context.mounted) {
    fireResolveDone();
    return;
  }

  final AppLatLng user;
  switch (loc) {
    case MapUserLocationDenied():
    case MapUserLocationDeniedForever():
    case MapUserLocationServiceDisabled():
    case MapUserLocationGnssTimeout():
      fireResolveDone();
      showMapUserLocationOutcomeSnackbar(
        context,
        loc,
        featureLabel: 'tìm cây xăng gần nhất',
      );
      return;
    case MapUserLocationOk(:final position):
      user = position;
  }

  final resolved = await resolveNearestStation(ref: ref, user: user, loadedItems: items);
  if (!context.mounted) {
    fireResolveDone();
    return;
  }

  if (resolved == null) {
    fireResolveDone();
    messenger?.showSnackBar(
      const SnackBar(content: Text('Không tìm thấy cây xăng gần bạn trên máy chủ.')),
    );
    return;
  }

  if (resolved.needsEphemeralMarker) {
    ref.read(mapEphemeralStationProvider.notifier).state = resolved.item;
  }

  fireResolveDone();
  final d = resolved.distanceKm;
  await showMapDiscoveryResultsSheet(
    context: context,
    rows: [
      MapStationListRow(
        item: resolved.item,
        distanceKm: d,
        spotlightAverageRating: resolved.spotlightAverageRating,
        spotlightReviewCount: resolved.spotlightReviewCount,
      ),
    ],
    title: 'Gần nhất',
    subtitle: 'Các cửa hàng gần vị trí của bạn',
    chrome: MapDiscoverySheetChrome.nearest,
    emptySubtitle: 'Vui lòng thử thay đổi bộ lọc hoặc khu vực tìm kiếm',
    initialChildSize: 0.34,
    onStationChosen: (row) async {
      final item = row.item;
      if (resolved.needsEphemeralMarker) {
        ref.read(mapEphemeralStationProvider.notifier).state = item;
      }
      await focusMapStationAndOpenSummary(
        context,
        ref,
        item,
        distanceKm: row.distanceKm,
      );
    },
  );
}
