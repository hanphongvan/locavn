import '../../../core/network/json_utils.dart';

List<T> _listMap<T>(dynamic raw, T Function(Map<String, dynamic>) f) {
  final list = JsonUtils.readList(raw);
  if (list == null) return const [];
  final out = <T>[];
  for (final e in list) {
    final m = JsonUtils.readMap(e);
    if (m != null) out.add(f(m));
  }
  return out;
}

/// GET `/api/leader/dashboard/inventory-detail`.
class LeaderInventoryDetailResponse {
  const LeaderInventoryDetailResponse({
    required this.dataSource,
    this.reportPeriodLabel,
    required this.items,
  });

  final String dataSource;
  final String? reportPeriodLabel;
  final List<LeaderInventoryDetailRow> items;

  bool get fromStoredProcedure => dataSource == 'stored_procedure';

  factory LeaderInventoryDetailResponse.fromJson(Map<String, dynamic> json) {
    return LeaderInventoryDetailResponse(
      dataSource: JsonUtils.readString(json['dataSource']) ?? '',
      reportPeriodLabel: JsonUtils.readString(json['reportPeriodLabel']),
      items: _listMap(json['items'], LeaderInventoryDetailRow.fromJson),
    );
  }
}

class LeaderInventoryDetailRow {
  const LeaderInventoryDetailRow({
    required this.distributorId,
    required this.distributorName,
    this.address,
    required this.fuelType,
    required this.inventoryQuantity,
    required this.unit,
    required this.coverageDays,
    required this.statusCode,
    required this.status,
    this.updatedAt,
  });

  final int distributorId;
  final String distributorName;
  final String? address;
  final String fuelType;
  final double inventoryQuantity;
  final String unit;
  final double coverageDays;
  /// 0 = an toàn, 1 = cảnh báo, 2 = nguy cơ (theo backend / SQL).
  final int statusCode;
  final String status;
  final DateTime? updatedAt;

  factory LeaderInventoryDetailRow.fromJson(Map<String, dynamic> json) {
    return LeaderInventoryDetailRow(
      distributorId: JsonUtils.readInt(json['distributorId']) ?? 0,
      distributorName: JsonUtils.readString(json['distributorName']) ?? '',
      address: JsonUtils.readString(json['address']),
      fuelType: JsonUtils.readString(json['fuelType']) ?? '',
      inventoryQuantity: JsonUtils.readDouble(json['inventoryQuantity']) ?? 0,
      unit: JsonUtils.readString(json['unit']) ?? '',
      coverageDays: JsonUtils.readDouble(json['coverageDays']) ?? 0,
      statusCode: JsonUtils.readInt(json['statusCode']) ?? 1,
      status: JsonUtils.readString(json['status']) ?? '',
      updatedAt: JsonUtils.readDateTime(json['updatedAt']),
    );
  }
}
