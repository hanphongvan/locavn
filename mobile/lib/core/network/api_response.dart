import 'package:dio/dio.dart';

import 'api_exception.dart';

/// Shared success / error handling for Dio calls (no mock payloads).
abstract final class ApiResponseHandler {
  /// Expects 2xx with JSON body decoded to [data]. Non-2xx → [ApiException].
  static T decode<T>(
    Response<dynamic> response,
    T Function(dynamic data) parse,
  ) {
    final code = response.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      throw ApiException.fromResponse(response);
    }
    try {
      return parse(response.data);
    } on FormatException catch (e, st) {
      throw ApiException('Invalid response: $e', cause: st);
    }
  }

  /// Same as [decode] but allows `null` body (e.g. 204). [parse] receives `null`.
  static T decodeAllowNull<T>(
    Response<dynamic> response,
    T Function(dynamic data) parse,
  ) {
    final code = response.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      throw ApiException.fromResponse(response);
    }
    try {
      return parse(response.data);
    } on FormatException catch (e, st) {
      throw ApiException('Invalid response: $e', cause: st);
    }
  }
}
