/// Tham số `window` gửi lên API Phân tích.
enum LeaderAnalyticsWindow {
  d7('d7', '7 ngày'),
  d30('d30', '30 ngày'),
  m3('m3', '3 tháng'),
  m6('m6', '6 tháng');

  const LeaderAnalyticsWindow(this.apiValue, this.labelVi);
  final String apiValue;
  final String labelVi;
}

class LeaderAnalyticsInventoryTrendDto {
  const LeaderAnalyticsInventoryTrendDto({
    required this.dataSource,
    required this.labels,
    required this.series,
  });

  final String dataSource;
  final List<String> labels;
  final List<LeaderAnalyticsSeriesDto> series;

  factory LeaderAnalyticsInventoryTrendDto.fromJson(Map<String, dynamic> json) {
    return LeaderAnalyticsInventoryTrendDto(
      dataSource: json['dataSource'] as String? ?? '',
      labels: _stringList(json['labels']),
      series: _listMap(json['series'], LeaderAnalyticsSeriesDto.fromJson),
    );
  }
}

class LeaderAnalyticsSeriesDto {
  const LeaderAnalyticsSeriesDto({
    required this.label,
    required this.color,
    required this.values,
  });

  final String label;
  final String color;
  final List<double> values;

  factory LeaderAnalyticsSeriesDto.fromJson(Map<String, dynamic> json) {
    return LeaderAnalyticsSeriesDto(
      label: json['label'] as String? ?? '',
      color: json['color'] as String? ?? '#2563eb',
      values: _doubleList(json['values']),
    );
  }
}

class LeaderAnalyticsImportExportTrendDto {
  const LeaderAnalyticsImportExportTrendDto({
    required this.dataSource,
    required this.fuel,
    required this.labels,
    required this.nhap,
    required this.xuat,
  });

  final String dataSource;
  final String fuel;
  final List<String> labels;
  final List<double> nhap;
  final List<double> xuat;

  factory LeaderAnalyticsImportExportTrendDto.fromJson(Map<String, dynamic> json) {
    return LeaderAnalyticsImportExportTrendDto(
      dataSource: json['dataSource'] as String? ?? '',
      fuel: json['fuel'] as String? ?? 'xang',
      labels: _stringList(json['labels']),
      nhap: _doubleList(json['nhap']),
      xuat: _doubleList(json['xuat']),
    );
  }
}

class LeaderAnalyticsPriceTrendDto {
  const LeaderAnalyticsPriceTrendDto({
    required this.dataSource,
    required this.labels,
    this.ngayDinhGiaGanNhat,
    required this.currentPrices,
    required this.series,
  });

  final String dataSource;
  final List<String> labels;
  final String? ngayDinhGiaGanNhat;
  final List<LeaderAnalyticsCurrentPriceDto> currentPrices;
  final List<LeaderAnalyticsSeriesDto> series;

  factory LeaderAnalyticsPriceTrendDto.fromJson(Map<String, dynamic> json) {
    return LeaderAnalyticsPriceTrendDto(
      dataSource: json['dataSource'] as String? ?? '',
      labels: _stringList(json['labels']),
      ngayDinhGiaGanNhat: json['ngayDinhGiaGanNhat'] as String?,
      currentPrices: _listMap(json['currentPrices'], LeaderAnalyticsCurrentPriceDto.fromJson),
      series: _listMap(json['series'], LeaderAnalyticsSeriesDto.fromJson),
    );
  }
}

class LeaderAnalyticsCurrentPriceDto {
  const LeaderAnalyticsCurrentPriceDto({
    required this.label,
    required this.value,
    required this.change,
  });

  final String label;
  final double value;
  final double change;

  factory LeaderAnalyticsCurrentPriceDto.fromJson(Map<String, dynamic> json) {
    return LeaderAnalyticsCurrentPriceDto(
      label: json['label'] as String? ?? '',
      value: _toDouble(json['value']),
      change: _toDouble(json['change']),
    );
  }
}

class LeaderAnalyticsPeriodComparisonDto {
  const LeaderAnalyticsPeriodComparisonDto({
    required this.dataSource,
    required this.tonKhoXang,
    required this.tonKhoDau,
    required this.nhap,
    required this.xuat,
  });

  final String dataSource;
  final LeaderAnalyticsDeltaCardDto tonKhoXang;
  final LeaderAnalyticsDeltaCardDto tonKhoDau;
  final LeaderAnalyticsDeltaCardDto nhap;
  final LeaderAnalyticsDeltaCardDto xuat;

  factory LeaderAnalyticsPeriodComparisonDto.fromJson(Map<String, dynamic> json) {
    return LeaderAnalyticsPeriodComparisonDto(
      dataSource: json['dataSource'] as String? ?? '',
      tonKhoXang: LeaderAnalyticsDeltaCardDto.fromJson(_asJsonMap(json['tonKhoXang'])),
      tonKhoDau: LeaderAnalyticsDeltaCardDto.fromJson(_asJsonMap(json['tonKhoDau'])),
      nhap: LeaderAnalyticsDeltaCardDto.fromJson(_asJsonMap(json['nhap'])),
      xuat: LeaderAnalyticsDeltaCardDto.fromJson(_asJsonMap(json['xuat'])),
    );
  }
}

class LeaderAnalyticsDeltaCardDto {
  const LeaderAnalyticsDeltaCardDto({required this.title, required this.pctChange});

  final String title;
  final double pctChange;

  factory LeaderAnalyticsDeltaCardDto.fromJson(Map<String, dynamic> json) {
    return LeaderAnalyticsDeltaCardDto(
      title: json['title'] as String? ?? '',
      pctChange: _toDouble(json['pctChange']),
    );
  }
}

class LeaderAnalyticsMarketInsightDto {
  const LeaderAnalyticsMarketInsightDto({
    required this.dataSource,
    required this.xuHuongGia,
    required this.ruiRoCungCau,
    required this.khuVucBatThuong,
    required this.deXuat,
  });

  final String dataSource;
  final String xuHuongGia;
  final String ruiRoCungCau;
  final String khuVucBatThuong;
  final String deXuat;

  factory LeaderAnalyticsMarketInsightDto.fromJson(Map<String, dynamic> json) {
    return LeaderAnalyticsMarketInsightDto(
      dataSource: json['dataSource'] as String? ?? '',
      xuHuongGia: json['xuHuongGia'] as String? ?? '',
      ruiRoCungCau: json['ruiRoCungCau'] as String? ?? '',
      khuVucBatThuong: json['khuVucBatThuong'] as String? ?? '',
      deXuat: json['deXuat'] as String? ?? '',
    );
  }
}

Map<String, dynamic> _asJsonMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return {};
}

List<String> _stringList(dynamic v) {
  if (v is! List) return [];
  return v.map((e) => '$e').toList();
}

List<double> _doubleList(dynamic v) {
  if (v is! List) return [];
  return v.map(_toDouble).toList();
}

double _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0;
  return 0;
}

List<T> _listMap<T>(dynamic v, T Function(Map<String, dynamic>) f) {
  if (v is! List) return [];
  final out = <T>[];
  for (final e in v) {
    if (e is Map<String, dynamic>) {
      out.add(f(e));
    } else if (e is Map) {
      out.add(f(Map<String, dynamic>.from(e)));
    }
  }
  return out;
}
