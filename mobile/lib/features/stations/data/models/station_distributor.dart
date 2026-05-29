import '../../../../core/network/json_utils.dart';

/// Backend: `StationDistributorDto` — 1 đầu mối (`DM_DonVi.CapDonViId=235`) có trạm bán lẻ.
class StationDistributor {
  const StationDistributor({
    required this.id,
    required this.name,
    required this.stationCount,
    this.brandKey,
    this.brandLogoUrl,
  });

  /// `DM_DonVi.Id` của đầu mối — khớp `StationMapItem.parentDonViId`.
  final int id;
  final String name;

  /// Số trạm bán lẻ (`CapDonViId=248`) thuộc đầu mối này.
  final int stationCount;

  /// Slug từ `StationBranding` (Petrolimex / PVOIL / Saigon Petro …); null khi chưa cấu hình.
  final String? brandKey;
  final String? brandLogoUrl;

  factory StationDistributor.fromJson(Map<String, dynamic> json) {
    return StationDistributor(
      id: JsonUtils.readIntRequired(json['id'], field: 'id'),
      name: JsonUtils.readString(json['name']) ?? '',
      stationCount: JsonUtils.readInt(json['stationCount']) ?? 0,
      brandKey: JsonUtils.readString(json['brandKey']),
      brandLogoUrl: JsonUtils.readString(json['brandLogoUrl']),
    );
  }
}
