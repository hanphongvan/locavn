import 'app_routes.dart';

/// Signed-out **Citizen** UX: map + tra cứu trạm công khai + tab Tài khoản (màn đăng nhập)
/// không bắt JWT; các route khác redirect về bản đồ hoặc chặn ở UI.
abstract final class CitizenGuestRouteAccess {
  CitizenGuestRouteAccess._();

  static String _normalizedPath(String matchedLocation) =>
      matchedLocation.split('?').first;

  /// Cho phép khi **chưa đăng nhập** (không gồm `/login`, `/register`, … — xử lý riêng trong GoRouter).
  static bool isPublicLocation(String matchedLocation) {
    final path = _normalizedPath(matchedLocation);
    if (path == AppRoute.map.path) return true;
    if (path.startsWith(AppRoute.stationDetailBase)) return true;
    if (path == AppRoute.more.path) return true;
    return false;
  }
}
