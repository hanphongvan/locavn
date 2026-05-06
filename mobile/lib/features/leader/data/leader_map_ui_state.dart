import 'package:flutter/foundation.dart';

/// Chỉ Xăng / Dầu.
enum LeaderMapFuelFilter {
  xang,
  dau,
}

/// Ngưỡng số ngày dự trữ (theo nhiên liệu đang chọn).
enum LeaderStockCoverageBand {
  all,
  safe,
  warn,
  risk,
}

@immutable
class LeaderMapUiState {
  const LeaderMapUiState({
    this.fuel = LeaderMapFuelFilter.xang,
    this.coverage = LeaderStockCoverageBand.all,
    this.showRetailStores = false,
    this.showWholesale = true,
    this.selectedServiceCodes = const [],
  });

  final LeaderMapFuelFilter fuel;
  final LeaderStockCoverageBand coverage;
  /// Lớp 2 — tắt mặc định (nhiều điểm, tải theo khung nhìn).
  final bool showRetailStores;
  /// Lớp 1 — đầu mối, bật mặc định.
  final bool showWholesale;

  /// Mã dịch vụ (`activeServiceCodes`) — rỗng = không lọc; logic giống bản đồ Citizen.
  final List<String> selectedServiceCodes;

  LeaderMapUiState copyWith({
    LeaderMapFuelFilter? fuel,
    LeaderStockCoverageBand? coverage,
    bool? showRetailStores,
    bool? showWholesale,
    List<String>? selectedServiceCodes,
  }) {
    return LeaderMapUiState(
      fuel: fuel ?? this.fuel,
      coverage: coverage ?? this.coverage,
      showRetailStores: showRetailStores ?? this.showRetailStores,
      showWholesale: showWholesale ?? this.showWholesale,
      selectedServiceCodes: selectedServiceCodes ?? this.selectedServiceCodes,
    );
  }
}
