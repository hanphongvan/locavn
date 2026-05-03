import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/spotlight_user_messages.dart';
import '../../stations/data/models/station_map_item.dart';
import '../../stations/data/stations_api.dart';
import 'map_discovery_navigation.dart';
import 'map_discovery_results_sheet.dart';
import 'map_providers.dart';
import 'map_spotlight_station.dart';

/// Loads top-rated spotlight from API; 404 → clear message, no fabricated list.
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
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            userMessageForSpotlightNotFound(
              e,
              whenGenericTitle: 'Chưa có đánh giá công khai trên máy chủ để xếp hạng cây xăng.',
            ),
          ),
        ),
      );
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
