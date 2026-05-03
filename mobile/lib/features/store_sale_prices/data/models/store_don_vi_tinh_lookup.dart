import '../../../../core/network/json_utils.dart';

/// Backend: `StoreAdminDonViTinhLookupDto` — `GET /api/admin/store-prices/don-vi-tinh` (`DM_DonViTinh`).
class StoreDonViTinhLookup {
  const StoreDonViTinhLookup({
    required this.id,
    required this.ma,
    required this.ten,
  });

  final int id;
  final String? ma;
  final String? ten;

  factory StoreDonViTinhLookup.fromJson(Map<String, dynamic> json) {
    return StoreDonViTinhLookup(
      id: JsonUtils.readIntRequired(json['id'], field: 'id'),
      ma: JsonUtils.readString(json['ma']),
      ten: JsonUtils.readString(json['ten']),
    );
  }
}
