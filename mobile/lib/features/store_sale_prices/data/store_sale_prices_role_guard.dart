import '../../../core/auth/portal_loai.dart';
import '../../../core/auth/portal_session_scope.dart';

/// RBAC for the **Nhập giá bán** data layer — **Store (`Loai == 4`) only**, with a bound `donViId`.
///
/// Angular additionally allows Admin/Trader on `/store-prices` (`RETAIL_PORTAL_ROLES`); this
/// Flutter feature is intentionally narrower (product requirement).
abstract final class StoreSalePricesRoleGuard {
  static bool isStoreLoai(int? loai) => loai == PortalLoai.store;

  /// `true` when the user may call store sale price repositories: Store + positive `donViId`.
  static bool canUseStoreSalePricesDataLayer(PortalSessionScope? scope) {
    if (scope == null) return false;
    if (!isStoreLoai(scope.loai)) return false;
    final id = scope.donViId;
    return id != null && id > 0;
  }
}
