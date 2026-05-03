import '../../stations/data/models/station_map_item.dart';
import '../data/leader_map_ui_state.dart';

/// Tồn kho / ngày dự trữ minh họa cho cửa hàng (API map chưa có trường tồn).
class LeaderStationSyntheticStock {
  const LeaderStationSyntheticStock({
    required this.xangTon,
    required this.dauTon,
    required this.daysXang,
    required this.daysDau,
    required this.trendLabel,
  });

  final double xangTon;
  final double dauTon;
  final double daysXang;
  final double daysDau;
  final String trendLabel;
}

LeaderStationSyntheticStock leaderSyntheticStockForStation(StationMapItem s) {
  final h = s.stationId * 1103515245 + 12345;
  final r1 = (h % 9000) / 100.0 + 20;
  final r2 = (h >> 3 % 7000) / 100.0 + 15;
  final xangTon = s.priceRon95 != null ? r1 + 5 : r1 * 0.4;
  final dauTon = s.priceDiesel != null ? r2 + 4 : r2 * 0.35;
  final dailyX = 12.0 + (h % 7);
  final dailyD = 9.0 + (h % 5);
  final daysX = xangTon > 0 ? (xangTon / dailyX).clamp(0.5, 40.0) : 0.0;
  final daysD = dauTon > 0 ? (dauTon / dailyD).clamp(0.5, 40.0) : 0.0;
  final t = h % 3;
  final trendLabel = switch (t) {
    0 => 'Xu hướng ổn định theo mô hình minh họa.',
    1 => 'Biến động nhẹ so với kỳ trước (minh họa).',
    _ => 'Theo dõi sát nếu cầu tăng (minh họa).',
  };
  return LeaderStationSyntheticStock(
    xangTon: xangTon,
    dauTon: dauTon,
    daysXang: daysX,
    daysDau: daysD,
    trendLabel: trendLabel,
  );
}

bool leaderStationHasFuelPriceForFilter(StationMapItem s, LeaderMapFuelFilter fuel) {
  return switch (fuel) {
    LeaderMapFuelFilter.xang => s.priceRon95 != null,
    LeaderMapFuelFilter.dau => s.priceDiesel != null,
  };
}

double leaderSelectedDays(LeaderStationSyntheticStock v, LeaderMapFuelFilter fuel) {
  return fuel == LeaderMapFuelFilter.xang ? v.daysXang : v.daysDau;
}

double leaderSelectedTon(LeaderStationSyntheticStock v, LeaderMapFuelFilter fuel) {
  return fuel == LeaderMapFuelFilter.xang ? v.xangTon : v.dauTon;
}

bool leaderPassesCoverageBand(double? days, LeaderStockCoverageBand band) {
  switch (band) {
    case LeaderStockCoverageBand.all:
      return true;
    case LeaderStockCoverageBand.safe:
      return days != null && days > 10;
    case LeaderStockCoverageBand.warn:
      return days != null && days >= 5 && days <= 10;
    case LeaderStockCoverageBand.risk:
      return days != null && days < 5;
  }
}
