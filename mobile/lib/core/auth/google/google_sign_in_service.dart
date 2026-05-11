import 'package:google_sign_in/google_sign_in.dart';

import '../../network/api_config.dart';

/// Wrapper mỏng quanh `google_sign_in` để chỉ trả Google ID token cho backend
/// (`POST /api/oauth/google`). Backend chịu trách nhiệm verify + cấp JWT.
class GoogleSignInService {
  GoogleSignInService();

  GoogleSignIn? _instance;

  /// `false` khi chưa có `--dart-define=GOOGLE_SERVER_CLIENT_ID=...` — UI nên ẩn nút.
  bool get isConfigured => ApiConfig.googleServerClientId.isNotEmpty;

  GoogleSignIn _ensure() {
    final id = ApiConfig.googleServerClientId;
    if (id.isEmpty) {
      throw const GoogleSignInException(
        'Chưa cấu hình GOOGLE_SERVER_CLIENT_ID. '
        'Truyền --dart-define=GOOGLE_SERVER_CLIENT_ID=... khi build.',
      );
    }
    return _instance ??= GoogleSignIn(
      // serverClientId = Web client ID; ID token trả về sẽ có aud = id này,
      // backend kiểm tra trong GoogleAuth:AllowedAudiences.
      serverClientId: id,
      scopes: const ['email', 'profile', 'openid'],
    );
  }

  /// Mở Google chooser (hoặc silent nếu account đã chọn trước đó).
  /// Trả `null` nếu user huỷ; throw [GoogleSignInException] khi sai cấu hình / lỗi mạng.
  Future<String?> signInAndGetIdToken() async {
    final google = _ensure();

    GoogleSignInAccount? account;
    try {
      account = await google.signIn();
    } catch (e) {
      throw GoogleSignInException('Không thể mở đăng nhập Google: $e');
    }
    if (account == null) {
      // User cancelled.
      return null;
    }

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      // Cấu hình Android/iOS sai (thiếu OAuth client cùng SHA-1 / bundle id) → idToken null.
      await google.signOut();
      throw const GoogleSignInException(
        'Google không trả idToken — kiểm tra OAuth Client (Android SHA-1 / iOS bundle id) '
        'có trùng với cấu hình trên Google Cloud Console không.',
      );
    }
    return idToken;
  }

  /// Cleanup local state — gọi sau khi backend reject hoặc khi logout app.
  Future<void> signOut() async {
    if (_instance == null) return;
    try {
      await _instance!.signOut();
    } catch (_) {
      // ignore: best-effort cleanup
    }
  }
}

class GoogleSignInException implements Exception {
  const GoogleSignInException(this.message);
  final String message;

  @override
  String toString() => message;
}
