import '../../../../core/network/json_utils.dart';

/// Backend: `StoreAdminStoreDto` — `GET /api/admin/stores` (hub store label).
class StoreAdminStoreRow {
  const StoreAdminStoreRow({
    required this.id,
    required this.ma,
    required this.ten,
  });

  final int id;
  final String ma;
  final String ten;

  factory StoreAdminStoreRow.fromJson(Map<String, dynamic> json) {
    return StoreAdminStoreRow(
      id: JsonUtils.readIntRequired(json['id'], field: 'id'),
      ma: JsonUtils.readString(json['ma']) ?? '',
      ten: JsonUtils.readString(json['ten']) ?? '',
    );
  }

  String get displayLine => '$ma — $ten';
}
