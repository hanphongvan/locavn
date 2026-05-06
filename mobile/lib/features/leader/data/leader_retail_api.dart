import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/network/json_utils.dart';
import 'leader_retail_models.dart';

/// HTTP client cho Leader Retail (`/api/leader/retail/*`) — Bearer JWT qua `dioProvider`.
class LeaderRetailApi {
  LeaderRetailApi(this._dio);

  final Dio _dio;

  Future<RetailDashboardData> getDashboard(RetailFilter filter) async {
    final url = ApiEndpoints.leaderRetailDashboard(
      provinceId: filter.provinceId,
      status: filter.status?.bitValue,
      managingUnitId: filter.managingUnitId,
    );
    debugPrint('[leader-retail] api.getDashboard → GET $url');
    try {
      final response = await _dio.get<dynamic>(url);
      debugPrint(
        '[leader-retail] api.getDashboard ← status=${response.statusCode} '
        'data.runtimeType=${response.data.runtimeType}',
      );
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          debugPrint('[leader-retail] api.getDashboard parse FAIL: data not a map');
          throw const FormatException('retail-dashboard');
        }
        debugPrint(
          '[leader-retail] api.getDashboard parsed keys=${m.keys.toList()}',
        );
        return RetailDashboardData.fromJson(m);
      });
    } on DioException catch (e) {
      debugPrint(
        '[leader-retail] api.getDashboard DioException type=${e.type} '
        'status=${e.response?.statusCode} message=${e.message}',
      );
      throw ApiException.fromDio(e);
    } catch (e, st) {
      debugPrint('[leader-retail] api.getDashboard UNEXPECTED: $e');
      debugPrintStack(stackTrace: st, label: '[leader-retail] api stack');
      rethrow;
    }
  }

  Future<List<RetailManagingUnit>> getManagingUnits() async {
    debugPrint('[leader-retail] api.getManagingUnits → GET ${ApiEndpoints.leaderRetailManagingUnits}');
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.leaderRetailManagingUnits);
      debugPrint('[leader-retail] api.getManagingUnits ← status=${response.statusCode}');
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) return const <RetailManagingUnit>[];
        final items = (m['items'] as List?) ?? const [];
        return items
            .whereType<Map<String, dynamic>>()
            .map(RetailManagingUnit.fromJson)
            .toList();
      });
    } on DioException catch (e) {
      debugPrint(
        '[leader-retail] api.getManagingUnits DioException type=${e.type} '
        'status=${e.response?.statusCode} message=${e.message}',
      );
      throw ApiException.fromDio(e);
    } catch (e, st) {
      debugPrint('[leader-retail] api.getManagingUnits UNEXPECTED: $e');
      debugPrintStack(stackTrace: st, label: '[leader-retail] api stack');
      rethrow;
    }
  }

  Future<List<RetailProvinceFilterOption>> getProvinces() async {
    debugPrint('[leader-retail] api.getProvinces → GET ${ApiEndpoints.leaderRetailProvinces}');
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.leaderRetailProvinces);
      debugPrint('[leader-retail] api.getProvinces ← status=${response.statusCode}');
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) return const <RetailProvinceFilterOption>[];
        final items = (m['items'] as List?) ?? const [];
        return items
            .whereType<Map<String, dynamic>>()
            .map(RetailProvinceFilterOption.fromJson)
            .toList();
      });
    } on DioException catch (e) {
      debugPrint(
        '[leader-retail] api.getProvinces DioException type=${e.type} '
        'status=${e.response?.statusCode} message=${e.message}',
      );
      throw ApiException.fromDio(e);
    } catch (e, st) {
      debugPrint('[leader-retail] api.getProvinces UNEXPECTED: $e');
      debugPrintStack(stackTrace: st, label: '[leader-retail] api stack');
      rethrow;
    }
  }
}

final leaderRetailApiProvider = Provider<LeaderRetailApi>((ref) {
  return LeaderRetailApi(ref.watch(dioProvider));
});
