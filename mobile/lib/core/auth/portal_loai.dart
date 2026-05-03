/// Portal RBAC: maps `AspNetUsers.Loai` from the API (aligned with Angular `portal-loai-role.ts`).
///
/// | `Loai` | Role |
/// |--------|------|
/// | **1** | Admin |
/// | **3** | Trader |
/// | **4** | Store |
/// | **5** | Citizen |
/// | **6** | Leader — shell `/leader/overview` … `/leader/stabilization-fund` … `/leader/account` (chỉ xem) |
abstract final class PortalLoai {
  static const int admin = 1;
  static const int trader = 3;
  static const int store = 4;

  /// Người dùng phổ thông — đăng ký qua app (`AspNetUsers.Loai = 5`).
  static const int citizen = 5;

  /// Lãnh đạo — màn chính 5 tab (Tổng quan, Bản đồ, Phân tích, Quỹ bình ổn, Tài khoản); không nhập giá/tồn, không admin/trader/store shell, không CRUD người dân.
  static const int leader = 6;
}

/// Vai trò mobile: Admin, Trader, Store, Người dân, Lãnh đạo.
enum PortalRole { admin, trader, store, citizen, leader }

PortalRole? mapLoaiToPortalRole(int? loai) {
  if (loai == PortalLoai.admin) return PortalRole.admin;
  if (loai == PortalLoai.trader) return PortalRole.trader;
  if (loai == PortalLoai.store) return PortalRole.store;
  if (loai == PortalLoai.citizen) return PortalRole.citizen;
  if (loai == PortalLoai.leader) return PortalRole.leader;
  return null;
}

bool isAuthorizedPortalLoai(int? loai) => mapLoaiToPortalRole(loai) != null;

/// Nhãn hiển thị (menu Thêm, thông báo, …).
String portalRoleLabelVi(PortalRole role) {
  switch (role) {
    case PortalRole.admin:
      return 'Quản trị';
    case PortalRole.trader:
      return 'Thương nhân';
    case PortalRole.store:
      return 'Cửa hàng';
    case PortalRole.citizen:
      return 'Người dân';
    case PortalRole.leader:
      return 'Lãnh đạo';
  }
}
