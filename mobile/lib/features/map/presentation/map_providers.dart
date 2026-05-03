import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../stations/data/models/station_map_item.dart';
import '../../store_services/data/models/store_service_catalog_item.dart';
import '../../stations/data/models/station_map_markers_load_result.dart';
import '../../stations/data/stations_api.dart';
import '../data/map_discovery.dart';
import '../data/map_filters.dart';
import '../data/map_geo.dart';

final mapFiltersProvider = StateProvider<MapFilters>((ref) => const MapFilters());

/// Public store-service catalog for map filter chips (same payload as admin catalog).
final stationStoreServiceCatalogProvider =
    FutureProvider.autoDispose<List<StoreServiceCatalogItem>>((ref) async {
  final api = ref.watch(stationsApiProvider);
  return api.getStoreServicesCatalog();
});

/// Chỉ các trường kích hoạt tải lại từ API (`GET /api/stations/map` + ∩ danh sách từ khóa).
@immutable
class MapApiFilterKey {
  const MapApiFilterKey({
    required this.provinceCode,
    required this.districtCode,
    required this.keyword,
    required this.status,
  });

  final String? provinceCode;
  final String? districtCode;
  final String? keyword;
  final String? status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapApiFilterKey &&
          runtimeType == other.runtimeType &&
          provinceCode == other.provinceCode &&
          districtCode == other.districtCode &&
          keyword == other.keyword &&
          status == other.status;

  @override
  int get hashCode => Object.hash(provinceCode, districtCode, keyword, status);
}

final mapApiFilterKeyProvider = Provider<MapApiFilterKey>((ref) {
  final f = ref.watch(mapFiltersProvider);
  String? norm(String? x) {
    final t = x?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  final kw = f.keyword?.trim();
  return MapApiFilterKey(
    provinceCode: norm(f.provinceCode),
    districtCode: norm(f.districtCode),
    keyword: (kw == null || kw.isEmpty) ? null : kw,
    status: _statusQuery(f.status),
  );
});

/// Giá hiển thị trên marker (khi có hồ sơ phương tiện sẽ đồng bộ từ đó — TODO).
enum MapMarkerFuelPriceMode { ron95, diesel }

final mapMarkerFuelPriceModeProvider = StateProvider<MapMarkerFuelPriceMode>(
  (ref) => MapMarkerFuelPriceMode.ron95,
);

/// Google Map controller từ [MapStationMapBody] — dùng nút zoom / vị trí.
final mapGoogleMapControllerProvider = StateProvider<GoogleMapController?>((ref) => null);

/// Sắp xếp danh sách trạm trong bottom sheet (client-side, dữ liệu đã tải).
enum MapStationListSort {
  distanceAsc,
  priceRon95Asc,
  /// TODO: Khi API trả về điểm uy tín theo lô trạm, sắp xếp theo trường đó.
  ratingDescPlaceholder,
}

final mapStationListSortProvider = StateProvider<MapStationListSort>(
  (ref) => MapStationListSort.distanceAsc,
);

/// Vị trí người dùng để tính khoảng cách trong sheet (không tạo dữ liệu giả).
///
/// [FutureProvider] (không autoDispose) để đổi tab rồi quay lại Bản đồ không gọi lại GPS.
final mapSheetUserOriginProvider = FutureProvider<LatLng?>((ref) async {
  var perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) {
    perm = await Geolocator.requestPermission();
  }
  if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
    return null;
  }
  final pos = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
  );
  // Defensive: GPS có thể trả NaN/Inf khi sensor lỗi — bỏ qua để consumer không tạo `LatLng` invalid.
  if (!StationMapItem.isValidCoord(pos.latitude, pos.longitude)) {
    return null;
  }
  return LatLng(pos.latitude, pos.longitude);
});

/// Danh sách trạm đã tải + sắp xếp theo [mapStationListSortProvider] và GPS nếu có.
final mapSortedStationSheetItemsProvider = Provider<List<StationMapItem>>((ref) {
  final asyncMarkers = ref.watch(stationMapMarkersProvider);
  final sort = ref.watch(mapStationListSortProvider);
  final origin = ref.watch(mapSheetUserOriginProvider).valueOrNull;

  final items = asyncMarkers.asData?.value.items;
  if (items == null || items.isEmpty) return const [];

  final copy = List<StationMapItem>.from(items);
  switch (sort) {
    case MapStationListSort.distanceAsc:
      if (origin != null) {
        copy.sort((a, b) {
          final da = mapHaversineKm(origin.latitude, origin.longitude, a.latitude, a.longitude);
          final db = mapHaversineKm(origin.latitude, origin.longitude, b.latitude, b.longitude);
          return da.compareTo(db);
        });
      }
      break;
    case MapStationListSort.priceRon95Asc:
      double key(StationMapItem s) => s.priceRon95 ?? double.nan;
      copy.sort((a, b) {
        final ka = key(a);
        final kb = key(b);
        if (ka.isNaN && kb.isNaN) return a.stationId.compareTo(b.stationId);
        if (ka.isNaN) return 1;
        if (kb.isNaN) return -1;
        return ka.compareTo(kb);
      });
      break;
    case MapStationListSort.ratingDescPlaceholder:
      // TODO(api): sắp xếp theo ratingSummary khi có endpoint lô hoặc trường trên DTO map.
      copy.sort((a, b) => a.stationName.compareTo(b.stationName));
      break;
  }
  return copy;
});

/// Tải trạm từ máy chủ (chỉ phụ thuộc [mapApiFilterKeyProvider]).
///
/// [FutureProvider] (không autoDispose): giữ kết quả khi rời tab Bản đồ — tránh tải lại toàn bộ marker
/// mỗi lần quay lại (IndexedStack vẫn giữ widget nhưng autoDispose có thể hủy cache khi không còn listener).
final stationMapMarkersFetchProvider = FutureProvider<StationMapMarkersLoadResult>((ref) async {
  final key = ref.watch(mapApiFilterKeyProvider);
  final api = ref.watch(stationsApiProvider);

  final mapResult = await api.loadMapMarkersPaged(
    provinceCode: key.provinceCode,
    districtCode: key.districtCode,
    status: key.status,
  );

  final kw = key.keyword;
  if (kw == null || kw.isEmpty) {
    return StationMapMarkersLoadResult(
      items: mapResult.items,
      mapTotalCount: mapResult.mapTotalCount,
      truncated: mapResult.truncated,
    );
  }

  final idResult = await api.collectStationIdsForKeyword(
    keyword: kw,
    provinceCode: key.provinceCode,
    districtCode: key.districtCode,
    status: key.status,
  );
  final filtered = mapResult.items.where((m) => idResult.ids.contains(m.stationId)).toList();

  return StationMapMarkersLoadResult(
    items: filtered,
    mapTotalCount: mapResult.mapTotalCount,
    truncated: mapResult.truncated,
    keywordApplied: true,
    keywordListTruncated: idResult.listTruncated,
  );
});

bool _stationPassesClientFilters(StationMapItem m, MapFilters f) {
  switch (f.unitType) {
    case MapUnitTypeFilter.all:
    case MapUnitTypeFilter.retail:
      break;
    case MapUnitTypeFilter.wholesale:
      return false;
  }

  switch (f.fuelType) {
    case MapFuelTypeFilter.all:
    case MapFuelTypeFilter.lpg:
      break;
    case MapFuelTypeFilter.petrol:
      if (m.priceRon95 == null) return false;
      break;
    case MapFuelTypeFilter.diesel:
      if (m.priceDiesel == null) return false;
      break;
  }

  if (f.hasPriceFilter) {
    final lo = f.priceMinDong.toDouble();
    final hi = f.priceMaxDong.toDouble();
    final prices = <double>[
      if (m.priceRon95 != null) m.priceRon95!,
      if (m.priceDiesel != null) m.priceDiesel!,
    ];
    if (prices.isEmpty) return false;
    final inBand = prices.any((p) => p >= lo && p <= hi);
    if (!inBand) return false;
  }

  if (f.selectedServiceCodes.isNotEmpty) {
    final stationCodes = m.activeServiceCodes.map((c) => c.toUpperCase()).toSet();
    for (final sel in f.selectedServiceCodes) {
      if (!stationCodes.contains(sel.toUpperCase())) return false;
    }
  }

  // Đánh giá: DTO map chưa có điểm — giữ nguyên danh sách (chip vẫn hiện trong tóm tắt).
  return true;
}

/// Cùng logic lọc chip với [stationMapMarkersProvider] — dùng cho gợi ý Dashboard Citizen.
///
/// Cũng loại bỏ trạm có tọa độ không hợp lệ (`NaN`, `Infinity`, vượt ±90/±180) để các consumer
/// (`MapStationMapBody`, distance sort, …) không phải lo trường hợp `LatLng` lỗi.
StationMapMarkersLoadResult applyMapClientSideFilters(
  StationMapMarkersLoadResult raw,
  MapFilters filters,
) {
  final loadedCount = raw.items.length;
  final filtered = raw.items
      .where((m) => m.hasValidCoord && _stationPassesClientFilters(m, filters))
      .toList();
  return StationMapMarkersLoadResult(
    items: filtered,
    mapTotalCount: raw.mapTotalCount,
    truncated: raw.truncated,
    keywordApplied: raw.keywordApplied,
    keywordListTruncated: raw.keywordListTruncated,
    loadedItemCount: loadedCount,
  );
}

/// Kết quả hiển thị bản đồ: [stationMapMarkersFetchProvider] + lọc chip client-side.
final stationMapMarkersProvider = Provider<AsyncValue<StationMapMarkersLoadResult>>((ref) {
  final raw = ref.watch(stationMapMarkersFetchProvider);
  final filters = ref.watch(mapFiltersProvider);
  return raw.when(
    data: (data) => AsyncValue.data(applyMapClientSideFilters(data, filters)),
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

/// When set, [MapShellPage] animates the camera here then clears the value.
final mapCameraTargetProvider = StateProvider<LatLng?>((ref) => null);

/// Marker highlight driven from search / discovery (not only marker tap).
final mapHighlightStationIdProvider = StateProvider<int?>((ref) => null);

/// One station not in [stationMapMarkersProvider] (e.g. global nearest outside current filter) — drawn until cleared.
final mapEphemeralStationProvider = StateProvider<StationMapItem?>((ref) => null);

/// Station id from “giá rẻ nhất” spotlight — drives [station_cheap.png] when that station is open.
final mapCheapSpotlightStationIdProvider = StateProvider<int?>((ref) => null);

/// Quick filter chip selection (nearest / cheapest / …).
final mapDiscoveryShortcutProvider = StateProvider<MapDiscoveryShortcut>(
  (ref) => MapDiscoveryShortcut.none,
);

String? _statusQuery(String? raw) {
  final s = raw?.trim().toLowerCase();
  if (s == null || s.isEmpty || s == 'all') {
    return null;
  }
  if (s == 'open' || s == 'closed') {
    return s;
  }
  return null;
}

/// Clears the cheapest-spotlight marker id (filters, dismiss overlays, after focus flow).
///
/// Tránh cập nhật provider đồng bộ từ [State.dispose] (Riverpod cấm khi cây widget đang finalize).
/// Dùng [ProviderContainer] đã lưu + [WidgetsBinding.instance.addPostFrameCallback], hoặc gọi hàm này khi [ref] còn hợp lệ.
void mapClearCheapSpotlightMarker(WidgetRef ref) {
  ref.read(mapCheapSpotlightStationIdProvider.notifier).state = null;
}
