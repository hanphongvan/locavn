import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/fuel_api.dart';

/// One month bucket for the consumption bar chart.
@immutable
class MonthlyLiterPoint {
  const MonthlyLiterPoint({
    required this.year,
    required this.month,
    required this.liters,
  });

  final int year;
  final int month;
  final double liters;
}

/// Query key for [fuelMonthlyLitersChartProvider] (vehicle + dashboard month anchor).
@immutable
class FuelMonthlyChartArgs {
  const FuelMonthlyChartArgs({
    required this.vehicleId,
    required this.anchorYear,
    required this.anchorMonth,
  });

  final int vehicleId;
  final int anchorYear;
  final int anchorMonth;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FuelMonthlyChartArgs &&
          vehicleId == other.vehicleId &&
          anchorYear == other.anchorYear &&
          anchorMonth == other.anchorMonth;

  @override
  int get hashCode => Object.hash(vehicleId, anchorYear, anchorMonth);
}

/// Last 6 calendar months ending at [anchorYear]/[anchorMonth] — liters from monthly summary API.
final fuelMonthlyLitersChartProvider =
    FutureProvider.autoDispose.family<List<MonthlyLiterPoint>, FuelMonthlyChartArgs>((ref, args) async {
  final api = ref.watch(fuelApiProvider);
  final end = DateTime(args.anchorYear, args.anchorMonth);
  final months = List.generate(6, (i) => DateTime(end.year, end.month - (5 - i)));

  Future<MonthlyLiterPoint> one(DateTime d) async {
    try {
      final s = await api.getFuelMonthlySummary(args.vehicleId, d.month, d.year);
      return MonthlyLiterPoint(year: d.year, month: d.month, liters: s.totalLiters);
    } catch (_) {
      return MonthlyLiterPoint(year: d.year, month: d.month, liters: 0);
    }
  }

  return Future.wait(months.map(one));
});
