import '../../../../core/network/json_utils.dart';

/// Backend: `StationMapItemDto` (V1) hoặc `StationMapItemV2Dto` (V2).
/// [priceForSelectedFuel] chỉ có trong V2 và non-null khi request truyền `fuelCode`.
class StationMapItem {
  const StationMapItem({
    required this.stationId,
    required this.stationName,
    required this.latitude,
    required this.longitude,
    this.shortAddress,
    this.priceRon95,
    this.priceDiesel,
    this.priceForSelectedFuel,
    this.isActive,
    this.openNow,
    this.openStatus,
    this.openingTime,
    this.closingTime,
    this.activeServiceCodes = const [],
    this.brandKey,
    this.brandLogoUrl,
    this.parentDonViId,
  });

  final int stationId;
  final String stationName;
  final double latitude;
  final double longitude;
  final String? shortAddress;

  /// Đơn giá RON95 (`So_01` dòng báo cáo khớp) — đồng.
  final double? priceRon95;

  /// Đơn giá diesel / DO (`So_01` dòng báo cáo khớp) — đồng.
  final double? priceDiesel;

  /// V2 only: giá theo fuelCode mobile đã chọn (`StationStoreServices.Price`). Null trong V1
  /// hoặc khi V2 được gọi không truyền `fuelCode`.
  final double? priceForSelectedFuel;

  /// `DM_DonVi.TrangThai` — giấy phép / hoạt động hồ sơ.
  final bool? isActive;

  /// Giờ mở cửa thực tế (theo `StationOperatingHours`, giờ VN) khi có dữ liệu.
  final bool? openNow;

  /// `open` | `closed` | `unknown`
  final String? openStatus;

  final String? openingTime;
  final String? closingTime;

  /// Active `StationStoreServices.serviceCode` values from the map API.
  final List<String> activeServiceCodes;

  /// Slug ổn định cho thương hiệu (đầu mối). Khi non-null, marker dùng logo brand
  /// thay icon trạm chung. Lookup asset bundled qua `BrandMarkerRegistry`.
  final String? brandKey;

  /// Remote logo URL fallback cho brand chưa bundle (cache memory client-side).
  final String? brandLogoUrl;

  /// `DM_DonVi.CapTrenId` — id đầu mối (CapDonViId=235). Mobile dùng để filter client-side
  /// khi user chọn brand trên thanh tìm kiếm.
  final int? parentDonViId;

  /// `true` nếu cặp (lat, lng) hữu hạn và nằm trong dải hợp lệ.
  /// Dùng để filter những trạm có dữ liệu tọa độ hỏng (NaN, Infinity, vượt ±90/±180).
  static bool isValidCoord(double lat, double lng) =>
      lat.isFinite &&
      lng.isFinite &&
      lat.abs() <= 90 &&
      lng.abs() <= 180;

  bool get hasValidCoord => isValidCoord(latitude, longitude);

  factory StationMapItem.fromJson(Map<String, dynamic> json) {
    return StationMapItem(
      stationId: JsonUtils.readIntRequired(json['stationId'], field: 'stationId'),
      stationName: JsonUtils.readString(json['stationName']) ?? '',
      latitude: JsonUtils.readDoubleRequired(json['latitude'], field: 'latitude'),
      longitude: JsonUtils.readDoubleRequired(json['longitude'], field: 'longitude'),
      shortAddress: JsonUtils.readString(json['shortAddress']),
      priceRon95: JsonUtils.readDouble(json['priceRon95']),
      priceDiesel: JsonUtils.readDouble(json['priceDiesel']),
      priceForSelectedFuel: JsonUtils.readDouble(json['priceForSelectedFuel']),
      isActive: JsonUtils.readBool(json['isActive']),
      openNow: JsonUtils.readBool(json['openNow']),
      openStatus: JsonUtils.readString(json['openStatus']),
      openingTime: JsonUtils.readString(json['openingTime']),
      closingTime: JsonUtils.readString(json['closingTime']),
      activeServiceCodes: _readStringList(json['activeServiceCodes']),
      brandKey: JsonUtils.readString(json['brandKey']),
      brandLogoUrl: JsonUtils.readString(json['brandLogoUrl']),
      parentDonViId: JsonUtils.readInt(json['parentDonViId']),
    );
  }

  static List<String> _readStringList(Object? raw) {
    if (raw is! List<dynamic>) return const [];
    final out = <String>[];
    for (final e in raw) {
      final s = JsonUtils.readString(e);
      if (s != null && s.isNotEmpty) out.add(s);
    }
    return out;
  }
}
