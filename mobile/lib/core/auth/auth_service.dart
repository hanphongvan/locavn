import 'admin_auth_repository.dart';
import 'apple/apple_sign_in_service.dart';
import 'auth_session.dart';
import 'google/google_sign_in_service.dart';
import 'local_persistent_session_store.dart';
import 'models/admin_auth_me.dart';
import 'models/auth_login_result.dart';
import 'models/oauth_token_login_response.dart';
import 'portal_loai.dart';
import 'role_service.dart';
import '../router/role_home_navigation.dart';

/// Application auth facade: OAuth2 password grant (`POST /api/oauth/token`) + `GET /api/admin/auth/me`,
/// same contract as Angular admin (no custom protocol).
class AuthService {
  AuthService(this._repository, this._sessionStore, this._googleSignIn, this._appleSignIn);

  final AdminAuthRepository _repository;
  final LocalPersistentSessionStore _sessionStore;
  final GoogleSignInService _googleSignIn;
  final AppleSignInService _appleSignIn;

  AppleSignInService get appleSignIn => _appleSignIn;

  /// Same path Angular uses: `{baseUrl}/api/oauth/token` (OAuth “token” endpoint).
  static const String oauthTokenPath = '/api/oauth/token';

  /// Profile endpoint aligned with Angular admin.
  static const String adminAuthMePath = '/api/admin/auth/me';

  /// `true` when secure storage holds a valid portal session (including allowed `Loai`).
  Future<bool> isLoggedIn() async {
    final s = await _sessionStore.readValidatedSession();
    return s != null;
  }

  /// Current Bearer access token from storage, or `null`.
  Future<String?> getToken() async {
    return _sessionStore.getAccessToken();
  }

  /// Loads portal profile from the server using the stored token; `null` if not logged in.
  Future<AdminAuthMe?> getCurrentUser() async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      return null;
    }
    return _repository.fetchCurrentUser(token);
  }

  /// Full local sign-out: removes **all** persisted session keys ([LocalSessionStorageKeys.allKeys]):
  /// `access_token`, `username`, `DonViId`, `Loai`, `expires_in`, `displayName`, `email`,
  /// `portalRole`, `fullSystemScope`. Cũng clear Google session để lần sau hiện lại account chooser.
  ///
  /// In-memory session is reset by [AuthSessionController.logout] after this returns.
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _sessionStore.clearSession();
  }

  /// Cold start: reads [AuthSession] from local secure storage (no network). Used by
  /// [AuthSessionController.restoreFromLocalStorage] via `AppSessionBootstrap`.
  Future<AuthSession?> loadPersistedSession() => _sessionStore.readValidatedSession();

  /// `true` when persisted `Loai` is **Store** (4). Uses secure storage (no in-memory session required).
  Future<bool> isStoreUser() async {
    final loai = await _sessionStore.getLoai();
    return RoleService.isStoreUser(loai);
  }

  /// Resource-owner login: `POST /api/oauth/token` then [`GET /api/admin/auth/me`](adminAuthMePath)
  /// (required — same as Angular). Profile fields merge OAuth ticket extras when `/me` omits them.
  ///
  /// On success, [LocalPersistentSessionStore.saveSession] persists **DonViId**, **username**,
  /// **Loai** (with access token and profile extras) for cold start and role-based routing.
  ///
  /// Returns parsed token response + resolved profile + session. Throws [AdminAuthException] or
  /// [UnsupportedPortalLoaiException] on failure; nothing is persisted until both steps succeed.
  Future<AuthLoginResult> login(String username, String password) async {
    final map = await _repository.fetchOAuthPasswordGrantJson(
      username: username,
      password: password,
    );
    final tokenResponse = OAuthTokenLoginResponse.fromJson(map);
    final profile = await _resolveProfileAfterToken(
      accessToken: tokenResponse.accessToken,
      tokenResponse: tokenResponse,
      loginUsername: username,
    );
    final role = mapLoaiToPortalRole(profile.loai);
    if (role == null) {
      throw UnsupportedPortalLoaiException(profile.loai);
    }
    await _sessionStore.saveSession(
      accessToken: tokenResponse.accessToken,
      username: profile.userName,
      donViId: profile.donViId,
      loai: profile.loai,
      expiresIn: tokenResponse.expiresIn,
      displayName: profile.displayName,
      email: profile.email,
      portalRole: profile.role,
      fullSystemScope: profile.fullSystemScope,
    );
    final session = AuthSession(
      accessToken: tokenResponse.accessToken,
      userName: profile.userName,
      donViId: profile.donViId,
      loai: profile.loai,
      role: role,
      displayName: profile.displayName,
      expiresIn: tokenResponse.expiresIn,
      email: profile.email,
      portalRole: profile.role,
      fullSystemScope: profile.fullSystemScope,
    );
    return AuthLoginResult(
      tokenResponse: tokenResponse,
      profile: profile,
      session: session,
    );
  }

  /// Google Sign-In flow cho citizen (Loai=5). Mở chooser → lấy ID token → `POST /api/oauth/google`
  /// → fetch `/me` → persist session. Trả `null` nếu user huỷ chooser.
  ///
  /// Throws [AdminAuthException], [GoogleSignInException], hoặc [UnsupportedPortalLoaiException].
  Future<AuthLoginResult?> loginWithGoogle() async {
    final idToken = await _googleSignIn.signInAndGetIdToken();
    if (idToken == null) {
      return null;
    }
    final map = await _repository.fetchOAuthGoogleGrantJson(idToken: idToken);
    final tokenResponse = OAuthTokenLoginResponse.fromJson(map);
    final profile = await _resolveProfileAfterToken(
      accessToken: tokenResponse.accessToken,
      tokenResponse: tokenResponse,
      loginUsername: '',
    );
    final role = mapLoaiToPortalRole(profile.loai);
    if (role == null) {
      await _googleSignIn.signOut();
      throw UnsupportedPortalLoaiException(profile.loai);
    }
    await _sessionStore.saveSession(
      accessToken: tokenResponse.accessToken,
      username: profile.userName,
      donViId: profile.donViId,
      loai: profile.loai,
      expiresIn: tokenResponse.expiresIn,
      displayName: profile.displayName,
      email: profile.email,
      portalRole: profile.role,
      fullSystemScope: profile.fullSystemScope,
    );
    final session = AuthSession(
      accessToken: tokenResponse.accessToken,
      userName: profile.userName,
      donViId: profile.donViId,
      loai: profile.loai,
      role: role,
      displayName: profile.displayName,
      expiresIn: tokenResponse.expiresIn,
      email: profile.email,
      portalRole: profile.role,
      fullSystemScope: profile.fullSystemScope,
    );
    return AuthLoginResult(
      tokenResponse: tokenResponse,
      profile: profile,
      session: session,
    );
  }

  /// Apple Sign-In flow cho citizen (iOS only). Trả `null` nếu user huỷ Apple sheet.
  ///
  /// Throws [AdminAuthException], [AppleSignInException], hoặc [UnsupportedPortalLoaiException].
  Future<AuthLoginResult?> loginWithApple() async {
    final AppleSignInResult appleResult;
    try {
      appleResult = await _appleSignIn.signIn();
    } on AppleSignInCancelledException {
      return null;
    }
    final map = await _repository.fetchOAuthAppleGrantJson(
      idToken: appleResult.idToken,
      givenName: appleResult.givenName,
      familyName: appleResult.familyName,
    );
    final tokenResponse = OAuthTokenLoginResponse.fromJson(map);
    final profile = await _resolveProfileAfterToken(
      accessToken: tokenResponse.accessToken,
      tokenResponse: tokenResponse,
      loginUsername: '',
    );
    final role = mapLoaiToPortalRole(profile.loai);
    if (role == null) {
      throw UnsupportedPortalLoaiException(profile.loai);
    }
    await _sessionStore.saveSession(
      accessToken: tokenResponse.accessToken,
      username: profile.userName,
      donViId: profile.donViId,
      loai: profile.loai,
      expiresIn: tokenResponse.expiresIn,
      displayName: profile.displayName,
      email: profile.email,
      portalRole: profile.role,
      fullSystemScope: profile.fullSystemScope,
    );
    final session = AuthSession(
      accessToken: tokenResponse.accessToken,
      userName: profile.userName,
      donViId: profile.donViId,
      loai: profile.loai,
      role: role,
      displayName: profile.displayName,
      expiresIn: tokenResponse.expiresIn,
      email: profile.email,
      portalRole: profile.role,
      fullSystemScope: profile.fullSystemScope,
    );
    return AuthLoginResult(
      tokenResponse: tokenResponse,
      profile: profile,
      session: session,
    );
  }

  /// Same contract as Angular admin: `/me` must succeed after password grant before the session is persisted.
  Future<AdminAuthMe> _resolveProfileAfterToken({
    required String accessToken,
    required OAuthTokenLoginResponse tokenResponse,
    required String loginUsername,
  }) async {
    final api = await _repository.fetchCurrentUser(accessToken);
    return _mergeApiProfileWithTokenResponse(api, tokenResponse, loginUsername);
  }
}

AdminAuthMe _mergeApiProfileWithTokenResponse(
  AdminAuthMe api,
  OAuthTokenLoginResponse token,
  String loginUsername,
) {
  final mergedName = api.userName.trim().isNotEmpty
      ? api.userName.trim()
      : _usernameFromTokenOrLogin(token.userName, loginUsername);
  return AdminAuthMe(
    userName: mergedName,
    displayName: api.displayName ?? token.displayName,
    email: api.email,
    donViId: api.donViId ?? int.tryParse(token.idDonVi ?? ''),
    loai: api.loai ?? int.tryParse(token.loai ?? ''),
    role: api.role,
    fullSystemScope: api.fullSystemScope,
  );
}

String _usernameFromTokenOrLogin(String? tokenUserName, String loginUsername) {
  final t = tokenUserName?.trim();
  if (t != null && t.isNotEmpty) {
    return t;
  }
  return loginUsername.trim();
}
