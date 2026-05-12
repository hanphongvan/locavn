import 'dart:io';

import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Wrapper quanh `sign_in_with_apple` — lấy ID token + fullName (chỉ lần đầu) để gửi BE.
///
/// iOS native (iOS 13+) work tự nhiên. Android/web cần Service ID + redirect URL → MVP
/// chỉ hỗ trợ iOS, [isAvailable] check `Platform.isIOS`.
class AppleSignInService {
  AppleSignInService();

  /// `true` khi platform là iOS (Apple Sign-In hợp lệ native). Android/web/Windows = false.
  bool get isAvailable => Platform.isIOS;

  /// Mở Apple Sign-In sheet → trả [AppleSignInResult] (idToken + fullName lần đầu).
  /// Throw [AppleSignInException] khi user huỷ / lỗi network / capability chưa cấu hình.
  Future<AppleSignInResult> signIn() async {
    if (!isAvailable) {
      throw const AppleSignInException(
        'Apple Sign-In chỉ hỗ trợ trên iOS trong phiên bản này.',
      );
    }

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AppleSignInException(
          'Apple không trả idToken — kiểm tra cấu hình Sign in with Apple trên Apple Developer + Runner.entitlements.',
        );
      }

      return AppleSignInResult(
        idToken: idToken,
        givenName: credential.givenName,
        familyName: credential.familyName,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      // user cancel hoặc lỗi authorize
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AppleSignInCancelledException();
      }
      throw AppleSignInException('Apple Sign-In thất bại: ${e.message}');
    } catch (e) {
      throw AppleSignInException('Apple Sign-In lỗi không xác định: $e');
    }
  }
}

class AppleSignInResult {
  const AppleSignInResult({
    required this.idToken,
    this.givenName,
    this.familyName,
  });

  final String idToken;

  /// Chỉ available LẦN ĐẦU user authorize. Lần sau Apple trả null — BE đã lưu sẵn.
  final String? givenName;
  final String? familyName;

  bool get hasFullName =>
      (givenName?.isNotEmpty ?? false) || (familyName?.isNotEmpty ?? false);
}

class AppleSignInException implements Exception {
  const AppleSignInException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AppleSignInCancelledException extends AppleSignInException {
  const AppleSignInCancelledException() : super('User cancelled Apple Sign-In');
}
