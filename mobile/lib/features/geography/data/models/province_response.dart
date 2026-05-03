import '../../../../core/network/json_utils.dart';

/// Backend: `ProvinceResponseDto`
class ProvinceResponse {
  const ProvinceResponse({
    required this.code,
    required this.name,
    this.sapXep,
    this.vungMien,
  });

  final String code;
  final String name;
  final int? sapXep;
  final int? vungMien;

  factory ProvinceResponse.fromJson(Map<String, dynamic> json) {
    return ProvinceResponse(
      code: JsonUtils.readString(json['code']) ?? '',
      name: JsonUtils.readString(json['name']) ?? '',
      sapXep: JsonUtils.readInt(json['sapXep']),
      vungMien: JsonUtils.readInt(json['vungMien']),
    );
  }
}
