import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Trạng thái 1 cửa hàng bán lẻ — dùng cho filter + thống kê.
enum RetailStoreStatus {
  active('active', 'Đang hoạt động'),
  paused('paused', 'Tạm dừng'),
  outOfStock('outOfStock', 'Gián đoạn / hết hàng');

  const RetailStoreStatus(this.id, this.label);
  final String id;
  final String label;
}

/// Loại nhiên liệu lọc trên dashboard bán lẻ.
enum RetailFuelType {
  all('all', 'Tất cả'),
  gasoline('gasoline', 'Xăng'),
  diesel('diesel', 'Dầu DO');

  const RetailFuelType(this.id, this.label);
  final String id;
  final String label;
}

/// Bộ lọc dashboard Bán lẻ (Vùng / Tỉnh / Loại NL / Trạng thái).
class RetailFilter {
  const RetailFilter({
    this.region,
    this.province,
    this.fuelType = RetailFuelType.all,
    this.status,
  });

  final String? region;
  final String? province;
  final RetailFuelType fuelType;
  final RetailStoreStatus? status;

  RetailFilter copyWith({
    Object? region = _sentinel,
    Object? province = _sentinel,
    RetailFuelType? fuelType,
    Object? status = _sentinel,
  }) =>
      RetailFilter(
        region: identical(region, _sentinel) ? this.region : region as String?,
        province:
            identical(province, _sentinel) ? this.province : province as String?,
        fuelType: fuelType ?? this.fuelType,
        status: identical(status, _sentinel)
            ? this.status
            : status as RetailStoreStatus?,
      );

  static const Object _sentinel = Object();
}

/// KPI tổng quan toàn quốc (sau khi áp filter).
class RetailKpiSummary {
  const RetailKpiSummary({
    required this.totalStores,
    required this.activeStores,
    required this.pausedStores,
    required this.outOfStockStores,
  });

  final int totalStores;
  final int activeStores;
  final int pausedStores;
  final int outOfStockStores;

  /// Tỷ lệ hoạt động (0..1) — `active / total` (0 nếu total = 0).
  double get activeRate => totalStores == 0 ? 0 : activeStores / totalStores;
}

/// Thống kê 1 tỉnh — dùng cho ranking + drill-down.
class RetailProvinceStat {
  const RetailProvinceStat({
    required this.province,
    required this.region,
    required this.totalStores,
    required this.activeStores,
    required this.pausedStores,
    required this.outOfStockStores,
  });

  final String province;
  final String region;
  final int totalStores;
  final int activeStores;
  final int pausedStores;
  final int outOfStockStores;

  double get activeRate => totalStores == 0 ? 0 : activeStores / totalStores;
}

/// Mức độ cảnh báo cho `RetailWarning`.
enum RetailWarningSeverity { high, medium, low }

/// Cảnh báo điều hành (tỉnh nhiều CH tạm dừng / tỷ lệ thấp / nguy cơ thiếu cung).
class RetailWarning {
  const RetailWarning({
    required this.province,
    required this.title,
    required this.detail,
    required this.severity,
  });

  final String province;
  final String title;
  final String detail;
  final RetailWarningSeverity severity;
}

/// Toàn bộ dữ liệu trang Bán lẻ trong 1 lần fetch.
class RetailDashboardData {
  const RetailDashboardData({
    required this.kpi,
    required this.provinces,
    required this.warnings,
    required this.regions,
  });

  final RetailKpiSummary kpi;
  final List<RetailProvinceStat> provinces;
  final List<RetailWarning> warnings;

  /// Danh sách vùng (cho dropdown filter) — derive từ data.
  final List<String> regions;
}

/// Mock service — trả `Future` kèm delay nhỏ; thay bằng API thật khi sẵn sàng.
class LeaderRetailMockService {
  const LeaderRetailMockService();

  Future<RetailDashboardData> fetchDashboard(RetailFilter filter) async {
    // Giả lập latency (đủ để hiện loading state).
    await Future<void>.delayed(const Duration(milliseconds: 350));

    final all = _seedProvinces();
    final filtered = all.where((p) {
      if (filter.region != null && p.region != filter.region) return false;
      if (filter.province != null && p.province != filter.province) {
        return false;
      }
      return true;
    }).toList();

    final scaled = filter.status == null
        ? filtered
        : filtered
            .map((p) => _scaleByStatus(p, filter.status!))
            .toList(growable: false);

    final total = scaled.fold<int>(0, (s, p) => s + p.totalStores);
    final active = scaled.fold<int>(0, (s, p) => s + p.activeStores);
    final paused = scaled.fold<int>(0, (s, p) => s + p.pausedStores);
    final oos = scaled.fold<int>(0, (s, p) => s + p.outOfStockStores);

    return RetailDashboardData(
      kpi: RetailKpiSummary(
        totalStores: total,
        activeStores: active,
        pausedStores: paused,
        outOfStockStores: oos,
      ),
      provinces: scaled..sort((a, b) => b.totalStores.compareTo(a.totalStores)),
      warnings: _buildWarnings(scaled),
      regions: all.map((p) => p.region).toSet().toList()..sort(),
    );
  }

  RetailProvinceStat _scaleByStatus(
    RetailProvinceStat p,
    RetailStoreStatus status,
  ) {
    return switch (status) {
      RetailStoreStatus.active => RetailProvinceStat(
          province: p.province,
          region: p.region,
          totalStores: p.activeStores,
          activeStores: p.activeStores,
          pausedStores: 0,
          outOfStockStores: 0,
        ),
      RetailStoreStatus.paused => RetailProvinceStat(
          province: p.province,
          region: p.region,
          totalStores: p.pausedStores,
          activeStores: 0,
          pausedStores: p.pausedStores,
          outOfStockStores: 0,
        ),
      RetailStoreStatus.outOfStock => RetailProvinceStat(
          province: p.province,
          region: p.region,
          totalStores: p.outOfStockStores,
          activeStores: 0,
          pausedStores: 0,
          outOfStockStores: p.outOfStockStores,
        ),
    };
  }

  List<RetailWarning> _buildWarnings(List<RetailProvinceStat> stats) {
    final out = <RetailWarning>[];
    for (final p in stats) {
      if (p.totalStores < 5) continue;
      if (p.pausedStores >= 8) {
        out.add(RetailWarning(
          province: p.province,
          title: '${p.province}: nhiều cửa hàng tạm dừng',
          detail:
              '${p.pausedStores}/${p.totalStores} CH đang tạm dừng. Cần kiểm tra lý do tạm dừng (giấy phép / nguồn cung).',
          severity: RetailWarningSeverity.high,
        ));
      }
      if (p.activeRate < 0.7 && p.totalStores >= 10) {
        out.add(RetailWarning(
          province: p.province,
          title: '${p.province}: tỷ lệ hoạt động thấp',
          detail:
              'Tỷ lệ hoạt động ${(p.activeRate * 100).toStringAsFixed(1)}%, dưới ngưỡng 70%.',
          severity: RetailWarningSeverity.medium,
        ));
      }
      if (p.outOfStockStores >= 3) {
        out.add(RetailWarning(
          province: p.province,
          title: '${p.province}: nguy cơ thiếu nguồn cung',
          detail:
              '${p.outOfStockStores} CH gián đoạn / hết hàng. Đề xuất rà soát điều phối.',
          severity: RetailWarningSeverity.high,
        ));
      }
    }
    out.sort((a, b) => a.severity.index.compareTo(b.severity.index));
    return out;
  }

  List<RetailProvinceStat> _seedProvinces() {
    return const [
      RetailProvinceStat(
        province: 'Hà Nội',
        region: 'Bắc Bộ',
        totalStores: 184,
        activeStores: 168,
        pausedStores: 12,
        outOfStockStores: 4,
      ),
      RetailProvinceStat(
        province: 'TP.HCM',
        region: 'Nam Bộ',
        totalStores: 226,
        activeStores: 210,
        pausedStores: 11,
        outOfStockStores: 5,
      ),
      RetailProvinceStat(
        province: 'Hải Phòng',
        region: 'Bắc Bộ',
        totalStores: 72,
        activeStores: 58,
        pausedStores: 11,
        outOfStockStores: 3,
      ),
      RetailProvinceStat(
        province: 'Đà Nẵng',
        region: 'Trung Bộ',
        totalStores: 64,
        activeStores: 60,
        pausedStores: 3,
        outOfStockStores: 1,
      ),
      RetailProvinceStat(
        province: 'Quảng Ninh',
        region: 'Bắc Bộ',
        totalStores: 58,
        activeStores: 49,
        pausedStores: 8,
        outOfStockStores: 1,
      ),
      RetailProvinceStat(
        province: 'Thanh Hoá',
        region: 'Trung Bộ',
        totalStores: 96,
        activeStores: 80,
        pausedStores: 12,
        outOfStockStores: 4,
      ),
      RetailProvinceStat(
        province: 'Nghệ An',
        region: 'Trung Bộ',
        totalStores: 82,
        activeStores: 70,
        pausedStores: 9,
        outOfStockStores: 3,
      ),
      RetailProvinceStat(
        province: 'Cần Thơ',
        region: 'Nam Bộ',
        totalStores: 54,
        activeStores: 50,
        pausedStores: 3,
        outOfStockStores: 1,
      ),
      RetailProvinceStat(
        province: 'Bình Dương',
        region: 'Nam Bộ',
        totalStores: 88,
        activeStores: 80,
        pausedStores: 6,
        outOfStockStores: 2,
      ),
      RetailProvinceStat(
        province: 'Đồng Nai',
        region: 'Nam Bộ',
        totalStores: 92,
        activeStores: 70,
        pausedStores: 16,
        outOfStockStores: 6,
      ),
      RetailProvinceStat(
        province: 'Lâm Đồng',
        region: 'Trung Bộ',
        totalStores: 46,
        activeStores: 40,
        pausedStores: 4,
        outOfStockStores: 2,
      ),
      RetailProvinceStat(
        province: 'Khánh Hoà',
        region: 'Trung Bộ',
        totalStores: 52,
        activeStores: 47,
        pausedStores: 4,
        outOfStockStores: 1,
      ),
    ];
  }
}

/// Provider service — instance tĩnh để dùng chung.
final leaderRetailServiceProvider = Provider<LeaderRetailMockService>(
  (ref) => const LeaderRetailMockService(),
);

/// Bộ lọc hiện tại (state) — UI mutate qua `notifier`.
final leaderRetailFilterProvider =
    StateProvider<RetailFilter>((ref) => const RetailFilter());

/// Dữ liệu dashboard theo filter — auto-refetch khi filter đổi.
final leaderRetailDashboardProvider =
    FutureProvider<RetailDashboardData>((ref) {
  final filter = ref.watch(leaderRetailFilterProvider);
  final service = ref.watch(leaderRetailServiceProvider);
  return service.fetchDashboard(filter);
});
