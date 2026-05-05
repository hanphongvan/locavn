import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/map/app_lat_lng.dart';
import '../../../core/network/api_exception.dart';
import '../../stations/data/models/station_map_item.dart';
import '../../stations/data/stations_api.dart';
import '../../stations/domain/station_availability.dart';
import '../../stations/station_open_status.dart';
import '../data/map_geo.dart';
import 'map_discovery_navigation.dart';
import 'map_discovery_results_sheet.dart';
import 'map_providers.dart';
import 'map_spotlight_station.dart';

/// Ưu tiên `GET /api/stations/top-rated`. Khi máy chủ 404 (chưa có review), xếp hạng cục bộ
/// trên các trạm đã tải: đang mở → có giấy phép hoạt động → tên A → Z (cùng chrome sheet).
List<StationMapItem> _localTrustRankedStations(List<StationMapItem> items) {
  int openRank(StationMapItem s) {
    switch (StationOpenStatus.forMapItem(s).tone) {
      case StationOpenTone.open:
        return 0;
      case StationOpenTone.unknown:
        return 1;
      case StationOpenTone.closed:
        return 2;
    }
  }

  int activeRank(StationMapItem s) {
    if (s.isActive == true) return 0;
    if (s.isActive == null) return 1;
    return 2;
  }

  final copy = List<StationMapItem>.from(items);
  copy.sort((a, b) {
    final o = openRank(a).compareTo(openRank(b));
    if (o != 0) return o;
    final ar = activeRank(a).compareTo(activeRank(b));
    if (ar != 0) return ar;
    return a.stationName.toLowerCase().compareTo(b.stationName.toLowerCase());
  });
  return copy;
}

Future<void> _presentTopRatedLocalFallback(
  BuildContext context,
  WidgetRef ref,
  List<StationMapItem> items,
) async {
  final ranked = _localTrustRankedStations(items).take(60).toList();
  if (ranked.isEmpty) return;

  final AppLatLng? origin = ref.read(mapSheetUserOriginProvider).asData?.value;
  final rows = ranked.map((e) {
    if (origin != null) {
      return MapStationListRow(
        item: e,
        distanceKm: mapHaversineKm(
          origin.latitude,
          origin.longitude,
          e.latitude,
          e.longitude,
        ),
      );
    }
    return MapStationListRow(item: e);
  }).toList();

  await showMapDiscoveryResultsSheet(
    context: context,
    rows: rows,
    title: 'Uy tín',
    subtitle:
        'Chưa có đánh giá công khai trên máy chủ. Danh sách gợi ý tạm: đang mở, có giấy phép hoạt động, tên A → Z.',
    chrome: MapDiscoverySheetChrome.topRated,
    emptySubtitle: 'Vui lòng thử thay đổi bộ lọc hoặc khu vực tìm kiếm',
    initialChildSize: ranked.length <= 4 ? 0.36 : 0.44,
    onStationChosen: (row) => focusMapStationAndOpenSummary(
          context,
          ref,
          row.item,
          distanceKm: row.distanceKm,
        ),
  );
}

/// Loads top-rated spotlight from API; 404 (chưa có review) → danh sách gợi ý cục bộ trên bản đồ đã tải.
Future<void> presentTopRatedPetrolStation(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final items = ref.read(stationMapMarkersProvider).asData?.value.items ?? const <StationMapItem>[];
  if (items.isEmpty) {
    messenger?.showSnackBar(
      const SnackBar(content: Text('Chưa có dữ liệu bản đồ — tải xong rồi thử lại.')),
    );
    return;
  }

  try {
    final spot = await ref.read(stationsApiProvider).getTopRatedSpotlight();
    if (!context.mounted) return;

    final resolved = await resolveSpotlightToMapItem(ref.read(stationsApiProvider), spot, items);
    if (!context.mounted) return;
    if (resolved == null) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Không tải được chi tiết để hiển thị trên bản đồ.')),
      );
      return;
    }
    if (resolved.$2) {
      ref.read(mapEphemeralStationProvider.notifier).state = resolved.$1;
    }

    final row = MapStationListRow(
      item: resolved.$1,
      spotlightAverageRating: spot.averageRating,
      spotlightReviewCount: spot.reviewCount,
    );

    await showMapDiscoveryResultsSheet(
      context: context,
      rows: [row],
      title: 'Uy tín',
      subtitle: 'Các cửa hàng được đánh giá cao',
      chrome: MapDiscoverySheetChrome.topRated,
      emptySubtitle: 'Vui lòng thử thay đổi bộ lọc hoặc khu vực tìm kiếm',
      initialChildSize: 0.36,
      onStationChosen: (row) async {
        final item = row.item;
        if (resolved.$2) {
          ref.read(mapEphemeralStationProvider.notifier).state = item;
        }
        await focusMapStationAndOpenSummary(context, ref, item);
      },
    );
  } on ApiException catch (e) {
    if (!context.mounted) return;
    if (e.statusCode == 404) {
      await _presentTopRatedLocalFallback(context, ref, items);
    } else {
      messenger?.showSnackBar(SnackBar(content: Text(e.message)));
    }
  } catch (e) {
    if (!context.mounted) return;
    messenger?.showSnackBar(
      SnackBar(content: Text('Không tải được trạm đánh giá cao: $e')),
    );
  }
}
