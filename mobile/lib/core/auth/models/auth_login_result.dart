import 'admin_auth_me.dart';
import 'oauth_token_login_response.dart';
import '../auth_session.dart';

/// Successful [AuthService.login]: token body, portal profile, persisted session.
class AuthLoginResult {
  const AuthLoginResult({
    required this.tokenResponse,
    required this.profile,
    required this.session,
  });

  final OAuthTokenLoginResponse tokenResponse;
  final AdminAuthMe profile;
  final AuthSession session;
}
