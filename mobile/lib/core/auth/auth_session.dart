import 'portal_loai.dart';
import 'role_service.dart';

/// Persisted portal session after OAuth password grant + `/api/admin/auth/me`.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.userName,
    required this.donViId,
    required this.loai,
    required this.role,
    this.displayName,
    this.expiresIn,
    this.email,
    this.portalRole,
    this.fullSystemScope = false,
  });

  final String accessToken;
  final String userName;
  final int? donViId;
  final int? loai;
  final PortalRole role;
  final String? displayName;
  /// From OAuth `expires_in` when saved after login.
  final int? expiresIn;
  /// From `GET /api/admin/auth/me` when available.
  final String? email;
  /// Backend `role` string (`ADMIN` / `TRADER` / `STORE` / `PORTAL_USER` khi `Loai == 5`) khi có.
  final String? portalRole;
  /// From `AdminAuthMeDto.fullSystemScope`.
  final bool fullSystemScope;

  bool get isAuthorizedLoai => isAuthorizedPortalLoai(loai);

  bool get isStoreUser => RoleService.isStoreUser(loai);
}
