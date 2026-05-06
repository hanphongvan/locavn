/// Trạng thái cửa hàng bán lẻ — đồng bộ với `DM_DonVi.TrangThai bit`:
/// `null`/`1` ⇒ Hoạt động, `0` ⇒ Tạm dừng.
enum RetailStoreStatus {
  active(true, 'Hoạt động'),
  paused(false, 'Tạm dừng');

  const RetailStoreStatus(this.bitValue, this.label);
  final bool bitValue;
  final String label;
}

/// Bộ lọc dashboard Bán lẻ (Tỉnh / Trạng thái / Đơn vị quản lý).
class RetailFilter {
  const RetailFilter({
    this.provinceId,
    this.status,
    this.managingUnitId,
  });

  final int? provinceId;
  final RetailStoreStatus? status;
  final int? managingUnitId;

  RetailFilter copyWith({
    Object? provinceId = _sentinel,
    Object? status = _sentinel,
    Object? managingUnitId = _sentinel,
  }) =>
      RetailFilter(
        provinceId: identical(provinceId, _sentinel) ? this.provinceId : provinceId as int?,
        status: identical(status, _sentinel) ? this.status : status as RetailStoreStatus?,
        managingUnitId:
            identical(managingUnitId, _sentinel) ? this.managingUnitId : managingUnitId as int?,
      );

  bool get hasAny => provinceId != null || status != null || managingUnitId != null;

  static const Object _sentinel = Object();
}

/// KPI tổng quan (sau khi áp filter) — khớp `LeaderRetailKpiDto`.
class RetailKpiSummary {
  const RetailKpiSummary({
    required this.totalStores,
    required this.activeStores,
    required this.pausedStores,
  });

  final int totalStores;
  final int activeStores;
  final int pausedStores;

  /// Tỷ lệ hoạt động (0..1) — `active / total` (0 nếu total = 0).
  double get activeRate => totalStores == 0 ? 0 : activeStores / totalStores;

  factory RetailKpiSummary.fromJson(Map<String, dynamic> json) => RetailKpiSummary(
        totalStores: (json['totalStores'] as num?)?.toInt() ?? 0,
        activeStores: (json['activeStores'] as num?)?.toInt() ?? 0,
        pausedStores: (json['pausedStores'] as num?)?.toInt() ?? 0,
      );
}

/// 1 dòng ranking theo tỉnh — khớp `LeaderRetailProvinceRowDto`.
class RetailProvinceStat {
  const RetailProvinceStat({
    required this.provinceId,
    required this.provinceCode,
    required this.provinceName,
    required this.totalStores,
    required this.activeStores,
    required this.pausedStores,
    this.lastUpdatedAt,
  });

  final int? provinceId;
  final String? provinceCode;
  final String? provinceName;
  final int totalStores;
  final int activeStores;
  final int pausedStores;
  final DateTime? lastUpdatedAt;

  double get activeRate => totalStores == 0 ? 0 : activeStores / totalStores;

  String get displayName => provinceName ?? provinceCode ?? '(không xác định)';

  factory RetailProvinceStat.fromJson(Map<String, dynamic> json) => RetailProvinceStat(
        provinceId: (json['provinceId'] as num?)?.toInt(),
        provinceCode: json['provinceCode'] as String?,
        provinceName: json['provinceName'] as String?,
        totalStores: (json['totalStores'] as num?)?.toInt() ?? 0,
        activeStores: (json['activeStores'] as num?)?.toInt() ?? 0,
        pausedStores: (json['pausedStores'] as num?)?.toInt() ?? 0,
        lastUpdatedAt: _parseDate(json['lastUpdatedAt']),
      );
}

/// Mức độ cảnh báo — khớp enum BE (`Low=0, Medium=1, High=2`).
enum RetailWarningSeverity {
  low,
  medium,
  high;

  static RetailWarningSeverity fromIndex(int? i) =>
      switch (i) { 2 => RetailWarningSeverity.high, 1 => RetailWarningSeverity.medium, _ => RetailWarningSeverity.low };
}

/// Cảnh báo điều hành — khớp `LeaderRetailWarningDto`.
class RetailWarning {
  const RetailWarning({
    required this.code,
    required this.severity,
    required this.title,
    required this.detail,
    this.provinceId,
    this.provinceName,
    this.stationId,
    this.stationName,
  });

  final String code;
  final RetailWarningSeverity severity;
  final String title;
  final String detail;
  final int? provinceId;
  final String? provinceName;
  final int? stationId;
  final String? stationName;

  factory RetailWarning.fromJson(Map<String, dynamic> json) => RetailWarning(
        code: json['code'] as String? ?? '',
        severity: RetailWarningSeverity.fromIndex((json['severity'] as num?)?.toInt()),
        title: json['title'] as String? ?? '',
        detail: json['detail'] as String? ?? '',
        provinceId: (json['provinceId'] as num?)?.toInt(),
        provinceName: json['provinceName'] as String?,
        stationId: (json['stationId'] as num?)?.toInt(),
        stationName: json['stationName'] as String?,
      );
}

/// Toàn bộ payload dashboard.
class RetailDashboardData {
  const RetailDashboardData({
    required this.kpi,
    required this.provinces,
    required this.warnings,
  });

  final RetailKpiSummary kpi;
  final List<RetailProvinceStat> provinces;
  final List<RetailWarning> warnings;

  factory RetailDashboardData.fromJson(Map<String, dynamic> json) => RetailDashboardData(
        kpi: RetailKpiSummary.fromJson(json['kpi'] as Map<String, dynamic>? ?? const {}),
        provinces: ((json['provinces'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(RetailProvinceStat.fromJson)
            .toList(),
        warnings: ((json['warnings'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(RetailWarning.fromJson)
            .toList(),
      );
}

/// Item dropdown "Đơn vị quản lý".
class RetailManagingUnit {
  const RetailManagingUnit({
    required this.id,
    this.code,
    this.name,
    required this.storeCount,
  });

  final int id;
  final String? code;
  final String? name;
  final int storeCount;

  String get displayName => name ?? code ?? '#$id';

  factory RetailManagingUnit.fromJson(Map<String, dynamic> json) => RetailManagingUnit(
        id: (json['id'] as num?)?.toInt() ?? 0,
        code: json['code'] as String?,
        name: json['name'] as String?,
        storeCount: (json['storeCount'] as num?)?.toInt() ?? 0,
      );
}

/// Item dropdown "Tỉnh".
class RetailProvinceFilterOption {
  const RetailProvinceFilterOption({
    required this.id,
    this.code,
    this.name,
    required this.storeCount,
  });

  final int id;
  final String? code;
  final String? name;
  final int storeCount;

  String get displayName => name ?? code ?? '#$id';

  factory RetailProvinceFilterOption.fromJson(Map<String, dynamic> json) =>
      RetailProvinceFilterOption(
        id: (json['id'] as num?)?.toInt() ?? 0,
        code: json['code'] as String?,
        name: json['name'] as String?,
        storeCount: (json['storeCount'] as num?)?.toInt() ?? 0,
      );
}

DateTime? _parseDate(dynamic raw) {
  if (raw is String && raw.isNotEmpty) {
    return DateTime.tryParse(raw);
  }
  return null;
}
