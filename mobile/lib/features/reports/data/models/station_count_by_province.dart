import '../../../../core/network/json_utils.dart';

/// Backend: `StationCountByProvinceDto`
class StationCountByProvince {
  const StationCountByProvince({
    this.provinceCode,
    this.provinceName,
    required this.stationCount,
  });

  final String? provinceCode;
  final String? provinceName;
  final int stationCount;

  factory StationCountByProvince.fromJson(Map<String, dynamic> json) {
    return StationCountByProvince(
      provinceCode: JsonUtils.readString(json['provinceCode']),
      provinceName: JsonUtils.readString(json['provinceName']),
      stationCount: JsonUtils.readInt(json['stationCount']) ?? 0,
    );
  }
}
