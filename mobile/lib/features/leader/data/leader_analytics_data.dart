import 'dart:math' as math;

import '../../reporting/data/models/fuel_price_line.dart';
import '../../reports/data/models/reports_overview_dto.dart';
import 'leader_fuel_filter.dart';

/// Khoảng thời gian biểu đồ tồn kho.
enum LeaderAnalyticsPeriod {
  d7('7 ngày', 7),
  d30('30 ngày', 30),
  d90('3 tháng', 90);

  const LeaderAnalyticsPeriod(this.label, this.days);
  final String label;
  final int days;
}

/// Chuỗi minh họa (đến khi có API time-series). Ổn định theo [seed].
List<double> leaderSyntheticStockSeries({
  required double endValue,
  required int points,
  required int seed,
  double volatility = 0.06,
}) {
  if (points <= 1) return [endValue];
  final out = <double>[];
  final start = endValue * (0.88 + (seed % 5) * 0.02);
  for (var i = 0; i < points; i++) {
    final t = i / (points - 1);
    final w = math.sin(seed * 0.31 + i * 0.7) * volatility;
    final v = start + (endValue - start) * t + endValue * w;
    out.add(v.clamp(0, double.infinity));
  }
  out[points - 1] = endValue;
  return out;
}

/// Giá đóng mỗi “ngày” minh họa quanh mức tham chiếu [base] (đồng/lít).
List<double> leaderSyntheticPriceSeries({
  required double base,
  required int points,
  required int seed,
}) {
  if (points <= 1) return [base];
  final out = <double>[];
  for (var i = 0; i < points; i++) {
    final t = i / (points - 1);
    final w = math.sin(seed * 0.17 + i * 0.55) * (base * 0.012);
    final v = base * (0.985 + 0.02 * t) + w;
    out.add(v.clamp(base * 0.94, base * 1.06));
  }
  out[points - 1] = base;
  return out;
}

double? _avgSo01(Iterable<FuelPriceLine> lines, bool Function(FuelPriceLine) pred) {
  final vals = lines.where(pred).map((e) => e.so01).whereType<num>().map((e) => e.toDouble()).toList();
  if (vals.isEmpty) return null;
  return vals.reduce((a, b) => a + b) / vals.length;
}

bool _isRon95Line(FuelPriceLine e) {
  final n = '${e.tenThongKe ?? ''} ${e.maSo ?? ''}'.toUpperCase();
  return n.contains('RON') && n.contains('95') && !n.contains('E5');
}

bool _isE5Ron92Line(FuelPriceLine e) {
  final n = '${e.tenThongKe ?? ''} ${e.maSo ?? ''}'.toUpperCase();
  return n.contains('E5') || (n.contains('RON') && n.contains('92'));
}

bool _isDieselLine(FuelPriceLine e) {
  final n = '${e.tenThongKe ?? ''} ${e.maSo ?? ''}'.toUpperCase();
  return n.contains('DIE') || n.contains('DO ') || n.contains('DẦU') || n.contains('DAU');
}

class LeaderReferencePrices {
  const LeaderReferencePrices({
    this.ron95,
    this.e5Ron92,
    this.diesel,
  });

  final double? ron95;
  final double? e5Ron92;
  final double? diesel;

  static LeaderReferencePrices fromLatestPrices(List<FuelPriceLine> items) {
    return LeaderReferencePrices(
      ron95: _avgSo01(items, _isRon95Line),
      e5Ron92: _avgSo01(items, _isE5Ron92Line),
      diesel: _avgSo01(items, _isDieselLine),
    );
  }

  /// Giá tham chiếu khi không khớp chuỗi tên (minh họa).
  static LeaderReferencePrices fallback() {
    return const LeaderReferencePrices(ron95: 22400, e5Ron92: 21500, diesel: 19800);
  }
}

({double xang, double dau}) leaderStockTotalsFromOverview(ReportsOverviewDto overview) {
  final inv = LeaderFuelFilter.withoutKhi(overview.systemInventory);
  final xang = LeaderFuelFilter.xangLines(inv);
  final dau = LeaderFuelFilter.dauLines(inv);
  final sumX = xang.fold<double>(0, (a, b) => a + b.currentQuantity);
  final sumD = dau.fold<double>(0, (a, b) => a + b.currentQuantity);
  return (xang: sumX, dau: sumD);
}

/// % thay đổi minh họa so “kỳ trước” (ổn định theo seed).
double leaderSyntheticPctChange(String key, int seed) {
  final h = Object.hash(key, seed);
  final v = (h % 200) / 10.0 - 10.0;
  return v.clamp(-12.0, 14.0);
}
