import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/map/app_lat_lng.dart';
import '../../../../stations/data/models/station_map_item.dart';
import '../../../../stations/data/models/station_spotlight_dto.dart';
import '../../../../stations/data/stations_api.dart';
import '../../../../map/data/map_discovery.dart';
import '../../../../map/data/map_geo.dart';
import '../../../../map/presentation/map_providers.dart';
import '../../../../map/presentation/map_spotlight_station.dart';

/// Một trạm gợi ý sau khi gọi spotlight + [resolveSpotlightToMapItem] (cùng luồng Bản đồ).
@immutable
class CitizenMapStationSuggestion {
  const CitizenMapStationSuggestion({
    required this.item,
    this.distanceKm,
    this.averageRating,
    this.reviewCount,
    this.priceRon95,
    this.needsEphemeralMarker = false,
  });

  final StationMapItem item;
  final double? distanceKm;
  final double? averageRating;
  final int? reviewCount;
  final double? priceRon95;

  /// Giống [resolveSpotlightToMapItem] — trạm chưa có trong tải bản đồ, cần marker tạm.
  final bool needsEphemeralMarker;
}

@immutable
class CitizenDashboardMapSuggestions {
  const CitizenDashboardMapSuggestions({
    this.nearest,
    this.topRated,
    this.cheapest,
    this.nearestNeedsLocation = false,
  });

  final CitizenMapStationSuggestion? nearest;
  final CitizenMapStationSuggestion? topRated;
  final CitizenMapStationSuggestion? cheapest;

  /// Không có tọa độ người dùng — không gọi được `GET /api/stations/nearest`.
  final bool nearestNeedsLocation;
}

CitizenMapStationSuggestion? _localNearestPick(AppLatLng user, List<StationMapItem> items) {
  if (items.isEmpty) return null;
  final ranked = MapDiscovery.nearest(items, user);
  final item = ranked.first;
  final km = mapHaversineKm(user.latitude, user.longitude, item.latitude, item.longitude);
  return CitizenMapStationSuggestion(
    item: item,
    distanceKm: km,
    averageRating: null,
    reviewCount: null,
    priceRon95: item.priceRon95,
    needsEphemeralMarker: false,
  );
}

CitizenMapStationSuggestion? _localCheapestPick(List<StationMapItem> items) {
  if (items.isEmpty) return null;
  final withPrice = items.where((e) => e.priceRon95 != null).toList();
  if (withPrice.isEmpty) return null;
  withPrice.sort((a, b) => a.priceRon95!.compareTo(b.priceRon95!));
  final item = withPrice.first;
  return CitizenMapStationSuggestion(
    item: item,
    distanceKm: null,
    averageRating: null,
    reviewCount: null,
    priceRon95: item.priceRon95,
    needsEphemeralMarker: false,
  );
}

Future<CitizenMapStationSuggestion?> _resolveSpotlight(
  StationsApi api,
  StationSpotlightDto spot,
  List<StationMapItem> items, {
  AppLatLng? origin,
}) async {
  final mapped = await resolveSpotlightToMapItem(api, spot, items);
  if (mapped == null) return null;
  final item = mapped.$1;
  var dist = spot.distanceKm;
  if (dist == null && origin != null) {
    dist = mapHaversineKm(origin.latitude, origin.longitude, item.latitude, item.longitude);
  }
  return CitizenMapStationSuggestion(
    item: item,
    distanceKm: dist,
    averageRating: spot.averageRating,
    reviewCount: spot.reviewCount,
    priceRon95: spot.priceRon95 ?? item.priceRon95,
    needsEphemeralMarker: mapped.$2,
  );
}

/// Gợi ý 3 trạm: gần nhất (GPS + `nearest` / fallback local), uy tín (`top-rated`), rẻ nhất (`cheapest` / fallback local).
///
/// Dùng cùng [stationMapMarkersFetchProvider], [mapFiltersProvider], [mapSheetUserOriginProvider] như Bản đồ.
final citizenDashboardMapSuggestionsProvider =
    FutureProvider.autoDispose<CitizenDashboardMapSuggestions>((ref) async {
  final api = ref.read(stationsApiProvider);

  final rawMarkers = await ref.watch(stationMapMarkersFetchProvider.future);
  final filters = ref.watch(mapFiltersProvider);
  final items = applyMapClientSideFilters(rawMarkers, filters).items;

  final origin = await ref.watch(mapSheetUserOriginProvider.future);

  CitizenMapStationSuggestion? nearest;
  var nearestNeedsLocation = false;

  if (origin == null) {
    nearestNeedsLocation = true;
  } else {
    try {
      final spot = await api.getNearestSpotlight(lat: origin.latitude, lng: origin.longitude);
      nearest = await _resolveSpotlight(api, spot, items, origin: origin);
    } catch (_) {
      nearest = null;
    }
    nearest ??= _localNearestPick(origin, items);
  }

  CitizenMapStationSuggestion? topRated;
  try {
    final spot = await api.getTopRatedSpotlight();
    topRated = await _resolveSpotlight(api, spot, items, origin: origin);
  } catch (_) {
    topRated = null;
  }

  CitizenMapStationSuggestion? cheapest;
  try {
    final spot = await api.getCheapestSpotlight(fuelType: 'ron95');
    cheapest = await _resolveSpotlight(api, spot, items, origin: origin);
  } catch (_) {
    cheapest = null;
  }
  cheapest ??= _localCheapestPick(items);

  return CitizenDashboardMapSuggestions(
    nearest: nearest,
    topRated: topRated,
    cheapest: cheapest,
    nearestNeedsLocation: nearestNeedsLocation,
  );
});
