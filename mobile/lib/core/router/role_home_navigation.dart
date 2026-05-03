import '../auth/portal_loai.dart';
import 'app_routes.dart';

/// Thrown when `AspNetUsers.Loai` is not allowed for this app (not 1, 3, 4, 5, or 6).
final class UnsupportedPortalLoaiException implements Exception {
  UnsupportedPortalLoaiException(this.loai);
  final int? loai;

  @override
  String toString() => 'UnsupportedPortalLoaiException(loai: $loai)';
}

/// Single place for **Loai → shell home** navigation (do not duplicate in screens).
///
/// Shell đích sau đăng nhập / khôi phục phiên — **tách theo `Loai`** (consumer `/map` chỉ người dân).
String? roleHomeLocationForLoai(int? loai) {
  final role = mapLoaiToPortalRole(loai);
  if (role == null) {
    return null;
  }
  return roleHomeLocation(role);
}

/// Dashboard / home route for a validated [PortalRole] (from stored `Loai`).
String roleHomeLocation(PortalRole role) {
  switch (role) {
    case PortalRole.admin:
      return AppRoleHomePaths.admin;
    case PortalRole.trader:
      return AppRoleHomePaths.trader;
    case PortalRole.store:
      return AppRoleHomePaths.store;
    case PortalRole.citizen:
      return AppRoleHomePaths.citizen;
    case PortalRole.leader:
      return AppRoleHomePaths.leader;
  }
}

/// Canonical home paths per portal role (aligned with shell routes in [goRouterProvider]).
abstract final class AppRoleHomePaths {
  /// Loai = 1 — admin: màn placeholder (mobile).
  static const String admin = AppRoute.portalAdminHome;

  /// Loai = 3 — trader: màn placeholder (mobile).
  static const String trader = AppRoute.portalTraderHome;

  /// Loai = 4 — cửa hàng: shell quản lý, tab Bản đồ.
  static const String store = AppRoute.storeMap;

  /// Loai = 5 — người dân: shell tiêu dùng (= [AppRoute.map]).
  /// `static final` (không phải `const`) vì giá trị lấy từ enum field.
  static final String citizen = AppRoute.map.path;

  /// Loai = 6 — lãnh đạo: `LeaderMainScreen` (5 tab; mặc định Tổng quan).
  static const String leader = AppRoute.leaderOverview;
}
