import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';

class PasswordResetApi {
  PasswordResetApi(this._dio);

  final Dio _dio;

  static String? _messageFromData(dynamic data) {
    if (data is Map && data['message'] is String) {
      final m = (data['message'] as String).trim();
      if (m.isNotEmpty) return m;
    }
    return null;
  }

  /// Luôn trả về [ForgotPasswordResult] với message từ server (200).
  Future<ForgotPasswordResult> forgotPassword({required String email}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.authForgotPassword,
        data: {'email': email.trim()},
      );
      final map = res.data ?? {};
      return ForgotPasswordResult(
        message: map['message'] as String? ?? ForgotPasswordResult.defaultMessage,
      );
    } on DioException catch (e) {
      final m = _messageFromData(e.response?.data);
      if (m != null) {
        return ForgotPasswordResult(message: m);
      }
      rethrow;
    }
  }

  Future<ResetPasswordResult> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.authResetPassword,
        data: {
          'token': token,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );
      final map = res.data ?? {};
      return ResetPasswordResult(
        ok: true,
        message: map['message'] as String? ?? ResetPasswordResult.defaultSuccess,
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final m = _messageFromData(e.response?.data);
      if (code == 400 && m != null) {
        return ResetPasswordResult(ok: false, message: m);
      }
      rethrow;
    }
  }
}

class ForgotPasswordResult {
  ForgotPasswordResult({required this.message});

  static const defaultMessage =
      'Nếu email tồn tại trong hệ thống, chúng tôi đã gửi hướng dẫn đặt lại mật khẩu đến email của bạn.';

  final String message;
}

class ResetPasswordResult {
  ResetPasswordResult({required this.ok, required this.message});

  static const defaultSuccess = 'Mật khẩu đã được đặt lại thành công. Vui lòng đăng nhập lại.';

  final bool ok;
  final String message;
}
