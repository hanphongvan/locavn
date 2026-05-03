import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/network/json_utils.dart';
import '../../stations/data/models/paged_stations_response.dart';
import '../../stations/data/models/station_map_item.dart';
import 'leader_map_models.dart';

final leaderMapApiProvider = Provider<LeaderMapApi>((ref) => LeaderMapApi(ref.watch(dioProvider)));

class LeaderMapApi {
  LeaderMapApi(this._dio);

  final Dio _dio;

  Future<LeaderMapDistributorsResponse> getDistributors() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.leaderMapDistributors);
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) throw const FormatException('leader map distributors');
        return LeaderMapDistributorsResponse.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<LeaderMapDistributorInventoryDto> getDistributorInventory(int id) async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.leaderMapDistributorInventory(id));
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) throw const FormatException('leader map distributor inventory');
        return LeaderMapDistributorInventoryDto.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<PagedStationsResponse<StationMapItem>> getStationsInViewport({
    required double north,
    required double south,
    required double east,
    required double west,
    int skip = 0,
    int take = 80,
    String? status,
  }) async {
    try {
      final qp = <String, dynamic>{
        'north': north,
        'south': south,
        'east': east,
        'west': west,
        'skip': skip,
        'take': take,
      };
      if (status != null && status.isNotEmpty) {
        qp['status'] = status;
      }
      final response = await _dio.get<dynamic>(ApiEndpoints.leaderMapStations, queryParameters: qp);
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) throw const FormatException('leader map stations');
        return PagedStationsResponse.fromJson(m, StationMapItem.fromJson);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<LeaderMapViolationsResponse> getViolations(int stationId) async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.leaderMapViolations(stationId));
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) throw const FormatException('leader map violations');
        return LeaderMapViolationsResponse.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
