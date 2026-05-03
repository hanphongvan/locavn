import '../../../../core/network/json_utils.dart';
import 'fuel_stock_line.dart';
import 'reporting_period.dart';

/// Backend: `StationReportingStockDto`
class StationReportingStock {
  const StationReportingStock({
    this.period,
    required this.lineCount,
    this.totalSo01,
    required this.lines,
  });

  final ReportingPeriod? period;
  final int lineCount;
  final double? totalSo01;
  final List<FuelStockLine> lines;

  factory StationReportingStock.fromJson(Map<String, dynamic> json) {
    final raw = JsonUtils.readList(json['lines']);
    final lines = <FuelStockLine>[];
    if (raw != null) {
      for (final e in raw) {
        final m = JsonUtils.readMap(e);
        if (m != null) {
          lines.add(FuelStockLine.fromJson(m));
        }
      }
    }
    return StationReportingStock(
      period: ReportingPeriod.parseNullable(json['period']),
      lineCount: JsonUtils.readInt(json['lineCount']) ?? 0,
      totalSo01: JsonUtils.readDouble(json['totalSo01']),
      lines: lines,
    );
  }

  static StationReportingStock? parseNullable(Object? json) {
    final m = JsonUtils.readMap(json);
    if (m == null) return null;
    return StationReportingStock.fromJson(m);
  }
}
