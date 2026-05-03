import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../../core/network/dio_provider.dart';

final requestDeleteDataApiProvider = Provider<RequestDeleteDataApi>((ref) {
  return RequestDeleteDataApi(ref.watch(dioProvider));
});

class RequestDeleteDataApi {
  RequestDeleteDataApi(this._dio);

  final Dio _dio;

  Future<RequestDeleteDataResultDto> submit({
    String requestType = 'DELETE_PERSONAL_DATA',
    String scope = 'ALL',
    String note = 'User requested personal data deletion from mobile app',
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.userRequestDeleteData,
        data: <String, dynamic>{
          'requestType': requestType,
          'scope': scope,
          'note': note,
        },
      );
      final map = res.data;
      if (map == null) {
        throw ApiException('Phản hồi không hợp lệ');
      }
      return RequestDeleteDataResultDto.fromJson(map);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

class RequestDeleteDataResultDto {
  const RequestDeleteDataResultDto({required this.success, required this.message});

  final bool success;
  final String message;

  factory RequestDeleteDataResultDto.fromJson(Map<String, dynamic> json) {
    return RequestDeleteDataResultDto(
      success: json['success'] == true,
      message: (json['message'] as String?)?.trim() ?? '',
    );
  }
}
