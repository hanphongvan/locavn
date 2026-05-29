import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/map/app_lat_lng.dart';
import '../../../core/map/app_map_controller.dart';
import '../../stations/data/models/fuel_product_leaf.dart';
import '../../stations/data/models/station_distributor.dart';
import '../../stations/data/models/station_map_item.dart';
import '../../store_services/data/models/store_service_catalog_item.dart';
import '../../stations/data/models/station_map_markers_load_result.dart';
import '../../stations/data/models/station_map_province_cluster.dart';
import '../../stations/data/stations_api.dart';
import '../data/map_discovery.dart';
import '../data/map_filters.dart';
import '../data/map_geo.dart';
import '../data/map_user_location.dart';
import 'map_viewport_state.dart';

final mapFiltersProvider = StateProvider<MapFilters>((ref) => const MapFilters());

/// Đầu mối (CapDonViId=235) có trạm bán lẻ — dùng cho bottom sheet lọc brand
/// trên thanh tìm kiếm. Không autoDispose để cache giữa các lần mở sheet.
final mapDistributorsProvider =
    FutureProvider<List<StationDistributor>>((ref) async {
  final api = ref.watch(stationsApiProvider);
  return api.getDistributors();
});

/// Public store-service catalog for map filter chips (same payload as admin catalog).
final stationStoreServiceCatalogProvider =
    FutureProvider.autoDispose<List<StoreServiceCatalogItem>>((ref) async {
  final api = ref.watch(stationsApiProvider);
  return api.getStoreServicesCatalog();
});

/// Public leaves of the `FuelProducts` tree (mã + tên) cho chip "Loại nhiên liệu" động.
/// Keep cache giữa các lần mở bottom sheet (không autoDispose).
final fuelProductLeavesProvider = FutureProvider<List<FuelProductLeaf>>((ref) async {
  final api = ref.watch(stationsApiProvider);
  return api.getFuelProductLeaves();
});

/// Chỉ các trường kích hoạt tải lại từ API (`GET /api/stations/map/v2` + ∩ danh sách từ khóa).
@immutable
class MapApiFilterKey {
  const MapApiFilterKey({
    required this.provinceCode,
    required this.districtCode,
    required this.keyword,
    required this.status,
    required this.fuelCode,
  });

  final String? provinceCode;
  final String? districtCode;
  final String? keyword;
  final String? status;
  final String? fuelCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapApiFilterKey &&
          runtimeType == other.runtimeType &&
          provinceCode == other.provinceCode &&
          districtCode == other.districtCode &&
          keyword == other.keyword &&
          status == other.status &&
          fuelCode == other.fuelCode;

  @override
  int get hashCode => Object.hash(provinceCode, districtCode, keyword, status, fuelCode);
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
    fuelCode: norm(f.fuelCode),
  );
});

/// Giá hiển thị trên marker (khi có hồ sơ phương tiện sẽ đồng bộ từ đó — TODO).
enum MapMarkerFuelPriceMode { ron95, diesel }

final mapMarkerFuelPriceModeProvider = StateProvider<MapMarkerFuelPriceMode>(
  (ref) => MapMarkerFuelPriceMode.ron95,
);

/// Map controller (provider-agnostic) từ [MapStationMapBody] — dùng nút zoom / vị trí.
final mapAppMapControllerProvider = StateProvider<AppMapController?>((ref) => null);

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
/// [FutureProvider] (không autoDispose): cache giữa lần [ref.invalidate] — gọi lại GPS khi
/// kéo sheet "Cửa hàng gần bạn" lên, chọn sắp xếp theo khoảng cách, hoặc nút vị trí trên bản đồ.
final mapSheetUserOriginProvider = FutureProvider<AppLatLng?>((ref) async {
  final r = await requestMapUserLocation();
  return switch (r) {
    MapUserLocationOk(:final position) =>
      StationMapItem.isValidCoord(position.latitude, position.longitude) ? position : null,
    _ => null,
  };
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

/// Tải trạm từ máy chủ — KHÔNG watch viewport để tránh re-run khi camera idle
/// (AsyncValueBody flip qua loading → unmount MapStationMapBody → MapLibre tear down
/// → STYLE_NOT_READY race → blinking loop).
///
/// Phase 2.B-viewport: chỉ áp dụng cho clusters (provider khác) + banner UI.
/// True viewport-aware fetch (giảm initial 12k load) cần redesign khác: preserve
/// dataBuilder qua refresh (AsyncValue.unwrapPrevious) hoặc tách map khỏi
/// AsyncValueBody — defer cho phase tiếp.
///
/// [FutureProvider] (không autoDispose): giữ kết quả khi rời tab Bản đồ — tránh tải lại toàn bộ marker
/// mỗi lần quay lại (IndexedStack vẫn giữ widget nhưng autoDispose có thể hủy cache khi không còn listener).
final stationMapMarkersFetchProvider = FutureProvider<StationMapMarkersLoadResult>((ref) async {
  final key = ref.watch(mapApiFilterKeyProvider);
  final api = ref.watch(stationsApiProvider);

  final kw = (key.keyword == null || key.keyword!.isEmpty) ? null : key.keyword;
  final mapResult = await api.loadMapMarkersPagedV2(
    provinceCode: key.provinceCode,
    districtCode: key.districtCode,
    status: key.status,
    keyword: kw,
    fuelCode: key.fuelCode,
  );
  return StationMapMarkersLoadResult(
    items: mapResult.items,
    mapTotalCount: mapResult.mapTotalCount,
    truncated: mapResult.truncated,
    keywordApplied: kw != null,
  );
});

/// Boolean cờ "đang ở zoom thấp" — derive từ viewport. Tách provider riêng để
/// [stationMapProvinceClustersProvider] chỉ re-fetch khi zoom CROSS threshold,
/// không phải mỗi camera idle.
final mapIsLowZoomProvider = Provider<bool>((ref) {
  final v = ref.watch(mapViewportProvider);
  return v != null && v.zoom < kMapClusterZoomThreshold;
});

/// Province-level clusters cho zoom thấp. Trả rỗng khi zoom ≥ threshold.
/// Optional theo keyword (count chỉ trạm match).
final stationMapProvinceClustersProvider =
    FutureProvider<List<StationMapProvinceCluster>>((ref) async {
  final isLowZoom = ref.watch(mapIsLowZoomProvider);
  if (!isLowZoom) return const [];
  final key = ref.watch(mapApiFilterKeyProvider);
  final api = ref.watch(stationsApiProvider);
  final kw = (key.keyword == null || key.keyword!.isEmpty) ? null : key.keyword;
  return api.getMapProvinceClusters(status: key.status, keyword: kw);
});

bool _stationPassesClientFilters(StationMapItem m, MapFilters f) {
  switch (f.unitType) {
    case MapUnitTypeFilter.all:
    case MapUnitTypeFilter.retail:
      break;
    case MapUnitTypeFilter.wholesale:
      return false;
  }

  // Fuel filter đã làm server-side tại `/api/stations/map/v2?fuelCode=...`
  // (xem `stationMapMarkersFetchProvider`); không lọc lại client-side.

  if (f.hasPriceFilter) {
    final lo = f.priceMinDong.toDouble();
    final hi = f.priceMaxDong.toDouble();
    final prices = <double>[
      // Khi user chọn fuelCode cụ thể → check đúng giá fuel đó (V2 đính kèm).
      if (f.fuelCode != null && m.priceForSelectedFuel != null) m.priceForSelectedFuel!,
      if (f.fuelCode == null && m.priceRon95 != null) m.priceRon95!,
      if (f.fuelCode == null && m.priceDiesel != null) m.priceDiesel!,
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

  if (f.distributorId != null) {
    if (m.parentDonViId != f.distributorId) return false;
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
final mapCameraTargetProvider = StateProvider<AppLatLng?>((ref) => null);

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
