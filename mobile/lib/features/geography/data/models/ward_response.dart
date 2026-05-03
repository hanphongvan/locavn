import '../../../../core/network/json_utils.dart';

/// Backend: `WardResponseDto`
class WardResponse {
  const WardResponse({
    required this.code,
    required this.name,
    this.tinhId,
    this.quanHuyenId,
  });

  final String code;
  final String name;
  final int? tinhId;
  final int? quanHuyenId;

  factory WardResponse.fromJson(Map<String, dynamic> json) {
    return WardResponse(
      code: JsonUtils.readString(json['code']) ?? '',
      name: JsonUtils.readString(json['name']) ?? '',
      tinhId: JsonUtils.readInt(json['tinhId']),
      quanHuyenId: JsonUtils.readInt(json['quanHuyenId']),
    );
  }
}
