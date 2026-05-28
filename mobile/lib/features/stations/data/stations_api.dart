import 'dart:io' show HttpException;
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_console_log.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/network/json_utils.dart';
import 'models/paged_stations_response.dart';
import 'models/station_detail_dto.dart';
import 'models/station_list_item.dart';
import 'models/station_map_item.dart';
import 'models/station_map_markers_load_result.dart';
import 'models/station_map_province_cluster.dart';
import '../../store_services/data/models/store_service_catalog_item.dart';
import 'models/station_rating_summary_dto.dart';
import 'models/station_review_dto.dart';
import 'models/station_spotlight_dto.dart';

final stationsApiProvider = Provider<StationsApi>((ref) {
  return StationsApi(ref.watch(dioProvider));
});

/// True when the socket closed while the client was still reading the body (large JSON,
/// flaky LAN, or server-side limits). Safe to repeat the same request.
bool _isConnectionClosedWhileReceiving(DioException e) {
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout) {
    return true;
  }
  final err = e.error;
  if (err is HttpException) {
    if (err.message.toLowerCase().contains('connection closed')) {
      return true;
    }
  }
  final msg = '${e.message} $err'.toLowerCase();
  if (msg.contains('connection closed') || msg.contains('connection reset')) {
    return true;
  }
  return false;
}

/// Phase-1 station read API (`/api/stations`, `/api/stations/map`, detail).
///
/// Spotlight and review endpoints will extend this class (same provider); see
/// `mobile/docs/flutter-map-upgrade-phases.md`.
class StationsApi {
  StationsApi(this._dio);

  final Dio _dio;

  /// One GET with a single retry on transient socket close (LAN / large bodies).
  Future<Response<dynamic>> _getWithConnectionRetry(
    String path, {
    Map<String, dynamic>? queryParameters,
    String? debugLabel,
  }) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        return await _dio.get<dynamic>(path, queryParameters: queryParameters);
      } on DioException catch (e) {
        if (attempt == 0 && _isConnectionClosedWhileReceiving(e)) {
          if (kDebugMode) {
            debugPrint(
              '[httm_xangdau] ${debugLabel ?? path} GET retry after transient close',
            );
          }
          await Future<void>.delayed(const Duration(milliseconds: 400));
          continue;
        }
        throw ApiException.fromDio(e);
      }
    }
    throw StateError('_getWithConnectionRetry: expected response');
  }

  Future<PagedStationsResponse<StationMapItem>> getMapSummary({
    int skip = 0,
    int take = 0,
    String? provinceCode,
    String? districtCode,
    String? status,
    String? keyword,
  }) async {
    final t = (take <= 0 ? 50 : take).clamp(1, 100);
    final response = await _getWithConnectionRetry(
      ApiEndpoints.stationsMap,
      queryParameters: <String, dynamic>{
        'skip': skip,
        'take': t,
        if (provinceCode != null && provinceCode.isNotEmpty) 'provinceCode': provinceCode,
        if (districtCode != null && districtCode.isNotEmpty) 'districtCode': districtCode,
        if (status != null && status.isNotEmpty) 'status': status,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      },
      debugLabel: 'getMapSummary',
    );
    return ApiResponseHandler.decode(response, (data) {
      final m = JsonUtils.readMap(data);
      if (m == null) {
        throw const FormatException('Expected map for PagedStationsResponse');
      }
      return PagedStationsResponse.fromJson(m, StationMapItem.fromJson);
    });
  }

  /// `GET /api/stations/map/bounds` (Phase 2.G) — markers trong bounding box
  /// + optional [keyword]. Dùng cho zoom-aware viewport loading (zoom ≥ 11).
  /// Cap server: take mặc định 500, max 1000.
  Future<PagedStationsResponse<StationMapItem>> getMapByBounds({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    int skip = 0,
    int take = 500,
    String? status,
    String? keyword,
  }) async {
    final response = await _getWithConnectionRetry(
      ApiEndpoints.stationsMapBounds,
      queryParameters: <String, dynamic>{
        'minLat': minLat,
        'maxLat': maxLat,
        'minLng': minLng,
        'maxLng': maxLng,
        'skip': skip,
        'take': take,
        if (status != null && status.isNotEmpty) 'status': status,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      },
      debugLabel: 'getMapByBounds',
    );
    return ApiResponseHandler.decode(response, (data) {
      final m = JsonUtils.readMap(data);
      if (m == null) {
        throw const FormatException('Expected map for PagedStationsResponse');
      }
      return PagedStationsResponse.fromJson(m, StationMapItem.fromJson);
    });
  }

  /// `GET /api/stations/map/clusters` (Phase 2.G) — count + centroid theo tỉnh
  /// cho low zoom (< 11). Optional [keyword] để cluster theo kết quả search.
  Future<List<StationMapProvinceCluster>> getMapProvinceClusters({
    String? status,
    String? keyword,
  }) async {
    final response = await _getWithConnectionRetry(
      ApiEndpoints.stationsMapClusters,
      queryParameters: <String, dynamic>{
        if (status != null && status.isNotEmpty) 'status': status,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      },
      debugLabel: 'getMapProvinceClusters',
    );
    return ApiResponseHandler.decode(response, (data) {
      final list = JsonUtils.readList(data);
      if (list == null) {
        throw const FormatException('Expected list for ProvinceClusters');
      }
      return list
          .map((e) => JsonUtils.readMap(e))
          .where((m) => m != null)
          .map((m) => StationMapProvinceCluster.fromJson(m!))
          .toList();
    });
  }

  /// Loads map markers in pages of [pageSize] (max 100 per backend) until the
  /// server returns a short page, counts are satisfied, or [maxPages] is hit.
  ///
  /// Fetches page 0 first (for [totalCount]), then remaining pages in small
  /// parallel batches. If a batch fails (timeouts / server load), falls back to
  /// sequential requests for that batch.
  ///
  /// **Important:** `all.length >= totalCount` is only valid when `totalCount > 0`.
  /// If `totalCount` is missing (0) but the first page is full, we keep paging
  /// sequentially (otherwise we would stop after one page).
  Future<StationMapMarkersLoadResult> loadMapMarkersPaged({
    String? provinceCode,
    String? districtCode,
    String? status,
    String? keyword,
    int pageSize = 50,
    int maxPages = 15,
  }) async {
    final take = pageSize.clamp(1, 100);
    final first = await getMapSummary(
      skip: 0,
      take: take,
      provinceCode: provinceCode,
      districtCode: districtCode,
      status: status,
      keyword: keyword,
    );
    final totalCount = first.totalCount;
    final all = List<StationMapItem>.from(first.items);

    if (first.items.isEmpty) {
      return StationMapMarkersLoadResult(
        items: all,
        mapTotalCount: totalCount,
        truncated: false,
      );
    }

    if (first.items.length < take) {
      final resolvedTotal = totalCount > 0 ? totalCount : all.length;
      return StationMapMarkersLoadResult(
        items: all,
        mapTotalCount: resolvedTotal,
        truncated: false,
      );
    }

    if (totalCount > 0 && all.length >= totalCount) {
      return StationMapMarkersLoadResult(
        items: all,
        mapTotalCount: totalCount,
        truncated: false,
      );
    }

    if (totalCount <= 0) {
      return _loadMapMarkersSequentialAfterFirst(
        all: all,
        take: take,
        maxPages: maxPages,
        provinceCode: provinceCode,
        districtCode: districtCode,
        status: status,
        keyword: keyword,
      );
    }

    final totalPages = ((totalCount + take - 1) ~/ take).clamp(1, 1 << 20);
    final maxExtra = math.max(0, maxPages - 1);
    final extraPages = math.min(maxExtra, totalPages - 1);
    if (extraPages <= 0) {
      return StationMapMarkersLoadResult(
        items: all,
        mapTotalCount: totalCount,
        truncated: all.length < totalCount,
      );
    }

    await _appendMapPagesBatched(
      all: all,
      take: take,
      firstPageIndex: 1,
      lastPageIndex: extraPages,
      provinceCode: provinceCode,
      districtCode: districtCode,
      status: status,
      keyword: keyword,
    );

    final truncated = all.length < totalCount;
    return StationMapMarkersLoadResult(
      items: all,
      mapTotalCount: totalCount,
      truncated: truncated,
    );
  }

  /// When [totalCount] is unknown but the first page was full — page until short read.
  Future<StationMapMarkersLoadResult> _loadMapMarkersSequentialAfterFirst({
    required List<StationMapItem> all,
    required int take,
    required int maxPages,
    String? provinceCode,
    String? districtCode,
    String? status,
    String? keyword,
  }) async {
    var skip = take;
    for (var i = 1; i < maxPages; i++) {
      final page = await getMapSummary(
        skip: skip,
        take: take,
        provinceCode: provinceCode,
        districtCode: districtCode,
        status: status,
        keyword: keyword,
      );
      all.addAll(page.items);
      if (page.items.isEmpty || page.items.length < take) {
        return StationMapMarkersLoadResult(
          items: all,
          mapTotalCount: all.length,
          truncated: false,
        );
      }
      skip += take;
    }
    return StationMapMarkersLoadResult(
      items: all,
      mapTotalCount: all.length,
      truncated: true,
    );
  }

  static const int _mapPageConcurrency = 4;

  Future<void> _appendMapPagesBatched({
    required List<StationMapItem> all,
    required int take,
    required int firstPageIndex,
    required int lastPageIndex,
    String? provinceCode,
    String? districtCode,
    String? status,
    String? keyword,
  }) async {
    var start = firstPageIndex;
    while (start <= lastPageIndex) {
      final end = math.min(start + _mapPageConcurrency - 1, lastPageIndex);
      final batch = <Future<PagedStationsResponse<StationMapItem>>>[];
      for (var p = start; p <= end; p++) {
        batch.add(
          getMapSummary(
            skip: p * take,
            take: take,
            provinceCode: provinceCode,
            districtCode: districtCode,
            status: status,
            keyword: keyword,
          ),
        );
      }
      try {
        final pages = await Future.wait(batch);
        for (final page in pages) {
          all.addAll(page.items);
        }
      } catch (e, st) {
        logAppError('loadMapMarkersPaged parallel batch pages $start-$end', e, st);
        for (var p = start; p <= end; p++) {
          final page = await getMapSummary(
            skip: p * take,
            take: take,
            provinceCode: provinceCode,
            districtCode: districtCode,
            status: status,
            keyword: keyword,
          );
          all.addAll(page.items);
        }
      }
      start = end + 1;
    }
  }

  /// Pages `GET /api/stations` with [keyword] until a short page, total reached, or [maxPages].
  /// Returns station IDs for intersection with map markers.
  Future<({Set<int> ids, bool listTruncated, int listTotalCount})> collectStationIdsForKeyword({
    required String keyword,
    String? provinceCode,
    String? districtCode,
    String? status,
    int maxPages = 20,
  }) async {
    final ids = <int>{};
    var skip = 0;
    var listTotalCount = 0;
    for (var i = 0; i < maxPages; i++) {
      final page = await listStations(
        keyword: keyword,
        skip: skip,
        take: 100,
        provinceCode: provinceCode,
        districtCode: districtCode,
        status: status,
      );
      listTotalCount = page.totalCount;
      for (final item in page.items) {
        ids.add(item.stationId);
      }
      if (page.items.isEmpty) {
        break;
      }
      if (page.items.length < 100 || skip + page.items.length >= page.totalCount) {
        break;
      }
      skip += 100;
    }
    final listTruncated = ids.length < listTotalCount && listTotalCount > 0;
    return (ids: ids, listTruncated: listTruncated, listTotalCount: listTotalCount);
  }

  Future<PagedStationsResponse<StationListItem>> listStations({
    int skip = 0,
    int take = 0,
    String? keyword,
    String? provinceCode,
    String? districtCode,
    String? status,
  }) async {
    final response = await _getWithConnectionRetry(
      ApiEndpoints.stations,
      queryParameters: <String, dynamic>{
        'skip': skip,
        'take': take,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        if (provinceCode != null && provinceCode.isNotEmpty) 'provinceCode': provinceCode,
        if (districtCode != null && districtCode.isNotEmpty) 'districtCode': districtCode,
        if (status != null && status.isNotEmpty) 'status': status,
      },
      debugLabel: 'listStations',
    );
    return ApiResponseHandler.decode(response, (data) {
      final m = JsonUtils.readMap(data);
      if (m == null) {
        throw const FormatException('Expected map for PagedStationsResponse');
      }
      return PagedStationsResponse.fromJson(m, StationListItem.fromJson);
    });
  }

  /// `GET /api/stations/{id}/reviews` — paged public reviews (newest first on server).
  Future<StationReviewsPageDto> listStationReviews(
    int stationId, {
    int skip = 0,
    int take = 20,
  }) async {
    final response = await _getWithConnectionRetry(
      ApiEndpoints.stationReviews(stationId),
      queryParameters: <String, dynamic>{
        'skip': skip,
        'take': take,
      },
      debugLabel: 'listStationReviews',
    );
    return ApiResponseHandler.decode(response, (data) {
      final m = JsonUtils.readMap(data);
      if (m == null) {
        throw const FormatException('Expected map for StationReviewsPageDto');
      }
      return StationReviewsPageDto.fromJson(m);
    });
  }

  /// POST `/api/stations/{id}/reviews` — [rating] 1–5; [comment] optional; [imageUrls] optional HTTPS/HTTP URLs (max 10).
  Future<({int id, DateTime createdAt})> submitStationReview({
    required int stationId,
    required int rating,
    String? comment,
    List<String>? imageUrls,
  }) async {
    if (rating < 1 || rating > 5) {
      throw const FormatException('rating must be 1–5');
    }
    try {
      final body = <String, dynamic>{
        'rating': rating,
      };
      final urls = imageUrls
              ?.map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(growable: false) ??
          const <String>[];
      if (urls.isNotEmpty) {
        body['imageUrls'] = urls;
      }
      final t = comment?.trim();
      if (t != null && t.isNotEmpty) {
        body['comment'] = t;
      }
      final response = await _dio.post<dynamic>(
        ApiEndpoints.stationReviews(stationId),
        data: body,
      );
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          throw const FormatException('Expected map for review response');
        }
        final id = JsonUtils.readInt(m['id']);
        final created = JsonUtils.readDateTime(m['createdAt']);
        if (id == null || created == null) {
          throw const FormatException('Missing id or createdAt in review response');
        }
        return (id: id, createdAt: created);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// `GET /api/stations/{id}/rating-summary` — aggregate rating (404 if station not found).
  Future<StationRatingSummaryDto> getStationRatingSummary(int stationId) async {
    final response = await _getWithConnectionRetry(
      ApiEndpoints.stationRatingSummary(stationId),
      debugLabel: 'getStationRatingSummary',
    );
    return ApiResponseHandler.decode(response, (data) {
      final m = JsonUtils.readMap(data);
      if (m == null) {
        throw const FormatException('Expected map for StationRatingSummaryDto');
      }
      return StationRatingSummaryDto.fromJson(m);
    });
  }

  /// `GET /api/stations/cheapest?fuelType=` — `ron95` | `diesel` (per server).
  Future<StationSpotlightDto> getCheapestSpotlight({required String fuelType}) async {
    final ft = fuelType.trim();
    if (ft.isEmpty) {
      throw const FormatException('fuelType is required');
    }
    final response = await _getWithConnectionRetry(
      ApiEndpoints.stationsCheapest,
      queryParameters: <String, dynamic>{'fuelType': ft},
      debugLabel: 'getCheapestSpotlight',
    );
    return ApiResponseHandler.decode(response, (data) {
      final m = JsonUtils.readMap(data);
      if (m == null) {
        throw const FormatException('Expected map for StationSpotlightDto');
      }
      return StationSpotlightDto.fromJson(m);
    });
  }

  /// `GET /api/stations/top-rated` — station with highest average review (404 if none).
  Future<StationSpotlightDto> getTopRatedSpotlight() async {
    final response = await _getWithConnectionRetry(
      ApiEndpoints.stationsTopRated,
      debugLabel: 'getTopRatedSpotlight',
    );
    return ApiResponseHandler.decode(response, (data) {
      final m = JsonUtils.readMap(data);
      if (m == null) {
        throw const FormatException('Expected map for StationSpotlightDto');
      }
      return StationSpotlightDto.fromJson(m);
    });
  }

  /// `GET /api/stations/nearest?lat=&lng=` — global nearest station with valid map coordinates.
  Future<StationSpotlightDto> getNearestSpotlight({
    required double lat,
    required double lng,
  }) async {
    final response = await _getWithConnectionRetry(
      ApiEndpoints.stationsNearest,
      queryParameters: <String, dynamic>{
        'lat': lat,
        'lng': lng,
      },
      debugLabel: 'getNearestSpotlight',
    );
    return ApiResponseHandler.decode(response, (data) {
      final m = JsonUtils.readMap(data);
      if (m == null) {
        throw const FormatException('Expected map for StationSpotlightDto');
      }
      return StationSpotlightDto.fromJson(m);
    });
  }

  /// Public catalog for map service filters (`GET /api/stations/store-services-catalog`).
  Future<List<StoreServiceCatalogItem>> getStoreServicesCatalog() async {
    final response = await _getWithConnectionRetry(
      ApiEndpoints.stationsStoreServicesCatalog,
      debugLabel: 'getStoreServicesCatalog',
    );
    return ApiResponseHandler.decode(response, (data) {
      if (data is! List<dynamic>) {
        throw const FormatException('Expected JSON array for stations store-services catalog');
      }
      return data
          .map((e) => StoreServiceCatalogItem.fromJson(JsonUtils.readMap(e)!))
          .toList(growable: false);
    });
  }

  Future<StationDetailDto> getStationDetail(int stationId) async {
    final response = await _getWithConnectionRetry(
      ApiEndpoints.stationById(stationId),
      debugLabel: 'getStationDetail',
    );
    return ApiResponseHandler.decode(response, (data) {
      final m = JsonUtils.readMap(data);
      if (m == null) {
        throw const FormatException('Expected map for StationDetailDto');
      }
      return StationDetailDto.fromJson(m);
    });
  }
}
