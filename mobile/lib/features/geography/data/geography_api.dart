import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/network/json_utils.dart';
import 'models/district_response.dart';
import 'models/province_response.dart';
import 'models/ward_response.dart';

final geographyApiProvider = Provider<GeographyApi>((ref) {
  return GeographyApi(ref.watch(dioProvider));
});

/// Backend: `/api/geography`
class GeographyApi {
  GeographyApi(this._dio);

  final Dio _dio;

  Future<List<ProvinceResponse>> getProvinces() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.geographyProvinces);
      return ApiResponseHandler.decode(response, (data) {
        final raw = JsonUtils.readList(data);
        if (raw == null) {
          throw const FormatException('Expected list for provinces');
        }
        final out = <ProvinceResponse>[];
        for (final e in raw) {
          final m = JsonUtils.readMap(e);
          if (m != null) {
            out.add(ProvinceResponse.fromJson(m));
          }
        }
        return out;
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<DistrictResponse>> getDistricts(String provinceCode) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.geographyDistricts,
        queryParameters: <String, dynamic>{'provinceCode': provinceCode},
      );
      return ApiResponseHandler.decode(response, (data) {
        final raw = JsonUtils.readList(data);
        if (raw == null) {
          throw const FormatException('Expected list for districts');
        }
        final out = <DistrictResponse>[];
        for (final e in raw) {
          final m = JsonUtils.readMap(e);
          if (m != null) {
            out.add(DistrictResponse.fromJson(m));
          }
        }
        return out;
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<WardResponse>> getWards(String districtCode) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.geographyWards,
        queryParameters: <String, dynamic>{'districtCode': districtCode},
      );
      return ApiResponseHandler.decode(response, (data) {
        final raw = JsonUtils.readList(data);
        if (raw == null) {
          throw const FormatException('Expected list for wards');
        }
        final out = <WardResponse>[];
        for (final e in raw) {
          final m = JsonUtils.readMap(e);
          if (m != null) {
            out.add(WardResponse.fromJson(m));
          }
        }
        return out;
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
