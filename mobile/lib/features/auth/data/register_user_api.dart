import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_get_with_retry.dart';
import 'register_user_models.dart';

class RegisterUserApi {
  RegisterUserApi(this._dio);

  final Dio _dio;

  Future<List<RegisterRoleOptionDto>> getRoles() async {
    try {
      final res = await dioGetWithConnectionRetry<dynamic>(
        _dio,
        '/api/auth/register-user/roles',
        debugLabel: 'register-user/roles',
      );
      final list = (res.data as List<dynamic>?) ?? const [];
      return list
          .map((e) => RegisterRoleOptionDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((r) => r.id.isNotEmpty)
          .toList();
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<RegisterUserNameCheckDto> checkUserName(String username) async {
    try {
      final res = await dioGetWithConnectionRetry<dynamic>(
        _dio,
        '/api/auth/register-user/check-username',
        queryParameters: {'username': username},
        debugLabel: 'register-user/check-username',
      );
      final map = res.data;
      if (map is! Map) {
        throw ApiException('Phản hồi check-username không hợp lệ', statusCode: res.statusCode);
      }
      return RegisterUserNameCheckDto.fromJson(Map<String, dynamic>.from(map));
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<RegisterUserResponseDto> register(RegisterUserRequestDto body) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/auth/register-user',
        data: body.toJson(),
      );
      return RegisterUserResponseDto.fromJson(Map<String, dynamic>.from(res.data ?? {}));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
