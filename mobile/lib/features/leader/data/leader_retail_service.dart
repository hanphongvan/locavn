import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'leader_retail_api.dart';
import 'leader_retail_models.dart';

/// Bật mock fallback trong dev khi BE chưa sẵn sàng. **Phải `false` ở release**.
/// Logic: chỉ enable mock khi `kDebugMode == true` AND cờ này = `true`.
const bool _kEnableRetailMockInDebug = false;

/// Hợp đồng dữ liệu cho Leader Retail — chia nhánh API/Mock qua provider.
abstract class LeaderRetailService {
  Future<RetailDashboardData> fetchDashboard(RetailFilter filter);
  Future<List<RetailManagingUnit>> fetchManagingUnits();
  Future<List<RetailProvinceFilterOption>> fetchProvinces();
}

/// Impl gọi API thật — production / staging.
class LeaderRetailApiService implements LeaderRetailService {
  LeaderRetailApiService(this._api);
  final LeaderRetailApi _api;

  @override
  Future<RetailDashboardData> fetchDashboard(RetailFilter filter) =>
      _api.getDashboard(filter);

  @override
  Future<List<RetailManagingUnit>> fetchManagingUnits() => _api.getManagingUnits();

  @override
  Future<List<RetailProvinceFilterOption>> fetchProvinces() => _api.getProvinces();
}

/// Impl mock — **chỉ dùng trong dev** khi BE chưa sẵn sàng. Không silent fallback ở release.
class LeaderRetailMockService implements LeaderRetailService {
  const LeaderRetailMockService();

  static const _delay = Duration(milliseconds: 350);

  @override
  Future<RetailDashboardData> fetchDashboard(RetailFilter filter) async {
    await Future<void>.delayed(_delay);
    final all = _seedProvinces();
    final filtered = all.where((p) {
      if (filter.provinceId != null && p.provinceId != filter.provinceId) return false;
      return true;
    }).toList();
    final total = filtered.fold<int>(0, (s, p) => s + p.totalStores);
    final active = filtered.fold<int>(0, (s, p) => s + p.activeStores);
    final paused = filtered.fold<int>(0, (s, p) => s + p.pausedStores);
    return RetailDashboardData(
      kpi: RetailKpiSummary(
        totalStores: total,
        activeStores: active,
        pausedStores: paused,
      ),
      provinces: filtered..sort((a, b) => b.totalStores.compareTo(a.totalStores)),
      warnings: const [],
    );
  }

  @override
  Future<List<RetailManagingUnit>> fetchManagingUnits() async {
    await Future<void>.delayed(_delay);
    return const [
      RetailManagingUnit(id: 1001, code: 'TCT-XD-MB', name: 'TCT Xăng dầu Miền Bắc', storeCount: 312),
      RetailManagingUnit(id: 1002, code: 'TCT-XD-MT', name: 'TCT Xăng dầu Miền Trung', storeCount: 246),
      RetailManagingUnit(id: 1003, code: 'TCT-XD-MN', name: 'TCT Xăng dầu Miền Nam', storeCount: 408),
    ];
  }

  @override
  Future<List<RetailProvinceFilterOption>> fetchProvinces() async {
    await Future<void>.delayed(_delay);
    return _seedProvinces()
        .map((p) => RetailProvinceFilterOption(
              id: p.provinceId ?? 0,
              code: p.provinceCode,
              name: p.provinceName,
              storeCount: p.totalStores,
            ))
        .toList();
  }

  List<RetailProvinceStat> _seedProvinces() {
    return const [
      RetailProvinceStat(
        provinceId: 1, provinceCode: 'HN', provinceName: 'Hà Nội',
        totalStores: 184, activeStores: 168, pausedStores: 16,
      ),
      RetailProvinceStat(
        provinceId: 79, provinceCode: 'HCM', provinceName: 'TP.HCM',
        totalStores: 226, activeStores: 210, pausedStores: 16,
      ),
      RetailProvinceStat(
        provinceId: 31, provinceCode: 'HP', provinceName: 'Hải Phòng',
        totalStores: 72, activeStores: 58, pausedStores: 14,
      ),
      RetailProvinceStat(
        provinceId: 48, provinceCode: 'DN', provinceName: 'Đà Nẵng',
        totalStores: 64, activeStores: 60, pausedStores: 4,
      ),
    ];
  }
}

final leaderRetailServiceProvider = Provider<LeaderRetailService>((ref) {
  if (kDebugMode && _kEnableRetailMockInDebug) {
    debugPrint('[leader-retail] service=Mock (kDebugMode + flag)');
    return const LeaderRetailMockService();
  }
  debugPrint('[leader-retail] service=Api (real backend)');
  return LeaderRetailApiService(ref.watch(leaderRetailApiProvider));
});

final leaderRetailFilterProvider =
    StateProvider<RetailFilter>((ref) => const RetailFilter());

final leaderRetailDashboardProvider = FutureProvider<RetailDashboardData>((ref) {
  final filter = ref.watch(leaderRetailFilterProvider);
  final service = ref.watch(leaderRetailServiceProvider);
  debugPrint(
    '[leader-retail] dashboardProvider FIRE '
    '(provinceId=${filter.provinceId} status=${filter.status?.name} mgmt=${filter.managingUnitId})',
  );
  return service.fetchDashboard(filter).then((d) {
    debugPrint(
      '[leader-retail] dashboardProvider OK '
      'kpi(total=${d.kpi.totalStores}, active=${d.kpi.activeStores}, paused=${d.kpi.pausedStores}) '
      'provinces=${d.provinces.length} warnings=${d.warnings.length}',
    );
    return d;
  }).catchError((Object err, StackTrace st) {
    debugPrint('[leader-retail] dashboardProvider ERROR: $err');
    debugPrintStack(stackTrace: st, label: '[leader-retail] dashboard stack');
    throw err;
  });
});

final leaderRetailManagingUnitsProvider =
    FutureProvider<List<RetailManagingUnit>>((ref) {
  final service = ref.watch(leaderRetailServiceProvider);
  debugPrint('[leader-retail] managingUnitsProvider FIRE');
  return service.fetchManagingUnits().then((v) {
    debugPrint('[leader-retail] managingUnitsProvider OK count=${v.length}');
    return v;
  }).catchError((Object err, StackTrace st) {
    debugPrint('[leader-retail] managingUnitsProvider ERROR: $err');
    debugPrintStack(stackTrace: st, label: '[leader-retail] managingUnits stack');
    throw err;
  });
});

final leaderRetailProvincesProvider =
    FutureProvider<List<RetailProvinceFilterOption>>((ref) {
  final service = ref.watch(leaderRetailServiceProvider);
  debugPrint('[leader-retail] provincesProvider FIRE');
  return service.fetchProvinces().then((v) {
    debugPrint('[leader-retail] provincesProvider OK count=${v.length}');
    return v;
  }).catchError((Object err, StackTrace st) {
    debugPrint('[leader-retail] provincesProvider ERROR: $err');
    debugPrintStack(stackTrace: st, label: '[leader-retail] provinces stack');
    throw err;
  });
});
