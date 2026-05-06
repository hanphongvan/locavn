/// Hằng số UI cho màn hình Leader Retail — gom 1 chỗ để dễ tinh chỉnh.
///
/// TODO: nếu cần config theo môi trường, chuyển sang remote config / AppSystemSettings.
abstract final class LeaderRetailUiLimits {
  /// Số cảnh báo hiển thị trên màn hình chính trước khi ẩn vào nút "Xem thêm".
  static const int initialWarningCount = 20;

  /// Ngưỡng tối thiểu để chip filter "Đơn vị quản lý" tự động dùng searchable bottom sheet
  /// thay vì popup menu (popup menu dưới ngưỡng này render OK).
  static const int managingUnitSearchableThreshold = 30;
}
