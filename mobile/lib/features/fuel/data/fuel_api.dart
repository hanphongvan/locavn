import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/network/json_utils.dart';
import 'models/fuel_api_dtos.dart';

final fuelApiProvider = Provider<FuelApi>((ref) {
  return FuelApi(ref.watch(dioProvider));
});

/// Portal JWT — `/api/fuel/*`.
class FuelApi {
  FuelApi(this._dio);

  final Dio _dio;

  Future<CurrentVehicleApiDto> getCurrentVehicle() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.fuelCurrentVehicle);
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          throw const FormatException('Expected map for current vehicle');
        }
        return CurrentVehicleApiDto.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<FuelSummaryApiDto> getFuelMonthlySummary(int vehicleId, int month, int year) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.fuelSummary,
        queryParameters: <String, dynamic>{
          'vehicleId': vehicleId,
          'month': month,
          'year': year,
        },
      );
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          throw const FormatException('Expected map for fuel summary');
        }
        return FuelSummaryApiDto.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<FuelInsightApiDto> getFuelInsights(int vehicleId, int month, int year) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.fuelInsights,
        queryParameters: <String, dynamic>{
          'vehicleId': vehicleId,
          'month': month,
          'year': year,
        },
      );
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          throw const FormatException('Expected map for fuel insights');
        }
        return FuelInsightApiDto.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<FuelTransactionsPageApiDto> getFuelTransactions(int vehicleId, {int pageIndex = 1, int pageSize = 20}) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.fuelTransactions,
        queryParameters: <String, dynamic>{
          'vehicleId': vehicleId,
          'pageIndex': pageIndex,
          'pageSize': pageSize,
        },
      );
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          throw const FormatException('Expected map for fuel transactions');
        }
        return FuelTransactionsPageApiDto.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<CreateFuelTransactionResultDto> createFuelTransaction(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<dynamic>(ApiEndpoints.fuelTransactions, data: body);
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          throw const FormatException('Expected map for create fuel transaction');
        }
        return CreateFuelTransactionResultDto.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<CreateFuelTransactionResultDto> updateFuelTransaction(int transactionId, Map<String, dynamic> body) async {
    try {
      final response = await _dio.put<dynamic>(ApiEndpoints.fuelTransactionById(transactionId), data: body);
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          throw const FormatException('Expected map for update fuel transaction');
        }
        return CreateFuelTransactionResultDto.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<CreateFuelTransactionResultDto> deleteFuelTransaction(int transactionId, {required int vehicleId}) async {
    try {
      final response = await _dio.delete<dynamic>(
        ApiEndpoints.fuelTransactionById(transactionId),
        queryParameters: <String, dynamic>{'vehicleId': vehicleId},
      );
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          throw const FormatException('Expected map for delete fuel transaction');
        }
        return CreateFuelTransactionResultDto.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
