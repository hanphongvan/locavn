import '../../../../core/network/json_utils.dart';

/// Backend: `FuelProductLeafDto` — lá của cây `FuelProducts` (catalog mở rộng được
/// bởi seeder/admin). [parentCode] giúp client gom theo nhánh `XANG`/`DAU`/... nếu cần.
class FuelProductLeaf {
  const FuelProductLeaf({
    required this.code,
    required this.name,
    required this.sortOrder,
    this.parentCode,
  });

  final String code;
  final String name;
  final String? parentCode;
  final int sortOrder;

  factory FuelProductLeaf.fromJson(Map<String, dynamic> json) {
    return FuelProductLeaf(
      code: JsonUtils.readString(json['code']) ?? '',
      name: JsonUtils.readString(json['name']) ?? '',
      parentCode: JsonUtils.readString(json['parentCode']),
      sortOrder: JsonUtils.readInt(json['sortOrder']) ?? 0,
    );
  }
}
