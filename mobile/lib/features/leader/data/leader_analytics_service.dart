import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/network/json_utils.dart';
import 'leader_analytics_dtos.dart';

final leaderAnalyticsServiceProvider = Provider<LeaderAnalyticsService>((ref) {
  return LeaderAnalyticsService(ref.watch(dioProvider));
});

/// Gọi GET `/api/leader/analytics/*` — dữ liệu cùng nguồn SP với DMPPortal home dashboard.
class LeaderAnalyticsService {
  LeaderAnalyticsService(this._dio);

  final Dio _dio;

  Future<LeaderAnalyticsInventoryTrendDto> getInventoryTrend({required String window}) async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.leaderAnalyticsInventoryTrend(window));
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) throw const FormatException('inventory-trend');
        return LeaderAnalyticsInventoryTrendDto.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<LeaderAnalyticsImportExportTrendDto> getImportExportTrend({
    required String window,
    required String fuel,
  }) async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.leaderAnalyticsImportExportTrend(window, fuel));
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) throw const FormatException('import-export-trend');
        return LeaderAnalyticsImportExportTrendDto.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<LeaderAnalyticsPriceTrendDto> getPriceTrend({required String window}) async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.leaderAnalyticsPriceTrend(window));
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) throw const FormatException('price-trend');
        return LeaderAnalyticsPriceTrendDto.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<LeaderAnalyticsPeriodComparisonDto> getPeriodComparison({required String window}) async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.leaderAnalyticsPeriodComparison(window));
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) throw const FormatException('period-comparison');
        return LeaderAnalyticsPeriodComparisonDto.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<LeaderAnalyticsMarketInsightDto> getMarketInsight({
    required String window,
    required String fuel,
  }) async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.leaderAnalyticsMarketInsight(window, fuel));
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) throw const FormatException('market-insight');
        return LeaderAnalyticsMarketInsightDto.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
