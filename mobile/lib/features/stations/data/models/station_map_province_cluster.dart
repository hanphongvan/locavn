import '../../../../core/network/json_utils.dart';

/// Backend `StationMapProvinceClusterDto` trả từ
/// `GET /api/stations/map/clusters` (Phase 2.G).
class StationMapProvinceCluster {
  const StationMapProvinceCluster({
    required this.provinceId,
    required this.provinceCode,
    required this.provinceName,
    required this.stationCount,
    required this.centroidLat,
    required this.centroidLng,
  });

  final int provinceId;
  final String provinceCode;
  final String provinceName;
  final int stationCount;
  final double centroidLat;
  final double centroidLng;

  factory StationMapProvinceCluster.fromJson(Map<String, dynamic> json) {
    return StationMapProvinceCluster(
      provinceId: JsonUtils.readInt(json['provinceId']) ??
          JsonUtils.readInt(json['ProvinceId']) ??
          0,
      provinceCode: JsonUtils.readString(json['provinceCode']) ??
          JsonUtils.readString(json['ProvinceCode']) ??
          '',
      provinceName: JsonUtils.readString(json['provinceName']) ??
          JsonUtils.readString(json['ProvinceName']) ??
          '',
      stationCount: JsonUtils.readInt(json['stationCount']) ??
          JsonUtils.readInt(json['StationCount']) ??
          0,
      centroidLat: JsonUtils.readDouble(json['centroidLat']) ??
          JsonUtils.readDouble(json['CentroidLat']) ??
          0.0,
      centroidLng: JsonUtils.readDouble(json['centroidLng']) ??
          JsonUtils.readDouble(json['CentroidLng']) ??
          0.0,
    );
  }
}
