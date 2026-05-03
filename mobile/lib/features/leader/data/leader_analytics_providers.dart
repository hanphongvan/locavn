import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'leader_analytics_dtos.dart';
import 'leader_analytics_service.dart';
import 'leader_map_ui_state.dart';

@immutable
class LeaderAnalyticsQuery {
  const LeaderAnalyticsQuery({
    required this.window,
    required this.barFuel,
  });

  final LeaderAnalyticsWindow window;
  final LeaderMapFuelFilter barFuel;

  String get fuelApi => barFuel == LeaderMapFuelFilter.xang ? 'xang' : 'dau';

  @override
  bool operator ==(Object other) =>
      other is LeaderAnalyticsQuery && other.window == window && other.barFuel == barFuel;

  @override
  int get hashCode => Object.hash(window, barFuel);
}

/// Gói 5 API Phân tích (song song).
final leaderAnalyticsBundleProvider =
    FutureProvider.autoDispose.family<LeaderAnalyticsBundle, LeaderAnalyticsQuery>((ref, q) async {
  final api = ref.watch(leaderAnalyticsServiceProvider);
  final w = q.window.apiValue;
  final f = q.fuelApi;
  final results = await Future.wait([
    api.getInventoryTrend(window: w),
    api.getImportExportTrend(window: w, fuel: f),
    api.getPriceTrend(window: w),
    api.getPeriodComparison(window: w),
    api.getMarketInsight(window: w, fuel: f),
  ]);
  return LeaderAnalyticsBundle(
    inventory: results[0] as LeaderAnalyticsInventoryTrendDto,
    importExport: results[1] as LeaderAnalyticsImportExportTrendDto,
    price: results[2] as LeaderAnalyticsPriceTrendDto,
    period: results[3] as LeaderAnalyticsPeriodComparisonDto,
    insight: results[4] as LeaderAnalyticsMarketInsightDto,
  );
});

class LeaderAnalyticsBundle {
  const LeaderAnalyticsBundle({
    required this.inventory,
    required this.importExport,
    required this.price,
    required this.period,
    required this.insight,
  });

  final LeaderAnalyticsInventoryTrendDto inventory;
  final LeaderAnalyticsImportExportTrendDto importExport;
  final LeaderAnalyticsPriceTrendDto price;
  final LeaderAnalyticsPeriodComparisonDto period;
  final LeaderAnalyticsMarketInsightDto insight;
}
