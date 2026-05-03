import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'admin_api_credentials.dart';

/// Central place: attach `Authorization: Bearer` from in-memory [AuthSessionController.session]
/// when available, otherwise [localPersistentSessionStoreProvider] (Android Keystore reads are
/// noticeably slower than RAM on every request). On **401** after a Bearer request,
/// [AuthSessionController.logout] clears storage + login.
final class AuthHttpInterceptor extends Interceptor {
  AuthHttpInterceptor(this._ref);

  final Ref _ref;

  static bool _isOAuthTokenRequest(String path) =>
      path.endsWith('/api/oauth/token') || path.endsWith('/api/oauth/store-admin/token');

  static bool _isAnonymousPasswordReset(String path) =>
      path.endsWith('/api/auth/forgot-password') || path.endsWith('/api/auth/reset-password');

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final path = options.uri.path;
    if (_isOAuthTokenRequest(path) || _isAnonymousPasswordReset(path)) {
      handler.next(options);
      return;
    }

    try {
      var token = _ref.read(authSessionControllerProvider).accessToken?.trim();
      if (token == null || token.isEmpty) {
        token = (await _ref.read(localPersistentSessionStoreProvider).getAccessToken())?.trim();
      }
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      } else if (path.contains('/api/admin')) {
        AdminApiCredentials.applyToAdminRequest(options);
      } else if (path.contains('/api/auth/register-user')) {
        AdminApiCredentials.applyToPublicRegisterUserRequest(options);
      }
    } catch (e, st) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: e,
          stackTrace: st,
          type: DioExceptionType.unknown,
        ),
      );
      return;
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final auth = err.requestOptions.headers['Authorization']?.toString() ?? '';
    if (status == 401 && auth.startsWith('Bearer ')) {
      await _ref.read(authSessionControllerProvider).logout();
    }
    handler.next(err);
  }
}
