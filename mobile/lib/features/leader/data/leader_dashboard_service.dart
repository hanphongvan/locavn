import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/network/json_utils.dart';
import 'leader_inventory_detail_models.dart';

final leaderDashboardServiceProvider = Provider<LeaderDashboardService>((ref) {
  return LeaderDashboardService(ref.watch(dioProvider));
});

/// Gói `/api/leader/dashboard/*` (GET) — Lãnh đạo.
class LeaderDashboardService {
  LeaderDashboardService(this._dio);

  final Dio _dio;

  Future<LeaderInventoryDetailResponse> getInventoryDetail(
    String fuelType, {
    int? month,
    int? year,
    String? statusGroup,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.leaderDashboardInventoryDetail(
          fuelType,
          month: month,
          year: year,
          statusGroup: statusGroup,
        ),
      );
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) throw const FormatException('inventory-detail');
        return LeaderInventoryDetailResponse.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
