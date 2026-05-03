import '../../../../core/network/json_utils.dart';
import '../../../reporting/data/models/reporting_period.dart';
import 'inventory_nhom_group.dart';

/// Backend: `InventorySummaryResponseDto`
class InventorySummaryResponse {
  const InventorySummaryResponse({
    this.period,
    required this.reportingStationCount,
    required this.stockLineCount,
    this.totalSo01,
    required this.byNhom,
  });

  final ReportingPeriod? period;
  final int reportingStationCount;
  final int stockLineCount;
  final double? totalSo01;
  final List<InventoryNhomGroup> byNhom;

  factory InventorySummaryResponse.fromJson(Map<String, dynamic> json) {
    final groups = <InventoryNhomGroup>[];
    final raw = JsonUtils.readList(json['byNhom']);
    if (raw != null) {
      for (final e in raw) {
        final m = JsonUtils.readMap(e);
        if (m != null) {
          groups.add(InventoryNhomGroup.fromJson(m));
        }
      }
    }
    return InventorySummaryResponse(
      period: ReportingPeriod.parseNullable(json['period']),
      reportingStationCount: JsonUtils.readInt(json['reportingStationCount']) ?? 0,
      stockLineCount: JsonUtils.readInt(json['stockLineCount']) ?? 0,
      totalSo01: JsonUtils.readDouble(json['totalSo01']),
      byNhom: groups,
    );
  }
}
