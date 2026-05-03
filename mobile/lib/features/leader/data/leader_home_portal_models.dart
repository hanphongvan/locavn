import '../../../core/network/json_utils.dart';

/// Thân POST tương đương Angular `InventorySummaryRequestDto`.
class LeaderHomeDashboardRequest {
  const LeaderHomeDashboardRequest({
    this.userName,
    this.donViId,
    this.period = 'THANG',
    this.month,
    this.year,
  });

  final String? userName;
  final String? donViId;
  final String period;
  final int? month;
  final int? year;

  Map<String, dynamic> toJson() => {
        'userName': userName,
        'donViId': donViId,
        'period': period,
        'month': month,
        'year': year,
      };
}

/// Thân POST bản đồ đầu mối (`Ma`: `xang` | `dau`).
class LeaderHomeDistributorMapRequest {
  const LeaderHomeDistributorMapRequest({this.userName, required this.ma});

  final String? userName;
  final String ma;

  Map<String, dynamic> toJson() => {
        'userName': userName,
        'ma': ma,
      };
}

class LeaderHomeInventorySummaryResponse {
  const LeaderHomeInventorySummaryResponse({
    required this.dataSource,
    required this.tongTonKho,
    required this.nhapXuat,
    required this.canDoi,
  });

  final String dataSource;
  final List<LeaderHomeTongTonKhoRow> tongTonKho;
  final List<LeaderHomeNhapXuatRow> nhapXuat;
  final List<LeaderHomeCanDoiRow> canDoi;

  bool get fromStoredProcedure => dataSource == 'stored_procedure';

  factory LeaderHomeInventorySummaryResponse.fromJson(Map<String, dynamic> json) {
    return LeaderHomeInventorySummaryResponse(
      dataSource: JsonUtils.readString(json['dataSource']) ?? 'unavailable',
      tongTonKho: _listMap(json['tongTonKho'], LeaderHomeTongTonKhoRow.fromJson),
      nhapXuat: _listMap(json['nhapXuat'], LeaderHomeNhapXuatRow.fromJson),
      canDoi: _listMap(json['canDoi'], LeaderHomeCanDoiRow.fromJson),
    );
  }
}

List<T> _listMap<T>(dynamic raw, T Function(Map<String, dynamic>) f) {
  final list = JsonUtils.readList(raw);
  if (list == null) return [];
  final out = <T>[];
  for (final e in list) {
    final m = JsonUtils.readMap(e);
    if (m != null) out.add(f(m));
  }
  return out;
}

class LeaderHomeTongTonKhoRow {
  const LeaderHomeTongTonKhoRow({
    required this.ten,
    required this.dvt,
    required this.giaTri,
    required this.soNgay,
    required this.type,
    required this.trend,
  });

  final String ten;
  final String dvt;
  final double giaTri;
  final int soNgay;
  final String type;
  final List<double> trend;

  factory LeaderHomeTongTonKhoRow.fromJson(Map<String, dynamic> json) {
    final tr = <double>[];
    final rawT = JsonUtils.readList(json['trend']);
    if (rawT != null) {
      for (final e in rawT) {
        final n = JsonUtils.readDouble(e);
        if (n != null) tr.add(n);
      }
    }
    return LeaderHomeTongTonKhoRow(
      ten: JsonUtils.readString(json['ten']) ?? '',
      dvt: JsonUtils.readString(json['dvt']) ?? '',
      giaTri: JsonUtils.readDouble(json['giaTri']) ?? 0,
      soNgay: JsonUtils.readInt(json['soNgay']) ?? 0,
      type: JsonUtils.readString(json['type']) ?? '',
      trend: tr,
    );
  }
}

class LeaderHomeNhapXuatRow {
  const LeaderHomeNhapXuatRow({
    required this.ten,
    required this.dvt,
    required this.type,
    required this.nhap,
    required this.xuat,
    required this.pctNhap,
    required this.pctXuat,
  });

  final String ten;
  final String dvt;
  final String type;
  final double nhap;
  final double xuat;
  final double pctNhap;
  final double pctXuat;

  factory LeaderHomeNhapXuatRow.fromJson(Map<String, dynamic> json) {
    return LeaderHomeNhapXuatRow(
      ten: JsonUtils.readString(json['ten']) ?? '',
      dvt: JsonUtils.readString(json['dvt']) ?? '',
      type: JsonUtils.readString(json['type']) ?? '',
      nhap: JsonUtils.readDouble(json['nhap']) ?? 0,
      xuat: JsonUtils.readDouble(json['xuat']) ?? 0,
      pctNhap: JsonUtils.readDouble(json['pctNhap']) ?? 0,
      pctXuat: JsonUtils.readDouble(json['pctXuat']) ?? 0,
    );
  }
}

class LeaderHomeCanDoiRow {
  const LeaderHomeCanDoiRow({
    required this.ten,
    required this.dvt,
    required this.type,
    required this.giaTri,
    required this.trend,
  });

  final String ten;
  final String dvt;
  final String type;
  final double giaTri;
  final List<double> trend;

  factory LeaderHomeCanDoiRow.fromJson(Map<String, dynamic> json) {
    final tr = <double>[];
    final rawT = JsonUtils.readList(json['trend']);
    if (rawT != null) {
      for (final e in rawT) {
        final n = JsonUtils.readDouble(e);
        if (n != null) tr.add(n);
      }
    }
    return LeaderHomeCanDoiRow(
      ten: JsonUtils.readString(json['ten']) ?? '',
      dvt: JsonUtils.readString(json['dvt']) ?? '',
      type: JsonUtils.readString(json['type']) ?? '',
      giaTri: JsonUtils.readDouble(json['giaTri']) ?? 0,
      trend: tr,
    );
  }
}

class LeaderHomeNationalStockMovementResponse {
  const LeaderHomeNationalStockMovementResponse({
    required this.dataSource,
    this.tonKhoChart,
    this.nhapXuatChart,
    this.tonKhoVsPrevMonth,
    this.nhapXuatVsPrevMonth,
  });

  final String dataSource;
  final LeaderHomeNationalMovementChart? tonKhoChart;
  final LeaderHomeNationalMovementChart? nhapXuatChart;
  final LeaderHomeTonKhoVsPrevMonth? tonKhoVsPrevMonth;
  final LeaderHomeNhapXuatVsPrevMonth? nhapXuatVsPrevMonth;

  bool get fromStoredProcedure => dataSource == 'stored_procedure';

  factory LeaderHomeNationalStockMovementResponse.fromJson(Map<String, dynamic> json) {
    return LeaderHomeNationalStockMovementResponse(
      dataSource: JsonUtils.readString(json['dataSource']) ?? 'unavailable',
      tonKhoChart: _chart(json['tonKhoChart']),
      nhapXuatChart: _chart(json['nhapXuatChart']),
      tonKhoVsPrevMonth: _vsTon(json['tonKhoVsPrevMonth']),
      nhapXuatVsPrevMonth: _vsNx(json['nhapXuatVsPrevMonth']),
    );
  }
}

LeaderHomeNationalMovementChart? _chart(dynamic raw) {
  final m = JsonUtils.readMap(raw);
  if (m == null) return null;
  return LeaderHomeNationalMovementChart.fromJson(m);
}

LeaderHomeTonKhoVsPrevMonth? _vsTon(dynamic raw) {
  final m = JsonUtils.readMap(raw);
  if (m == null) return null;
  return LeaderHomeTonKhoVsPrevMonth.fromJson(m);
}

LeaderHomeNhapXuatVsPrevMonth? _vsNx(dynamic raw) {
  final m = JsonUtils.readMap(raw);
  if (m == null) return null;
  return LeaderHomeNhapXuatVsPrevMonth.fromJson(m);
}

class LeaderHomeNationalMovementChart {
  const LeaderHomeNationalMovementChart({required this.labels, required this.datasets});

  final List<String> labels;
  final List<LeaderHomeNationalDataset> datasets;

  factory LeaderHomeNationalMovementChart.fromJson(Map<String, dynamic> json) {
    final lbl = <String>[];
    final rawL = JsonUtils.readList(json['labels']);
    if (rawL != null) {
      for (final e in rawL) {
        final s = JsonUtils.readString(e);
        if (s != null) lbl.add(s);
      }
    }
    final ds = <LeaderHomeNationalDataset>[];
    final rawD = JsonUtils.readList(json['datasets']);
    if (rawD != null) {
      for (final e in rawD) {
        final m = JsonUtils.readMap(e);
        if (m != null) ds.add(LeaderHomeNationalDataset.fromJson(m));
      }
    }
    return LeaderHomeNationalMovementChart(labels: lbl, datasets: ds);
  }
}

class LeaderHomeNationalDataset {
  const LeaderHomeNationalDataset({
    required this.label,
    this.borderColor,
    this.backgroundColor,
    required this.data,
  });

  final String label;
  final String? borderColor;
  final String? backgroundColor;
  final List<double> data;

  factory LeaderHomeNationalDataset.fromJson(Map<String, dynamic> json) {
    final pts = <double>[];
    final raw = JsonUtils.readList(json['data']);
    if (raw != null) {
      for (final e in raw) {
        final n = JsonUtils.readDouble(e);
        if (n != null) pts.add(n.toDouble());
      }
    }
    return LeaderHomeNationalDataset(
      label: JsonUtils.readString(json['label']) ?? '',
      borderColor: JsonUtils.readString(json['borderColor']),
      backgroundColor: JsonUtils.readString(json['backgroundColor']),
      data: pts,
    );
  }
}

class LeaderHomeTonKhoVsPrevMonth {
  const LeaderHomeTonKhoVsPrevMonth({required this.xangPct, required this.dauPct});

  final double xangPct;
  final double dauPct;

  factory LeaderHomeTonKhoVsPrevMonth.fromJson(Map<String, dynamic> json) {
    return LeaderHomeTonKhoVsPrevMonth(
      xangPct: JsonUtils.readDouble(json['xangPct']) ?? 0,
      dauPct: JsonUtils.readDouble(json['dauPct']) ?? 0,
    );
  }
}

class LeaderHomeNhapXuatVsPrevMonth {
  const LeaderHomeNhapXuatVsPrevMonth({required this.nhapPct, required this.xuatPct});

  final double nhapPct;
  final double xuatPct;

  factory LeaderHomeNhapXuatVsPrevMonth.fromJson(Map<String, dynamic> json) {
    return LeaderHomeNhapXuatVsPrevMonth(
      nhapPct: JsonUtils.readDouble(json['nhapPct']) ?? 0,
      xuatPct: JsonUtils.readDouble(json['xuatPct']) ?? 0,
    );
  }
}

class LeaderHomePriceSummaryResponse {
  const LeaderHomePriceSummaryResponse({
    required this.dataSource,
    required this.prices,
    this.priceChart,
  });

  final String dataSource;
  final List<LeaderHomePriceRow> prices;
  final LeaderHomePriceChart? priceChart;

  bool get fromStoredProcedure => dataSource == 'stored_procedure';

  factory LeaderHomePriceSummaryResponse.fromJson(Map<String, dynamic> json) {
    return LeaderHomePriceSummaryResponse(
      dataSource: JsonUtils.readString(json['dataSource']) ?? 'unavailable',
      prices: _listMap(json['prices'], LeaderHomePriceRow.fromJson),
      priceChart: _priceChart(json['priceChart']),
    );
  }
}

LeaderHomePriceChart? _priceChart(dynamic raw) {
  final m = JsonUtils.readMap(raw);
  if (m == null) return null;
  return LeaderHomePriceChart.fromJson(m);
}

class LeaderHomePriceRow {
  const LeaderHomePriceRow({
    required this.name,
    required this.value,
    required this.change,
    this.styleClass,
    required this.color,
  });

  final String name;
  final double value;
  final double change;
  final String? styleClass;
  final String color;

  factory LeaderHomePriceRow.fromJson(Map<String, dynamic> json) {
    return LeaderHomePriceRow(
      name: JsonUtils.readString(json['name']) ?? '',
      value: JsonUtils.readDouble(json['value']) ?? 0,
      change: JsonUtils.readDouble(json['change']) ?? 0,
      styleClass: JsonUtils.readString(json['class']),
      color: JsonUtils.readString(json['color']) ?? '',
    );
  }
}

class LeaderHomePriceChart {
  const LeaderHomePriceChart({
    required this.labels,
    this.ngayDinhGiaGanNhat,
    required this.datasets,
  });

  final List<String> labels;
  final String? ngayDinhGiaGanNhat;
  final List<LeaderHomePriceDataset> datasets;

  factory LeaderHomePriceChart.fromJson(Map<String, dynamic> json) {
    final lbl = <String>[];
    final rawL = JsonUtils.readList(json['labels']);
    if (rawL != null) {
      for (final e in rawL) {
        final s = JsonUtils.readString(e);
        if (s != null) lbl.add(s);
      }
    }
    final ds = <LeaderHomePriceDataset>[];
    final rawD = JsonUtils.readList(json['datasets']);
    if (rawD != null) {
      for (final e in rawD) {
        final m = JsonUtils.readMap(e);
        if (m != null) ds.add(LeaderHomePriceDataset.fromJson(m));
      }
    }
    return LeaderHomePriceChart(
      labels: lbl,
      ngayDinhGiaGanNhat: JsonUtils.readString(json['ngayDinhGiaGanNhat']),
      datasets: ds,
    );
  }
}

class LeaderHomePriceDataset {
  const LeaderHomePriceDataset({
    required this.label,
    required this.borderColor,
    required this.data,
  });

  final String label;
  final String borderColor;
  final List<double> data;

  factory LeaderHomePriceDataset.fromJson(Map<String, dynamic> json) {
    final pts = <double>[];
    final raw = JsonUtils.readList(json['data']);
    if (raw != null) {
      for (final e in raw) {
        final n = JsonUtils.readDouble(e);
        if (n != null) pts.add(n.toDouble());
      }
    }
    return LeaderHomePriceDataset(
      label: JsonUtils.readString(json['label']) ?? '',
      borderColor: JsonUtils.readString(json['borderColor']) ?? '#3b82f6',
      data: pts,
    );
  }
}

class LeaderHomeDistributorMapResponse {
  const LeaderHomeDistributorMapResponse({
    required this.dataSource,
    required this.items,
  });

  final String dataSource;
  final List<LeaderHomeDistributorMapRow> items;

  bool get fromStoredProcedure => dataSource == 'stored_procedure';

  factory LeaderHomeDistributorMapResponse.fromJson(Map<String, dynamic> json) {
    return LeaderHomeDistributorMapResponse(
      dataSource: JsonUtils.readString(json['dataSource']) ?? 'unavailable',
      items: _listMap(json['items'], LeaderHomeDistributorMapRow.fromJson),
    );
  }
}

class LeaderHomeDistributorMapRow {
  const LeaderHomeDistributorMapRow({
    required this.name,
    required this.lat,
    required this.lng,
    required this.xang,
    required this.dau,
    required this.days,
  });

  final String name;
  final double lat;
  final double lng;
  final double xang;
  final double dau;
  final int days;

  factory LeaderHomeDistributorMapRow.fromJson(Map<String, dynamic> json) {
    return LeaderHomeDistributorMapRow(
      name: JsonUtils.readString(json['name']) ?? '',
      lat: JsonUtils.readDouble(json['lat']) ?? 0,
      lng: JsonUtils.readDouble(json['lng']) ?? 0,
      xang: JsonUtils.readDouble(json['xang']) ?? 0,
      dau: JsonUtils.readDouble(json['dau']) ?? 0,
      days: JsonUtils.readInt(json['days']) ?? 0,
    );
  }
}
