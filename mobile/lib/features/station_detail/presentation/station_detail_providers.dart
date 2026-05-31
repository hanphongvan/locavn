import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../stations/data/models/station_detail_dto.dart';
import '../../stations/data/models/station_rating_summary_dto.dart';
import '../../stations/data/stations_api.dart';

/// V2 — gọi `GET /api/stations/{id}/v2`. Trả `prices` list từ `StationStoreServices`
/// thay cho `latestReportingPrices` (QT_TK_ThongKe). Mobile UI ưu tiên `prices` khi
/// non-null, fallback `latestReportingPrices` (cho compatibility nếu server rollback).
final stationDetailProvider = FutureProvider.autoDispose.family<StationDetailDto, int>(
  (ref, stationId) async {
    final api = ref.watch(stationsApiProvider);
    return api.getStationDetailV2(stationId);
  },
);

/// `GET /api/stations/{id}/rating-summary` — loads in parallel with detail.
final stationRatingSummaryProvider =
    FutureProvider.autoDispose.family<StationRatingSummaryDto, int>(
  (ref, stationId) async {
    final api = ref.watch(stationsApiProvider);
    return api.getStationRatingSummary(stationId);
  },
);

/// Bumped after a successful public review submit so [StationReviewsSection] reloads from `GET …/reviews`.
final stationReviewListBumpProvider =
    StateProvider.autoDispose.family<int, int>((ref, stationId) => 0);
