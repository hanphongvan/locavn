import 'package:flutter/foundation.dart';

/// Loại đơn vị (bản đồ hiện chủ yếu cửa hàng bán lẻ; đầu mối sẽ hiển thị khi API bổ sung).
enum MapUnitTypeFilter { all, wholesale, retail }

/// Lọc theo loại nhiên liệu có giá trên marker (client-side).
enum MapFuelTypeFilter { all, petrol, diesel, lpg }

/// Lọc theo đánh giá — chỉ thu hẹp danh sách khi API map có điểm trung bình.
enum MapRatingFilter { all, min3, min4 }

/// Map filter state. Geo + [status] + [keyword] kích hoạt tải lại từ máy chủ;
/// các trường còn lại lọc client-side sau khi tải (không gọi lại API khi chỉ đổi chip).
@immutable
class MapFilters {
  const MapFilters({
    this.keyword,
    this.provinceCode,
    this.districtCode,
    this.provinceLabel,
    this.districtLabel,
    /// `null` / rỗng / `'all'` → không gửi `status`. `'open'` / `'closed'` → API.
    this.status,
    this.unitType = MapUnitTypeFilter.all,
    this.fuelType = MapFuelTypeFilter.all,
    this.ratingFilter = MapRatingFilter.all,
    this.priceMinDong = MapFilters.priceSliderMinDong,
    this.priceMaxDong = MapFilters.priceSliderMaxDong,
    this.selectedServiceCodes = const [],
  });

  final String? keyword;
  final String? provinceCode;
  final String? districtCode;
  final String? provinceLabel;
  final String? districtLabel;
  final String? status;

  final MapUnitTypeFilter unitType;
  final MapFuelTypeFilter fuelType;
  final MapRatingFilter ratingFilter;
  final int priceMinDong;
  final int priceMaxDong;

  /// Uppercase service codes from [StoreServiceCatalogItem.serviceCode] — station must have **all** active.
  final List<String> selectedServiceCodes;

  /// Đồng/lít — mép slider (đơn giản, không phụ thuộc từng tỉnh).
  static const int priceSliderMinDong = 10000;
  static const int priceSliderMaxDong = 50000;

  static const int maxKeywordLength = 200;

  static List<String> normalizeSelectedServices(Iterable<String> raw) {
    final u = raw.map((c) => c.toUpperCase()).toSet().toList()..sort();
    return List<String>.unmodifiable(u);
  }

  bool get hasActiveGeo =>
      (provinceCode != null && provinceCode!.trim().isNotEmpty) ||
      (districtCode != null && districtCode!.trim().isNotEmpty);

  bool get hasActiveKeyword => keyword != null && keyword!.trim().isNotEmpty;

  bool get hasPriceFilter =>
      priceMinDong > priceSliderMinDong || priceMaxDong < priceSliderMaxDong;

  bool get hasActiveClientFilters =>
      unitType != MapUnitTypeFilter.all ||
      fuelType != MapFuelTypeFilter.all ||
      ratingFilter != MapRatingFilter.all ||
      hasPriceFilter ||
      selectedServiceCodes.isNotEmpty;

  /// Tỉnh/huyện/từ khóa — hiển thị thanh chip trên bản đồ.
  bool get hasActiveStrip => hasActiveGeo || hasActiveKeyword;

  /// Có bất kỳ bộ lọc nào (gồm chip client-side).
  bool get hasAny => hasActiveStrip || hasActiveClientFilters;

  /// Chuỗi tóm tắt một dòng (collapsed sheet / chip).
  String get compactSummaryLabel {
    final parts = <String>[];
    switch (fuelType) {
      case MapFuelTypeFilter.all:
        break;
      case MapFuelTypeFilter.petrol:
        parts.add('Xăng');
        break;
      case MapFuelTypeFilter.diesel:
        parts.add('Dầu');
        break;
      case MapFuelTypeFilter.lpg:
        parts.add('Khí');
        break;
    }
    final st = status?.trim().toLowerCase();
    if (st == 'open') {
      parts.add('Đang mở');
    } else if (st == 'closed') {
      parts.add('Đóng cửa');
    }
    switch (ratingFilter) {
      case MapRatingFilter.all:
        break;
      case MapRatingFilter.min3:
        parts.add('≥ 3⭐');
        break;
      case MapRatingFilter.min4:
        parts.add('≥ 4⭐');
        break;
    }
    switch (unitType) {
      case MapUnitTypeFilter.all:
        break;
      case MapUnitTypeFilter.wholesale:
        parts.add('Đầu mối');
        break;
      case MapUnitTypeFilter.retail:
        parts.add('Bán lẻ');
        break;
    }
    if (hasPriceFilter) {
      parts.add('Giá ${formatDongVnd(priceMinDong)}–${formatDongVnd(priceMaxDong)}');
    }
    if (selectedServiceCodes.isNotEmpty) {
      parts.add(
        selectedServiceCodes.length == 1
            ? '1 dịch vụ'
            : '${selectedServiceCodes.length} dịch vụ',
      );
    }
    if (parts.isEmpty) {
      return 'Chưa lọc thêm';
    }
    return parts.join(' • ');
  }

  /// Định dạng đồng kiểu `20.000đ`.
  static String formatDongVnd(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    final len = s.length;
    for (var i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '$bufđ';
  }

  /// Floating search: chỉ cập nhật từ khóa.
  MapFilters copyWithKeyword(String? keyword) {
    final t = keyword?.trim();
    return MapFilters(
      keyword: (t == null || t.isEmpty) ? null : t,
      provinceCode: provinceCode,
      districtCode: districtCode,
      provinceLabel: provinceLabel,
      districtLabel: districtLabel,
      status: status,
      unitType: unitType,
      fuelType: fuelType,
      ratingFilter: ratingFilter,
      priceMinDong: priceMinDong,
      priceMaxDong: priceMaxDong,
      selectedServiceCodes: selectedServiceCodes,
    );
  }

  static const Object _sentinel = Object();

  MapFilters copyWith({
    Object? keyword = _sentinel,
    Object? provinceCode = _sentinel,
    Object? districtCode = _sentinel,
    Object? provinceLabel = _sentinel,
    Object? districtLabel = _sentinel,
    Object? status = _sentinel,
    Object? unitType = _sentinel,
    Object? fuelType = _sentinel,
    Object? ratingFilter = _sentinel,
    Object? priceMinDong = _sentinel,
    Object? priceMaxDong = _sentinel,
    Object? selectedServiceCodes = _sentinel,
  }) {
    return MapFilters(
      keyword: identical(keyword, _sentinel) ? this.keyword : keyword as String?,
      provinceCode: identical(provinceCode, _sentinel) ? this.provinceCode : provinceCode as String?,
      districtCode: identical(districtCode, _sentinel) ? this.districtCode : districtCode as String?,
      provinceLabel: identical(provinceLabel, _sentinel) ? this.provinceLabel : provinceLabel as String?,
      districtLabel: identical(districtLabel, _sentinel) ? this.districtLabel : districtLabel as String?,
      status: identical(status, _sentinel) ? this.status : status as String?,
      unitType: identical(unitType, _sentinel) ? this.unitType : unitType as MapUnitTypeFilter,
      fuelType: identical(fuelType, _sentinel) ? this.fuelType : fuelType as MapFuelTypeFilter,
      ratingFilter: identical(ratingFilter, _sentinel) ? this.ratingFilter : ratingFilter as MapRatingFilter,
      priceMinDong: identical(priceMinDong, _sentinel) ? this.priceMinDong : priceMinDong as int,
      priceMaxDong: identical(priceMaxDong, _sentinel) ? this.priceMaxDong : priceMaxDong as int,
      selectedServiceCodes: identical(selectedServiceCodes, _sentinel)
          ? this.selectedServiceCodes
          : List<String>.unmodifiable(
              (selectedServiceCodes as List<String>).map((c) => c.toUpperCase()).toList()..sort(),
            ),
    );
  }
}
