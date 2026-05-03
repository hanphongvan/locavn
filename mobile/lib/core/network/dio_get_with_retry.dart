import 'dart:io' show HttpException, SocketException;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exception.dart';

/// LAN / payload lớn: server hoặc socket đôi khi đóng giữa chừng khi client đang đọc body.
bool isDioTransientConnectionLoss(DioException e) {
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout) {
    return true;
  }
  final err = e.error;
  if (err is HttpException) {
    final m = err.message.toLowerCase();
    if (m.contains('connection closed') || m.contains('broken pipe')) {
      return true;
    }
  }
  if (err is SocketException) {
    final m = err.message.toLowerCase();
    if (m.contains('connection reset') ||
        m.contains('broken pipe') ||
        m.contains('timed out') ||
        m.contains('connection refused')) {
      return true;
    }
  }
  final msg = '${e.message} $err'.toLowerCase();
  if (msg.contains('connection closed') ||
      msg.contains('connection reset') ||
      msg.contains('broken pipe')) {
    return true;
  }
  return false;
}

/// GET với vài lần thử lại khi mất kết nối tạm (LAN / JSON lớn — cùng ý tưởng [StationsApi._getWithConnectionRetry]).
Future<Response<T>> dioGetWithConnectionRetry<T>(
  Dio dio,
  String path, {
  Map<String, dynamic>? queryParameters,
  Options? options,
  String? debugLabel,
  int maxAttempts = 3,
}) async {
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      return await dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      final canRetry = attempt < maxAttempts - 1 && isDioTransientConnectionLoss(e);
      if (canRetry) {
        if (kDebugMode) {
          debugPrint(
            '[httm_xangdau] ${debugLabel ?? path} GET retry ${attempt + 1}/$maxAttempts after transient issue',
          );
        }
        await Future<void>.delayed(Duration(milliseconds: 350 + (attempt * 200)));
        continue;
      }
      throw ApiException.fromDio(e);
    }
  }
  throw StateError('dioGetWithConnectionRetry: unreachable');
}
