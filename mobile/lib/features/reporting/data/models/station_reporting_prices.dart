import '../../../../core/network/json_utils.dart';
import 'fuel_price_line.dart';
import 'reporting_period.dart';

/// Backend: `StationReportingPricesDto`
class StationReportingPrices {
  const StationReportingPrices({
    this.period,
    required this.lines,
  });

  final ReportingPeriod? period;
  final List<FuelPriceLine> lines;

  factory StationReportingPrices.fromJson(Map<String, dynamic> json) {
    final raw = JsonUtils.readList(json['lines']);
    final lines = <FuelPriceLine>[];
    if (raw != null) {
      for (final e in raw) {
        final m = JsonUtils.readMap(e);
        if (m != null) {
          lines.add(FuelPriceLine.fromJson(m));
        }
      }
    }
    return StationReportingPrices(
      period: ReportingPeriod.parseNullable(json['period']),
      lines: lines,
    );
  }

  static StationReportingPrices? parseNullable(Object? json) {
    final m = JsonUtils.readMap(json);
    if (m == null) return null;
    return StationReportingPrices.fromJson(m);
  }
}
