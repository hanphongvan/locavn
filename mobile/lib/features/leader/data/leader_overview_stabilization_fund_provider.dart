import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'stabilization_fund_models.dart';
import 'stabilization_fund_service.dart';

/// Tổng quan Dashboard Lãnh đạo — tồn quỹ BC08 (cùng API tab Quỹ bình ổn, không gửi tháng/năm).
final leaderOverviewStabilizationFundSummaryProvider =
    FutureProvider.autoDispose<StabilizationFundSummaryDto>((ref) async {
  return ref.read(stabilizationFundServiceProvider).getSummary();
});
