import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/network/json_utils.dart';
import '../../store_sale_prices/data/models/store_admin_fuel_product_list_item.dart';
import 'models/my_vehicles_list_response.dart';
import 'models/vehicle_dto.dart';

final myVehiclesApiProvider = Provider<MyVehiclesApi>((ref) {
  return MyVehiclesApi(ref.watch(dioProvider));
});

/// Portal JWT — `GET/POST/PUT/DELETE /api/my-vehicles`.
class MyVehiclesApi {
  MyVehiclesApi(this._dio);

  final Dio _dio;

  /// `GET /api/my-vehicles/fuel-product-options` — cùng JWT với danh sách xe.
  Future<List<StoreAdminFuelProductListItem>> listFuelProductOptions({int take = 500}) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.myVehiclesFuelProductOptions,
        queryParameters: <String, dynamic>{'take': take},
      );
      return ApiResponseHandler.decode(response, (data) {
        final list = JsonUtils.readList(data);
        if (list == null) {
          throw const FormatException('Expected array for fuel product options');
        }
        return list
            .map((e) => StoreAdminFuelProductListItem.fromJson(JsonUtils.readMap(e) ?? {}))
            .toList();
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<MyVehiclesListResponse> getMyVehicles({
    String? licensePlate,
    String? fuelType,
    int page = 1,
    int pageSize = 0,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.myVehicles,
        queryParameters: <String, dynamic>{
          if (licensePlate != null && licensePlate.trim().isNotEmpty) 'licensePlate': licensePlate.trim(),
          if (fuelType != null && fuelType.trim().isNotEmpty) 'fuelType': fuelType.trim(),
          'page': page,
          'pageSize': pageSize,
        },
      );
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          throw const FormatException('Expected map for my-vehicles list');
        }
        return MyVehiclesListResponse.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<VehicleDto> getVehicleById(int id) async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.myVehicleById(id));
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          throw const FormatException('Expected map for vehicle');
        }
        return VehicleDto.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<VehicleDto> createVehicle(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<dynamic>(ApiEndpoints.myVehicles, data: body);
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          throw const FormatException('Expected map for created vehicle');
        }
        return VehicleDto.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<VehicleDto> updateVehicle(int id, Map<String, dynamic> body) async {
    try {
      final response = await _dio.put<dynamic>(ApiEndpoints.myVehicleById(id), data: body);
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          throw const FormatException('Expected map for updated vehicle');
        }
        return VehicleDto.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteVehicle(int id) async {
    try {
      final response = await _dio.delete<dynamic>(ApiEndpoints.myVehicleById(id));
      ApiResponseHandler.decodeAllowNull(response, (_) => null);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<VehicleDto> setDefaultVehicle(int id) async {
    try {
      final response = await _dio.post<dynamic>(ApiEndpoints.myVehicleSetDefault(id));
      return ApiResponseHandler.decode(response, (data) {
        final m = JsonUtils.readMap(data);
        if (m == null) {
          throw const FormatException('Expected map for vehicle after set-default');
        }
        return VehicleDto.fromJson(m);
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
