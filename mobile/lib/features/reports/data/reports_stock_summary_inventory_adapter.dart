import '../../inventory/data/models/inventory_summary_response.dart';
import 'models/reports_system_inventory_line_dto.dart';

/// Chèn dòng tồn từ `stockSummary.byNhom` khi API không còn trả `systemInventory`.
///
/// Ánh xạ `nhom` (DM/template báo cáo): **1 = Xăng**, **2 = Dầu**, **3 = Khí** — điều chỉnh khi domain xác nhận mã khác.
List<ReportsSystemInventoryLineDto> inventoryLinesFromStockSummary(InventorySummaryResponse summary) {
  final out = <ReportsSystemInventoryLineDto>[];
  var syntheticId = 900_001;
  for (final g in summary.byNhom) {
    final name = _productNameForNhom(g.nhom);
    if (name == null) continue;
    final qty = g.sumSo01 ?? 0;
    out.add(
      ReportsSystemInventoryLineDto(
        productId: syntheticId++,
        productCode: 'NHOM_${g.nhom}',
        productName: name,
        currentQuantity: qty,
        unitTen: null,
      ),
    );
  }
  return out;
}

String? _productNameForNhom(int? nhom) {
  switch (nhom) {
    case 1:
      return 'Xăng';
    case 2:
      return 'Dầu';
    case 3:
      return 'Khí';
    default:
      return null;
  }
}
