import 'package:flutter/foundation.dart';

import '../../reports/data/models/reports_overview_dto.dart';
import '../../reports/data/models/reports_system_inventory_line_dto.dart';
import '../../reports/data/models/station_count_by_province.dart';
import '../map/leader_demo_distributors.dart';
import 'leader_fuel_filter.dart';
import 'leader_overview_metrics.dart';

/// Mức độ cảnh báo điều hành.
enum LeaderAlertSeverity {
  /// Dưới 5 ngày dự trữ (hoặc tương đương).
  critical,

  /// 5–10 ngày.
  warning,

  /// Biến động / theo dõi.
  watch,
}

enum LeaderAlertFuel {
  xang,
  dau,
}

enum LeaderAlertKind {
  distributor,
  provinceStores,
  productStock,
  systemNote,
  marketTrend,
}

@immutable
class LeaderOperationalAlert {
  const LeaderOperationalAlert({
    required this.id,
    required this.title,
    required this.fuel,
    required this.location,
    required this.at,
    required this.severity,
    required this.detailBody,
    required this.kind,
  });

  final String id;
  final String title;
  final LeaderAlertFuel fuel;
  final String location;
  final DateTime at;
  final LeaderAlertSeverity severity;
  final String detailBody;
  final LeaderAlertKind kind;

  static String fuelLabelVi(LeaderAlertFuel f) => switch (f) {
        LeaderAlertFuel.xang => 'Xăng',
        LeaderAlertFuel.dau => 'Dầu',
      };

  static String severityLabelVi(LeaderAlertSeverity s) => switch (s) {
        LeaderAlertSeverity.critical => 'Nghiêm trọng',
        LeaderAlertSeverity.warning => 'Cảnh báo',
        LeaderAlertSeverity.watch => 'Theo dõi',
      };
}

LeaderAlertSeverity _severityFromDays(double days) {
  if (days < 5) return LeaderAlertSeverity.critical;
  if (days <= 10) return LeaderAlertSeverity.warning;
  return LeaderAlertSeverity.watch;
}

double _daysForInventoryLine(ReportsSystemInventoryLineDto l, int openStations, bool isGasoline) {
  return leaderDaysOfCover(
    totalStock: l.currentQuantity,
    openStations: openStations,
    isGasoline: isGasoline,
  );
}

void _addProductLineAlerts(
  List<LeaderOperationalAlert> out,
  List<ReportsSystemInventoryLineDto> lines,
  LeaderAlertFuel fuel,
  int openStations,
  bool isGasoline,
  DateTime now,
) {
  final sorted = [...lines];
  sorted.sort(
    (a, b) => _daysForInventoryLine(a, openStations, isGasoline).compareTo(
          _daysForInventoryLine(b, openStations, isGasoline),
        ),
  );
  var added = 0;
  const maxLines = 8;
  for (final l in sorted) {
    if (added >= maxLines) break;
    final days = _daysForInventoryLine(l, openStations, isGasoline);
    if (days > 10) continue;
    final sev = _severityFromDays(days);
    final name = l.productName.trim().isEmpty ? l.productCode : l.productName;
    out.add(
      LeaderOperationalAlert(
        id: 'stk_${fuel.name}_${l.productId}',
        title: '$name: khoảng ${days.toStringAsFixed(1)} ngày dự trữ',
        fuel: fuel,
        location: 'Tổng hợp báo cáo',
        at: now,
        severity: sev,
        detailBody:
            'Mức tồn hiện tại ${l.currentQuantity.toStringAsFixed(1)} ${l.unitTen ?? l.unitMa ?? ''}. '
            'Ước tính minh họa theo quy mô trạm mở; API chi tiết sẽ thay thế.',
        kind: LeaderAlertKind.productStock,
      ),
    );
    added++;
  }
}

void _addDistributorAlerts(List<LeaderOperationalAlert> out, DateTime now) {
  for (final d in kLeaderDemoDistributors) {
    if (d.daysXang < 5) {
      out.add(
        LeaderOperationalAlert(
          id: 'dm_${d.id}_xang',
          title: '${d.name.split('(').first.trim()}: Xăng còn dưới 5 ngày',
          fuel: LeaderAlertFuel.xang,
          location: d.address,
          at: now,
          severity: LeaderAlertSeverity.critical,
          detailBody:
              'Dự trữ xăng khoảng ${d.daysXang.toStringAsFixed(1)} ngày. ${d.trendLabel} '
              '(dữ liệu đầu mối minh họa).',
          kind: LeaderAlertKind.distributor,
        ),
      );
    } else if (d.daysXang <= 10) {
      out.add(
        LeaderOperationalAlert(
          id: 'dm_${d.id}_xang_w',
          title: '${d.name.split('(').first.trim()}: Xăng trong vùng cảnh báo (5–10 ngày)',
          fuel: LeaderAlertFuel.xang,
          location: d.address,
          at: now,
          severity: LeaderAlertSeverity.warning,
          detailBody: d.trendLabel,
          kind: LeaderAlertKind.distributor,
        ),
      );
    }
    if (d.daysDau < 5) {
      final title = d.id == 'dm-ct'
          ? 'Petrolimex miền Trung: Dầu còn dưới 5 ngày'
          : '${d.name.split('(').first.trim()}: Dầu còn dưới 5 ngày';
      out.add(
        LeaderOperationalAlert(
          id: 'dm_${d.id}_dau',
          title: title,
          fuel: LeaderAlertFuel.dau,
          location: d.address,
          at: now,
          severity: LeaderAlertSeverity.critical,
          detailBody:
              'Dự trữ dầu khoảng ${d.daysDau.toStringAsFixed(1)} ngày. ${d.trendLabel} '
              '(dữ liệu đầu mối minh họa).',
          kind: LeaderAlertKind.distributor,
        ),
      );
    } else if (d.daysDau <= 10) {
      out.add(
        LeaderOperationalAlert(
          id: 'dm_${d.id}_dau_w',
          title: '${d.name.split('(').first.trim()}: Dầu trong vùng cảnh báo (5–10 ngày)',
          fuel: LeaderAlertFuel.dau,
          location: d.address,
          at: now,
          severity: LeaderAlertSeverity.warning,
          detailBody: d.trendLabel,
          kind: LeaderAlertKind.distributor,
        ),
      );
    }
  }
}

void _addProvinceStoreAlerts(List<LeaderOperationalAlert> out, List<StationCountByProvince> byProv, DateTime now) {
  StationCountByProvince? ngheAn;
  StationCountByProvince? top;
  for (final p in byProv) {
    final n = (p.provinceName ?? '').toLowerCase();
    if (n.contains('nghệ an') || n.contains('nghe an')) {
      ngheAn = p;
      break;
    }
    if (top == null || p.stationCount > top.stationCount) {
      top = p;
    }
  }
  final pick = ngheAn ?? top;
  if (pick == null) return;
  final label = pick.provinceName ?? pick.provinceCode ?? 'Địa phương';
  final c = pick.stationCount;
  if (c < 6) return;
  final isNgheAn = ngheAn != null;
  final title = isNgheAn && c >= 12
      ? '12 cửa hàng tại Nghệ An thiếu Xăng'
      : '$c cửa hàng tại $label thiếu Xăng';
  final sev = c >= 12 ? LeaderAlertSeverity.warning : LeaderAlertSeverity.watch;
  out.add(
    LeaderOperationalAlert(
      id: 'prov_${pick.provinceCode ?? label}',
      title: title,
      fuel: LeaderAlertFuel.xang,
      location: label,
      at: now,
      severity: sev,
      detailBody:
          'Cảnh báo minh họa theo mật độ trạm trên báo cáo tỉnh; cần API phân rã tồn theo tỉnh để xác thực.',
      kind: LeaderAlertKind.provinceStores,
    ),
  );
}

void _addSharpDecreaseWatch(List<LeaderOperationalAlert> out, ReportsOverviewDto overview, DateTime now) {
  final seed = overview.totalStations ^ overview.openStations;
  if (seed % 3 != 0) return;
  out.add(
    LeaderOperationalAlert(
      id: 'trend_sharp_${overview.totalStations}',
      title: 'Biến động tồn xăng toàn quốc giảm nhanh (theo dõi)',
      fuel: LeaderAlertFuel.xang,
      location: 'Toàn quốc',
      at: now,
      severity: LeaderAlertSeverity.watch,
      detailBody:
          'Mô hình minh họa phát hiện xu hướng giảm tương đối giữa các kỳ báo cáo; khi có chuỗi lịch sử thực sẽ thay thế quy tắc này.',
      kind: LeaderAlertKind.marketTrend,
    ),
  );
}

List<LeaderOperationalAlert> buildLeaderOperationalAlerts(ReportsOverviewDto overview) {
  final out = <LeaderOperationalAlert>[];
  final now = DateTime.now();
  final open = overview.openStations;
  final inv = LeaderFuelFilter.withoutKhi(overview.systemInventory);
  final xangLines = LeaderFuelFilter.xangLines(inv);
  final dauLines = LeaderFuelFilter.dauLines(inv);

  for (final n in overview.notes ?? const <String>[]) {
    if (n.trim().isEmpty) continue;
    out.add(
      LeaderOperationalAlert(
        id: 'note_${n.hashCode}',
        title: 'Thông báo hệ thống',
        fuel: LeaderAlertFuel.xang,
        location: 'Toàn quốc',
        at: now,
        severity: LeaderAlertSeverity.watch,
        detailBody: n,
        kind: LeaderAlertKind.systemNote,
      ),
    );
  }

  _addDistributorAlerts(out, now);
  _addProvinceStoreAlerts(out, overview.stationsByProvince, now);
  _addSharpDecreaseWatch(out, overview, now);
  _addProductLineAlerts(out, xangLines, LeaderAlertFuel.xang, open, true, now);
  _addProductLineAlerts(out, dauLines, LeaderAlertFuel.dau, open, false, now);

  out.sort((a, b) {
    final oa = switch (a.severity) {
      LeaderAlertSeverity.critical => 0,
      LeaderAlertSeverity.warning => 1,
      LeaderAlertSeverity.watch => 2,
    };
    final ob = switch (b.severity) {
      LeaderAlertSeverity.critical => 0,
      LeaderAlertSeverity.warning => 1,
      LeaderAlertSeverity.watch => 2,
    };
    final c = oa.compareTo(ob);
    if (c != 0) return c;
    return b.at.compareTo(a.at);
  });

  return out;
}

/// Số đầu mối (demo) có ít nhất một nhánh Xăng/Dầu dưới 5 ngày.
int countDemoDistributorHubsUnder5Days() {
  return kLeaderDemoDistributors.where((d) => d.daysXang < 5 || d.daysDau < 5).length;
}

int countStoresAtRisk(List<LeaderOperationalAlert> items) {
  return items
      .where(
        (e) =>
            (e.kind == LeaderAlertKind.provinceStores || e.kind == LeaderAlertKind.productStock) &&
            (e.severity == LeaderAlertSeverity.critical || e.severity == LeaderAlertSeverity.warning),
      )
      .length;
}
