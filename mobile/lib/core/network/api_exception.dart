import 'package:dio/dio.dart';

import 'dio_user_message.dart';

/// Maps HTTP failures and parse errors for UI (`AsyncValue` / snackbars).
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.cause});

  final String message;
  final int? statusCode;
  final Object? cause;

  factory ApiException.fromDio(DioException e) {
    final code = e.response?.statusCode;
    final msg = messageForDioException(e);
    return ApiException(msg, statusCode: code, cause: e);
  }

  factory ApiException.fromResponse(Response<dynamic> response, {String? fallback}) {
    final data = response.data;
    var msg = fallback ?? 'Yêu cầu thất bại';
    if (data is Map) {
      final detail = data['detail'] ?? data['title'];
      if (detail is String && detail.isNotEmpty) {
        msg = detail;
      }
    }
    return ApiException(msg, statusCode: response.statusCode);
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
