import 'dart:math' as math;

import '../../reports/data/models/reports_overview_dto.dart';
import '../../reports/data/models/station_count_by_province.dart';

/// Ước tính số ngày dự trữ từ tồn và quy mô trạm (minh họa đến khi có API tiêu thụ thực).
double leaderDaysOfCover({
  required double totalStock,
  required int openStations,
  required bool isGasoline,
}) {
  if (totalStock <= 0) return 0;
  final perStation = isGasoline ? 14.0 : 9.5;
  final daily = openStations > 0 ? openStations * perStation : math.max(totalStock * 0.04, 1);
  return totalStock / daily;
}

/// Chuỗi điểm cho sparkline (xu hướng minh họa quanh mức tồn hiện tại).
List<double> leaderSparkSeries(double current, int seed) {
  if (current <= 0) return List<double>.filled(12, 0);
  const n = 12;
  return List<double>.generate(n, (i) {
    final t = i / (n - 1);
    final wobble = (((seed + i * 17) % 11) - 5) * 0.01;
    return current * (0.82 + 0.18 * t + wobble).clamp(0.001, double.infinity);
  });
}

class LeaderFlowEstimate {
  const LeaderFlowEstimate({
    required this.nhap,
    required this.xuat,
    required this.pctVsKyTruoc,
    this.pctXuatVsKy,
  });

  final double nhap;
  final double xuat;
  /// % so với kỳ trước — **Nhập**.
  final double pctVsKyTruoc;
  /// % so với kỳ trước — **Xuất** (null → dùng cùng logic minh họa một chiều).
  final double? pctXuatVsKy;

  double get pctXuatEffective => pctXuatVsKy ?? pctVsKyTruoc;
}

/// Nhập / xuất minh họa trong kỳ (ổn định theo seed) — thay bằng API khi có.
LeaderFlowEstimate leaderFlowPlaceholder({
  required double stockTonOrM3,
  required int periodDays,
  required int salt,
}) {
  final days = math.max(1, periodDays);
  final base = stockTonOrM3 * (0.045 + (salt % 7) * 0.004) / math.sqrt(days.toDouble());
  final double nhap = math.max(base, 0.0);
  // Hệ số 0.85–1.12: một phần seed cho cân đối âm (cảnh báo) trên UI minh họa.
  final double xuat = nhap * (0.85 + (salt % 13) * 0.022);
  final double prev = nhap / (1.032 + (salt % 3) * 0.01);
  final double pct = prev > 0 ? ((nhap - prev) / prev) * 100 : 0;
  final prevX = xuat / (1.028 + (salt % 5) * 0.008);
  final pctX = prevX > 0 ? ((xuat - prevX) / prevX) * 100 : pct * 0.92;
  return LeaderFlowEstimate(nhap: nhap, xuat: xuat, pctVsKyTruoc: pct, pctXuatVsKy: pctX);
}

int leaderReportingPeriodDays(ReportsOverviewDto overview) {
  final p = overview.stockSummary?.period;
  if (p == null) return 30;
  final tu = p.tuNgay;
  final den = p.denNgay;
  if (tu != null && den != null) {
    return math.max(1, den.difference(tu).inDays + 1);
  }
  return 30;
}

List<StationCountByProvince> leaderTopProvincesByStations(ReportsOverviewDto overview, {int take = 3}) {
  final list = [...overview.stationsByProvince]..sort((a, b) => b.stationCount.compareTo(a.stationCount));
  return list.take(take).toList(growable: false);
}
