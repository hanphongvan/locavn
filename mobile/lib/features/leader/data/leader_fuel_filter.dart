import '../../reports/data/models/reports_system_inventory_line_dto.dart';

/// Phân loại dòng tồn kho hệ thống — loại trừ sản phẩm ngoài phạm vi tab (theo tên/mã).
abstract final class LeaderFuelFilter {
  LeaderFuelFilter._();

  static bool isKhiLine(ReportsSystemInventoryLineDto l) {
    final n = l.productName.toLowerCase();
    final c = l.productCode.toUpperCase();
    return n.contains('khí') ||
        n.contains('khi ') ||
        n.contains('gas') ||
        n.contains('lpg') ||
        c.contains('LPG') ||
        c.contains('GAS');
  }

  /// Chỉ giữ Xăng + Dầu.
  static List<ReportsSystemInventoryLineDto> withoutKhi(Iterable<ReportsSystemInventoryLineDto> lines) {
    return lines.where((l) => !isKhiLine(l)).toList(growable: false);
  }

  static bool isDauLine(ReportsSystemInventoryLineDto l) {
    final n = l.productName.toLowerCase();
    final c = l.productCode.toUpperCase();
    return n.contains('dầu') ||
        n.contains('dau') ||
        c.contains('DIE') ||
        c.contains('DO') ||
        c.contains('DO0');
  }

  static List<ReportsSystemInventoryLineDto> xangLines(Iterable<ReportsSystemInventoryLineDto> lines) {
    return withoutKhi(lines).where((l) => !isDauLine(l)).toList(growable: false);
  }

  static List<ReportsSystemInventoryLineDto> dauLines(Iterable<ReportsSystemInventoryLineDto> lines) {
    return withoutKhi(lines).where(isDauLine).toList(growable: false);
  }
}
