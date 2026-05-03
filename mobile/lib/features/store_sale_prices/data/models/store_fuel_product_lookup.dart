import '../../../../core/network/json_utils.dart';

/// Backend: `StoreAdminFuelProductLookupDto` — `GET /api/admin/store-prices/products`.
class StoreFuelProductLookup {
  const StoreFuelProductLookup({
    required this.id,
    required this.code,
    required this.name,
    required this.unitId,
    required this.sortOrder,
  });

  final int id;
  final String code;
  final String name;
  final int? unitId;
  final int? sortOrder;

  factory StoreFuelProductLookup.fromJson(Map<String, dynamic> json) {
    return StoreFuelProductLookup(
      id: JsonUtils.readIntRequired(json['id'], field: 'id'),
      code: JsonUtils.readString(json['code']) ?? '',
      name: JsonUtils.readString(json['name']) ?? '',
      unitId: JsonUtils.readInt(json['unitId']),
      sortOrder: JsonUtils.readInt(json['sortOrder']),
    );
  }
}
