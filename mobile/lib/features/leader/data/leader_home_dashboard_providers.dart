import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import 'leader_home_portal_api.dart';
import 'leader_home_portal_models.dart';
import 'leader_map_ui_state.dart';

/// Trả về 1 Future không bao giờ resolve — dùng khi user logout/đang đổi session.
/// Provider sẽ auto-dispose ngay sau đó (router redirect khỏi shell Leader),
/// không cần produce error/empty value gây flicker UI.
Future<T> _neverResolves<T>() => Completer<T>().future;

/// Tham số kỳ gửi lên SP (mặc định tháng hiện tại; đồng bộ dần với logic `periodLabel` Angular).
final leaderHomeDashboardRequestProvider = Provider.autoDispose<LeaderHomeDashboardRequest>((ref) {
  final s = ref.watch(portalSessionScopeProvider);
  final now = DateTime.now();
  return LeaderHomeDashboardRequest(
    userName: s?.userName,
    donViId: s?.donViId?.toString(),
    period: 'THANG',
    month: now.month,
    year: now.year,
  );
});

final leaderHomeInventoryProvider =
    FutureProvider.autoDispose<LeaderHomeInventorySummaryResponse>((ref) async {
  if (ref.watch(portalSessionScopeProvider) == null) {
    return _neverResolves();
  }
  final api = ref.watch(leaderHomePortalApiProvider);
  final body = ref.watch(leaderHomeDashboardRequestProvider);
  return api.postInventorySummary(body);
});

final leaderHomeNationalMovementProvider =
    FutureProvider.autoDispose<LeaderHomeNationalStockMovementResponse>((ref) async {
  if (ref.watch(portalSessionScopeProvider) == null) {
    return _neverResolves();
  }
  final api = ref.watch(leaderHomePortalApiProvider);
  final body = ref.watch(leaderHomeDashboardRequestProvider);
  return api.postNationalStockMovement(body);
});

final leaderHomePriceSummaryProvider =
    FutureProvider.autoDispose<LeaderHomePriceSummaryResponse>((ref) async {
  if (ref.watch(portalSessionScopeProvider) == null) {
    return _neverResolves();
  }
  final api = ref.watch(leaderHomePortalApiProvider);
  final body = ref.watch(leaderHomeDashboardRequestProvider);
  return api.postPriceSummary(body);
});

final leaderDistributorMapProvider =
    FutureProvider.autoDispose.family<LeaderHomeDistributorMapResponse, LeaderMapFuelFilter>((ref, fuel) async {
  final s = ref.watch(portalSessionScopeProvider);
  if (s == null) {
    return _neverResolves();
  }
  final api = ref.watch(leaderHomePortalApiProvider);
  final ma = fuel == LeaderMapFuelFilter.xang ? 'xang' : 'dau';
  return api.postDistributorMap(LeaderHomeDistributorMapRequest(userName: s.userName, ma: ma));
});
