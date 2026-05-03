import '../../../../core/network/json_utils.dart';

/// Backend: `StationListItemDto`
class StationListItem {
  const StationListItem({
    required this.stationId,
    required this.stationCode,
    required this.stationName,
    this.addressLine,
    this.provinceCode,
    this.provinceName,
    this.wardCode,
    this.wardName,
    this.districtId,
    this.licenseNumber,
    this.isActive,
    this.openNow,
    this.openStatus,
    this.openingTime,
    this.closingTime,
    this.priceRon95,
    this.priceDiesel,
  });

  final int stationId;
  final String stationCode;
  final String stationName;
  final String? addressLine;
  final String? provinceCode;
  final String? provinceName;
  final String? wardCode;
  final String? wardName;
  final int? districtId;
  final String? licenseNumber;
  final bool? isActive;
  final bool? openNow;
  final String? openStatus;
  final String? openingTime;
  final String? closingTime;
  final double? priceRon95;
  final double? priceDiesel;

  factory StationListItem.fromJson(Map<String, dynamic> json) {
    return StationListItem(
      stationId: JsonUtils.readIntRequired(json['stationId'], field: 'stationId'),
      stationCode: JsonUtils.readString(json['stationCode']) ?? '',
      stationName: JsonUtils.readString(json['stationName']) ?? '',
      addressLine: JsonUtils.readString(json['addressLine']),
      provinceCode: JsonUtils.readString(json['provinceCode']),
      provinceName: JsonUtils.readString(json['provinceName']),
      wardCode: JsonUtils.readString(json['wardCode']),
      wardName: JsonUtils.readString(json['wardName']),
      districtId: JsonUtils.readInt(json['districtId']),
      licenseNumber: JsonUtils.readString(json['licenseNumber']),
      isActive: JsonUtils.readBool(json['isActive']),
      openNow: JsonUtils.readBool(json['openNow']),
      openStatus: JsonUtils.readString(json['openStatus']),
      openingTime: JsonUtils.readString(json['openingTime']),
      closingTime: JsonUtils.readString(json['closingTime']),
      priceRon95: JsonUtils.readDouble(json['priceRon95']),
      priceDiesel: JsonUtils.readDouble(json['priceDiesel']),
    );
  }
}
