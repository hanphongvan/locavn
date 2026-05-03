import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';

class ChangePasswordApi {
  ChangePasswordApi(this._dio);

  final Dio _dio;

  Future<ChangePasswordResultDto> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.authChangePassword,
        data: <String, dynamic>{
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );
      final map = res.data;
      if (map == null) {
        throw ApiException('Phản hồi không hợp lệ');
      }
      return ChangePasswordResultDto.fromJson(map);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

class ChangePasswordResultDto {
  const ChangePasswordResultDto({required this.success, required this.message});

  final bool success;
  final String message;

  factory ChangePasswordResultDto.fromJson(Map<String, dynamic> json) {
    return ChangePasswordResultDto(
      success: json['success'] == true,
      message: (json['message'] as String?)?.trim() ?? '',
    );
  }
}
