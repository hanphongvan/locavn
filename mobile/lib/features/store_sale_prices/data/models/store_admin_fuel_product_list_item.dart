import '../../../../core/network/json_utils.dart';

/// Backend: `StoreAdminFuelProductListItemDto` — `GET /api/admin/fuel-products` (hub filter).
class StoreAdminFuelProductListItem {
  const StoreAdminFuelProductListItem({
    required this.id,
    required this.code,
    required this.name,
    required this.parentId,
    required this.unitId,
    required this.isActive,
    required this.sortOrder,
    required this.description,
  });

  final int id;
  final String code;
  final String name;
  final int? parentId;
  final int? unitId;
  final bool isActive;
  final int? sortOrder;
  final String? description;

  factory StoreAdminFuelProductListItem.fromJson(Map<String, dynamic> json) {
    return StoreAdminFuelProductListItem(
      id: JsonUtils.readIntRequired(json['id'], field: 'id'),
      code: JsonUtils.readString(json['code']) ?? '',
      name: JsonUtils.readString(json['name']) ?? '',
      parentId: JsonUtils.readInt(json['parentId']),
      unitId: JsonUtils.readInt(json['unitId']),
      isActive: JsonUtils.readBool(json['isActive']) ?? false,
      sortOrder: JsonUtils.readInt(json['sortOrder']),
      description: JsonUtils.readString(json['description']),
    );
  }
}
