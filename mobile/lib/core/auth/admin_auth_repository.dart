import 'package:dio/dio.dart';

import '../network/api_config.dart';
import '../network/api_exception.dart';
import '../network/dio_user_message.dart';
import 'models/admin_auth_me.dart';

/// OAuth2 resource-owner password grant + portal profile (same sequence as Angular admin).
class AdminAuthRepository {
  AdminAuthRepository(this._dio);

  final Dio _dio;

  static const _formType = Headers.formUrlEncodedContentType;

  /// `POST /api/oauth/token` (x-www-form-urlencoded) — full JSON body on success.
  ///
  /// Same fields as Angular `HttpParams` + `application/x-www-form-urlencoded`; Dio encodes
  /// [Map] bodies as `grant_type=password&username=…&password=…` for this content type.
  Future<Map<String, dynamic>> fetchOAuthPasswordGrantJson({
    required String username,
    required String password,
  }) async {
    final body = <String, dynamic>{
      'grant_type': 'password',
      'username': username.trim(),
      'password': password,
    };
    final response = await _dio.post<Object>(
      '/api/oauth/token',
      data: body,
      options: Options(contentType: _formType),
    );
    final data = response.data;
    if (data is! Map) {
      throw const AdminAuthException('Phản hồi đăng nhập không hợp lệ.');
    }
    final map = data.cast<String, dynamic>();
    final err = map['error'] as String?;
    if (err != null) {
      final desc = map['error_description'] as String? ?? err;
      throw AdminAuthException(desc);
    }
    final token = map['access_token'];
    if (token is! String || token.trim().isEmpty) {
      throw const AdminAuthException('Phản hồi đăng nhập không chứa access_token hợp lệ.');
    }
    return map;
  }

  /// `POST /api/oauth/google` (application/json) với Google ID token. Backend verify + cấp JWT
  /// cùng shape với password grant (`access_token`, `userName`, `loai`, …).
  Future<Map<String, dynamic>> fetchOAuthGoogleGrantJson({
    required String idToken,
  }) async {
    final response = await _dio.post<Object>(
      '/api/oauth/google',
      data: <String, dynamic>{'idToken': idToken},
    );
    final data = response.data;
    if (data is! Map) {
      throw const AdminAuthException('Phản hồi đăng nhập Google không hợp lệ.');
    }
    final map = data.cast<String, dynamic>();
    final err = map['error'] as String?;
    if (err != null) {
      final desc = map['error_description'] as String? ?? err;
      throw AdminAuthException(desc);
    }
    final token = map['access_token'];
    if (token is! String || token.trim().isEmpty) {
      throw const AdminAuthException('Phản hồi Google không chứa access_token hợp lệ.');
    }
    return map;
  }

  /// `POST /api/oauth/token` (x-www-form-urlencoded).
  Future<String> fetchAccessToken({
    required String username,
    required String password,
  }) async {
    final map = await fetchOAuthPasswordGrantJson(
      username: username,
      password: password,
    );
    return (map['access_token'] as String).trim();
  }

  /// `GET /api/admin/auth/me` (Bearer JWT).
  Future<AdminAuthMe> fetchCurrentUser(String accessToken) async {
    final response = await _dio.get<Object>(
      '/api/admin/auth/me',
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );
    final data = response.data;
    if (data is! Map) {
      throw const AdminAuthException('Không đọc được hồ sơ người dùng.');
    }
    return AdminAuthMe.fromJson(data.cast<String, dynamic>());
  }

  /// Password grant then profile (authoritative for `Loai` / `DonViId`).
  Future<({String accessToken, AdminAuthMe me})> login({
    required String username,
    required String password,
  }) async {
    final map = await fetchOAuthPasswordGrantJson(
      username: username,
      password: password,
    );
    final accessToken = (map['access_token'] as String).trim();
    final me = await fetchCurrentUser(accessToken);
    return (accessToken: accessToken, me: me);
  }
}

class AdminAuthException implements Exception {
  const AdminAuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Dio factory for login + `/me` only (no app-wide interceptors / circular deps).
Dio createAdminAuthDio() {
  return Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 60),
      headers: const {'Accept': 'application/json'},
    ),
  );
}

String? dioErrorUserMessage(Object error) {
  if (error is AdminAuthException) {
    return error.message;
  }
  if (error is DioException) {
    return messageForDioException(error);
  }
  if (error is ApiException) {
    return error.message;
  }
  return error.toString();
}
