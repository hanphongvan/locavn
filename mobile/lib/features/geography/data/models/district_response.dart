import '../../../../core/network/json_utils.dart';

/// Backend: `DistrictResponseDto`
class DistrictResponse {
  const DistrictResponse({
    required this.districtId,
    required this.districtCode,
    this.districtName,
  });

  final int districtId;
  final String districtCode;
  final String? districtName;

  factory DistrictResponse.fromJson(Map<String, dynamic> json) {
    return DistrictResponse(
      districtId: JsonUtils.readIntRequired(json['districtId'], field: 'districtId'),
      districtCode: JsonUtils.readString(json['districtCode']) ?? '',
      districtName: JsonUtils.readString(json['districtName']),
    );
  }
}
