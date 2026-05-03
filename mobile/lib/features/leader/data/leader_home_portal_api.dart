import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/network/json_utils.dart';
import 'leader_home_portal_models.dart';

final leaderHomePortalApiProvider = Provider<LeaderHomePortalApi>((ref) {
  return LeaderHomePortalApi(ref.watch(dioProvider));
});

/// Gọi API lãnh đạo (Bearer qua [dioProvider]).
class LeaderHomePortalApi {
  LeaderHomePortalApi(this._dio);

  final Dio _dio;

  Future<LeaderHomeInventorySummaryResponse> postInventorySummary(LeaderHomeDashboardRequest body) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.leaderHomeInventorySummary,
        data: body.toJson(),
      );
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) throw const FormatException('inventory-summary');
        return LeaderHomeInventorySummaryResponse.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<LeaderHomeNationalStockMovementResponse> postNationalStockMovement(LeaderHomeDashboardRequest body) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.leaderHomeNationalStockMovement,
        data: body.toJson(),
      );
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) throw const FormatException('national-stock-movement');
        return LeaderHomeNationalStockMovementResponse.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<LeaderHomePriceSummaryResponse> postPriceSummary(LeaderHomeDashboardRequest body) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.leaderHomePriceSummary,
        data: body.toJson(),
      );
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) throw const FormatException('price-summary');
        return LeaderHomePriceSummaryResponse.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<LeaderHomeDistributorMapResponse> postDistributorMap(LeaderHomeDistributorMapRequest body) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.leaderHomeDistributorMap,
        data: body.toJson(),
      );
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) throw const FormatException('distributor-map');
        return LeaderHomeDistributorMapResponse.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
