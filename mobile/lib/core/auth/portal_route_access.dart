import 'portal_loai.dart';
import '../router/app_routes.dart';
import '../router/citizen_guest_route_access.dart';

/// Central RBAC for mobile navigation (authoritative: stored `Loai` → [mapLoaiToPortalRole]).
///
/// Each role has a **disjoint** route set — no shared bottom shell between Store and Người dân.
abstract final class PortalRouteAccess {
  PortalRouteAccess._();

  /// Whether the signed-in user may open this path, using **stored `Loai`** from session.
  static bool isAllowedLocation(String matchedLocation, int? loai) {
    final role = mapLoaiToPortalRole(loai);
    final path = matchedLocation.split('?').first;

    if (path == AppRoute.splash ||
        path == AppRoute.login ||
        path == AppRoute.register ||
        path == AppRoute.forgotPassword ||
        path == AppRoute.resetPassword ||
        path == AppRoute.accessDenied) {
      return true;
    }

    if (role == null) {
      return CitizenGuestRouteAccess.isPublicLocation(matchedLocation);
    }

    if (path == AppRoute.changePassword.path || path.startsWith('${AppRoute.changePassword.path}/')) {
      return true;
    }

    if (path.startsWith(AppRoute.stationDetailBase)) {
      return true;
    }

    switch (role) {
      case PortalRole.citizen:
        return _citizenAllowed(path);
      case PortalRole.store:
        return _storeAllowed(path);
      case PortalRole.admin:
        return _adminAllowed(path);
      case PortalRole.trader:
        return _traderAllowed(path);
      case PortalRole.leader:
        return _leaderAllowed(path);
    }
  }

  static bool _citizenAllowed(String path) {
    if (_isStorePortalPath(path) || _isPortalRoleHomePath(path) || _isLeaderShellPath(path)) {
      return false;
    }
    if (path == AppRoute.inventoryStockMap || path.startsWith('${AppRoute.inventoryStockMap}/')) {
      return false;
    }
    if (path == AppRoute.storeSalePrices || path.startsWith('${AppRoute.storeSalePrices}/')) {
      return false;
    }

    if (path == AppRoute.map.path ||
        path == AppRoute.reports.path ||
        path == AppRoute.fuel.path ||
        path == AppRoute.addFuelTransaction.path ||
        path == AppRoute.fuelTransactionsHistory.path ||
        path == AppRoute.myVehicles.path ||
        path == AppRoute.more.path ||
        path == AppRoute.myViolationReports.path ||
        path == AppRoute.myStationReviews.path) {
      return true;
    }
    return false;
  }

  static bool _storeAllowed(String path) {
    if (path == AppRoute.map.path ||
        path == AppRoute.reports.path ||
        path == AppRoute.fuel.path ||
        path == AppRoute.addFuelTransaction.path ||
        path == AppRoute.fuelTransactionsHistory.path ||
        path == AppRoute.myVehicles.path ||
        path == AppRoute.more.path ||
        path == AppRoute.myViolationReports.path ||
        path == AppRoute.myStationReviews.path) {
      return false;
    }
    if (_isPortalRoleHomePath(path) || _isLeaderShellPath(path)) {
      return false;
    }
    if (path == AppRoute.inventoryStockMap || path.startsWith('${AppRoute.inventoryStockMap}/')) {
      return false;
    }

    if (path == AppRoute.storeRoot ||
        path == AppRoute.storeMap ||
        path == AppRoute.storeSalePrices ||
        path == AppRoute.storeServices ||
        path == AppRoute.storeInventory ||
        path == AppRoute.storeAccount) {
      return true;
    }
    if (path.startsWith('${AppRoute.storeRoot}/')) {
      return true;
    }
    return false;
  }

  static bool _adminAllowed(String path) {
    if (_isStorePortalPath(path) || _isCitizenShellPath(path) || _isLeaderShellPath(path)) {
      return false;
    }
    if (path == AppRoute.portalTraderHome || path.startsWith('${AppRoute.portalTraderHome}/')) {
      return false;
    }
    if (path == AppRoute.portalAdminHome || path.startsWith('${AppRoute.portalAdminHome}/')) {
      return true;
    }
    if (path == AppRoute.inventoryStockMap || path.startsWith('${AppRoute.inventoryStockMap}/')) {
      return true;
    }
    return false;
  }

  static bool _traderAllowed(String path) {
    if (_isStorePortalPath(path) || _isCitizenShellPath(path) || _isLeaderShellPath(path)) {
      return false;
    }
    if (path == AppRoute.portalAdminHome || path.startsWith('${AppRoute.portalAdminHome}/')) {
      return false;
    }
    if (path == AppRoute.inventoryStockMap || path.startsWith('${AppRoute.inventoryStockMap}/')) {
      return false;
    }
    if (path == AppRoute.portalTraderHome || path.startsWith('${AppRoute.portalTraderHome}/')) {
      return true;
    }
    return false;
  }

  /// **Leader** (`Loai == 6`): chỉ shell lãnh đạo (`/leader/overview`, `/leader/map`, `/leader/retail`,
  /// `/leader/analytics`, `/leader/stabilization-fund`) + `/leader/account` (mở qua icon AppBar) +
  /// đổi mật khẩu + chi tiết trạm (xem).
  ///
  /// Chặn: nhập **giá** / **tồn** (shell cửa hàng, phiếu kho, bản đồ tồn admin), **admin/trader**, dashboard báo cáo `/reports`,
  /// shell **người dân** (Nhiên liệu / xe / CRUD đổ xăng, …).
  static bool _leaderAllowed(String path) {
    if (_isStorePortalPath(path)) {
      return false;
    }
    if (_isCitizenShellPath(path)) {
      return false;
    }
    if (_isPortalRoleHomePath(path)) {
      return false;
    }
    if (path == AppRoute.inventoryStockMap || path.startsWith('${AppRoute.inventoryStockMap}/')) {
      return false;
    }
    if (path == AppRoute.reports.path || path.startsWith('${AppRoute.reports.path}/')) {
      return false;
    }

    // Allow-list only — no wildcard under `/leader/` (future sub-routes must be opted in).
    return path == AppRoute.leaderRoot ||
        path == AppRoute.leaderOverview ||
        path == AppRoute.leaderMap ||
        path == AppRoute.leaderRetail ||
        path == AppRoute.leaderAnalytics ||
        path == AppRoute.leaderStabilizationFund ||
        path == AppRoute.leaderAccount ||
        path == AppRoute.leaderAiChat;
  }

  static bool _isStorePortalPath(String path) {
    return path == AppRoute.storeRoot ||
        path.startsWith('${AppRoute.storeRoot}/');
  }

  static bool _isPortalRoleHomePath(String path) {
    return path == AppRoute.portalAdminHome ||
        path.startsWith('${AppRoute.portalAdminHome}/') ||
        path == AppRoute.portalTraderHome ||
        path.startsWith('${AppRoute.portalTraderHome}/');
  }

  static bool _isLeaderShellPath(String path) {
    return path == AppRoute.leaderRoot ||
        path.startsWith('${AppRoute.leaderRoot}/');
  }

  static bool _isCitizenShellPath(String path) {
    return path == AppRoute.map.path ||
        path == AppRoute.reports.path ||
        path == AppRoute.fuel.path ||
        path == AppRoute.addFuelTransaction.path ||
        path == AppRoute.fuelTransactionsHistory.path ||
        path == AppRoute.myVehicles.path ||
        path == AppRoute.more.path ||
        path == AppRoute.myViolationReports.path ||
        path == AppRoute.myStationReviews.path;
  }

  /// Session thuộc portal A nhưng [matchedLocation] vẫn là route shell portal B (vd Leader đăng nhập
  /// xong GoRouter còn `/more` hoặc `/map` của Citizen).
  ///
  /// Trả về `true` → [goRouterProvider] redirect thẳng về home đúng [Loai], **không** qua AccessDenied.
  /// Tránh vừa cấm RBAC vừa còn `IndexedStack` + Google Map platform view — dễ gây crash Android
  /// (`SurfaceProducer.getWidth()` null khi dispose/resize).
  static bool shouldBounceFromForeignPortalShell(String matchedLocation, int? loai) {
    final role = mapLoaiToPortalRole(loai);
    if (role == null) return false;
    final path = matchedLocation.split('?').first;

    return switch (role) {
      PortalRole.leader =>
        _isCitizenShellPath(path) || _isStorePortalPath(path) || _isPortalRoleHomePath(path),
      PortalRole.citizen =>
        _isLeaderShellPath(path) || _isStorePortalPath(path) || _isPortalRoleHomePath(path),
      PortalRole.store =>
        _isCitizenShellPath(path) || _isLeaderShellPath(path) || _isPortalRoleHomePath(path),
      PortalRole.admin =>
        _isCitizenShellPath(path) || _isStorePortalPath(path) || _isLeaderShellPath(path),
      PortalRole.trader =>
        _isCitizenShellPath(path) || _isStorePortalPath(path) || _isLeaderShellPath(path),
    };
  }

  /// Inventory stock map (`/inventory/stock-map`) — **Admin (`Loai == 1`) only** (Angular parity).
  static bool canAccessInventoryStockMap(int? loai) =>
      mapLoaiToPortalRole(loai) == PortalRole.admin;

  /// Nhập giá bán — **Store (`Loai == 4`)** (tab trong shell cửa hàng).
  static bool canAccessStoreSalePrices(int? loai) =>
      mapLoaiToPortalRole(loai) == PortalRole.store;
}
