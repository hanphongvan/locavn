import '../../../../core/network/json_utils.dart';
import '../../../inventory/data/models/inventory_summary_response.dart';

import 'reports_system_inventory_line_dto.dart';
import 'station_count_by_province.dart';
import '../reports_stock_summary_inventory_adapter.dart';

/// Backend: `ReportsOverviewDto` (`stockSummary` + legacy `systemInventory`).
class ReportsOverviewDto {
  const ReportsOverviewDto({
    required this.totalStations,
    required this.openStations,
    required this.closedStations,
    required this.stationsByProvince,
    required this.systemInventory,
    this.stockSummary,
    this.notes,
  });

  final int totalStations;
  final int openStations;
  final int closedStations;
  final List<StationCountByProvince> stationsByProvince;
  final List<ReportsSystemInventoryLineDto> systemInventory;
  /// Tổng tồn theo kỳ báo cáo (`InventorySummaryResponseDto`) khi pipeline trả về.
  final InventorySummaryResponse? stockSummary;
  final List<String>? notes;

  factory ReportsOverviewDto.fromJson(Map<String, dynamic> json) {
    final byProv = <StationCountByProvince>[];
    final rawProv = JsonUtils.readList(json['stationsByProvince']);
    if (rawProv != null) {
      for (final e in rawProv) {
        final m = JsonUtils.readMap(e);
        if (m != null) {
          byProv.add(StationCountByProvince.fromJson(m));
        }
      }
    }

    final noteList = <String>[];
    final rawNotes = JsonUtils.readList(json['notes']);
    if (rawNotes != null) {
      for (final e in rawNotes) {
        final s = JsonUtils.readString(e);
        if (s != null && s.isNotEmpty) {
          noteList.add(s);
        }
      }
    }

    final inv = <ReportsSystemInventoryLineDto>[];
    final rawInv = JsonUtils.readList(json['systemInventory']);
    if (rawInv != null) {
      for (final e in rawInv) {
        final m = JsonUtils.readMap(e);
        if (m != null) {
          inv.add(ReportsSystemInventoryLineDto.fromJson(m));
        }
      }
    }

    InventorySummaryResponse? stockSummary;
    final rawStock = JsonUtils.readMap(json['stockSummary']);
    if (rawStock != null) {
      final parsed = InventorySummaryResponse.fromJson(rawStock);
      stockSummary = parsed;
      if (inv.isEmpty && parsed.byNhom.isNotEmpty) {
        inv.addAll(inventoryLinesFromStockSummary(parsed));
      }
    }

    return ReportsOverviewDto(
      totalStations: JsonUtils.readInt(json['totalStations']) ?? 0,
      openStations: JsonUtils.readInt(json['openStations']) ?? 0,
      closedStations: JsonUtils.readInt(json['closedStations']) ?? 0,
      stationsByProvince: byProv,
      systemInventory: inv,
      stockSummary: stockSummary,
      notes: noteList.isEmpty ? null : noteList,
    );
  }
}
