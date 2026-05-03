import '../../../../core/network/json_utils.dart';
import '../../../reporting/data/models/station_reporting_prices.dart';
import '../../../reporting/data/models/station_reporting_stock.dart';

/// Backend: `StationOperatingSlotDto`
class StationOperatingSlot {
  const StationOperatingSlot({
    required this.dayOfWeek,
    required this.isClosedAllDay,
    this.opensAt,
    this.closesAt,
  });

  final int dayOfWeek;
  final bool isClosedAllDay;
  final String? opensAt;
  final String? closesAt;

  static StationOperatingSlot? tryParse(dynamic raw) {
    final m = JsonUtils.readMap(raw);
    if (m == null) {
      return null;
    }
    return StationOperatingSlot(
      dayOfWeek: JsonUtils.readIntRequired(m['dayOfWeek'], field: 'dayOfWeek'),
      isClosedAllDay: JsonUtils.readBool(m['isClosedAllDay']) ?? false,
      opensAt: JsonUtils.readString(m['opensAt']),
      closesAt: JsonUtils.readString(m['closesAt']),
    );
  }
}

/// Backend: `StationDetailStoreServiceDto`
class StationDetailStoreService {
  const StationDetailStoreService({
    required this.serviceCode,
    required this.displayName,
    this.iconKey,
    required this.isActive,
    this.price,
    required this.sortOrder,
  });

  final String serviceCode;
  final String displayName;
  final String? iconKey;
  final bool isActive;
  final double? price;
  final int sortOrder;

  static StationDetailStoreService? tryParse(dynamic raw) {
    final m = JsonUtils.readMap(raw);
    if (m == null) return null;
    return StationDetailStoreService(
      serviceCode: JsonUtils.readStringRequired(m['serviceCode'], field: 'serviceCode'),
      displayName: JsonUtils.readStringRequired(m['displayName'], field: 'displayName'),
      iconKey: JsonUtils.readString(m['iconKey']),
      isActive: JsonUtils.readBool(m['isActive']) ?? false,
      price: JsonUtils.readDouble(m['price']),
      sortOrder: JsonUtils.readInt(m['sortOrder']) ?? 0,
    );
  }
}

/// Backend: `StationDetailDto`
class StationDetailDto {
  const StationDetailDto({
    required this.stationId,
    required this.stationCode,
    required this.stationName,
    this.phone,
    this.email,
    this.addressLine,
    this.licenseNumber,
    this.licenseDate,
    this.licenseExpiryDate,
    this.latitude,
    this.longitude,
    this.provinceCode,
    this.provinceName,
    this.wardCode,
    this.wardName,
    this.districtId,
    this.districtCode,
    this.isActive,
    this.openNow,
    this.openStatus,
    this.openingTime,
    this.closingTime,
    this.weeklyOperatingHours,
    this.latestReportingPrices,
    this.latestReportingStock,
    this.priceRon95,
    this.priceDiesel,
    this.storeServices,
  });

  final int stationId;
  final String stationCode;
  final String stationName;
  final String? phone;
  final String? email;
  final String? addressLine;
  final String? licenseNumber;
  final DateTime? licenseDate;
  final DateTime? licenseExpiryDate;
  final double? latitude;
  final double? longitude;
  final String? provinceCode;
  final String? provinceName;
  final String? wardCode;
  final String? wardName;
  final int? districtId;
  final String? districtCode;
  final bool? isActive;
  final bool? openNow;
  final String? openStatus;
  final String? openingTime;
  final String? closingTime;
  final List<StationOperatingSlot>? weeklyOperatingHours;
  final StationReportingPrices? latestReportingPrices;
  final StationReportingStock? latestReportingStock;
  /// Same map snapshot as list/map (`So_01` Ron95 chip) when API sends it.
  final double? priceRon95;
  /// Diesel chip from map snapshot.
  final double? priceDiesel;
  final List<StationDetailStoreService>? storeServices;

  factory StationDetailDto.fromJson(Map<String, dynamic> json) {
    List<StationOperatingSlot>? weekly;
    final w = json['weeklyOperatingHours'];
    if (w is List<dynamic>) {
      weekly = w
          .map((e) => StationOperatingSlot.tryParse(e))
          .whereType<StationOperatingSlot>()
          .toList();
    }

    List<StationDetailStoreService>? services;
    final sv = json['storeServices'];
    if (sv is List<dynamic>) {
      services = sv
          .map(StationDetailStoreService.tryParse)
          .whereType<StationDetailStoreService>()
          .toList();
    }

    return StationDetailDto(
      stationId: JsonUtils.readIntRequired(json['stationId'], field: 'stationId'),
      stationCode: JsonUtils.readString(json['stationCode']) ?? '',
      stationName: JsonUtils.readString(json['stationName']) ?? '',
      phone: JsonUtils.readString(json['phone']),
      email: JsonUtils.readString(json['email']),
      addressLine: JsonUtils.readString(json['addressLine']),
      licenseNumber: JsonUtils.readString(json['licenseNumber']),
      licenseDate: JsonUtils.readDateTime(json['licenseDate']),
      licenseExpiryDate: JsonUtils.readDateTime(json['licenseExpiryDate']),
      latitude: JsonUtils.readDouble(json['latitude']),
      longitude: JsonUtils.readDouble(json['longitude']),
      provinceCode: JsonUtils.readString(json['provinceCode']),
      provinceName: JsonUtils.readString(json['provinceName']),
      wardCode: JsonUtils.readString(json['wardCode']),
      wardName: JsonUtils.readString(json['wardName']),
      districtId: JsonUtils.readInt(json['districtId']),
      districtCode: JsonUtils.readString(json['districtCode']),
      isActive: JsonUtils.readBool(json['isActive']),
      openNow: JsonUtils.readBool(json['openNow']),
      openStatus: JsonUtils.readString(json['openStatus']),
      openingTime: JsonUtils.readString(json['openingTime']),
      closingTime: JsonUtils.readString(json['closingTime']),
      weeklyOperatingHours: weekly?.isEmpty ?? true ? null : weekly,
      latestReportingPrices: StationReportingPrices.parseNullable(json['latestReportingPrices']),
      latestReportingStock: StationReportingStock.parseNullable(json['latestReportingStock']),
      priceRon95: JsonUtils.readDouble(json['priceRon95']),
      priceDiesel: JsonUtils.readDouble(json['priceDiesel']),
      storeServices: services?.isEmpty ?? true ? null : services,
    );
  }
}
