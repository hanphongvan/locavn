import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/network/json_utils.dart';
import 'stabilization_fund_models.dart';

final stabilizationFundServiceProvider = Provider<StabilizationFundService>((ref) {
  return StabilizationFundService(ref.watch(dioProvider));
});

class StabilizationFundService {
  StabilizationFundService(this._dio);

  final Dio _dio;

  Future<StabilizationFundSummaryDto> getSummary({int? month, int? year}) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.leaderStabilizationFundSummary(month: month, year: year),
      );
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) throw const FormatException('stabilization-fund-summary');
        return StabilizationFundSummaryDto.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<StabilizationFundDistributorsDto> getDistributors({int? month, int? year}) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.leaderStabilizationFundDistributors(month: month, year: year),
      );
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) throw const FormatException('stabilization-fund-distributors');
        return StabilizationFundDistributorsDto.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<StabilizationFundHistoryDto> getDistributorHistory(
    int distributorId, {
    int? month,
    int? year,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.leaderStabilizationFundDistributorHistory(distributorId, month: month, year: year),
      );
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) throw const FormatException('stabilization-fund-history');
        return StabilizationFundHistoryDto.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
