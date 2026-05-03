import '../../../../core/network/json_utils.dart';
import '../../../reporting/data/models/fuel_price_line.dart';
import '../../../reporting/data/models/reporting_period.dart';

/// Backend: `LatestFuelPricesResponseDto`
class LatestFuelPricesResponse {
  const LatestFuelPricesResponse({
    this.period,
    required this.items,
  });

  final ReportingPeriod? period;
  final List<FuelPriceLine> items;

  factory LatestFuelPricesResponse.fromJson(Map<String, dynamic> json) {
    final list = <FuelPriceLine>[];
    final raw = JsonUtils.readList(json['items']);
    if (raw != null) {
      for (final e in raw) {
        final m = JsonUtils.readMap(e);
        if (m != null) {
          list.add(FuelPriceLine.fromJson(m));
        }
      }
    }
    return LatestFuelPricesResponse(
      period: ReportingPeriod.parseNullable(json['period']),
      items: list,
    );
  }
}
