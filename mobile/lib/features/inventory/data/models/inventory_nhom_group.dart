import '../../../../core/network/json_utils.dart';

/// Backend: `InventoryNhomGroupDto`
class InventoryNhomGroup {
  const InventoryNhomGroup({
    this.nhom,
    required this.lineCount,
    this.sumSo01,
  });

  final int? nhom;
  final int lineCount;
  final double? sumSo01;

  factory InventoryNhomGroup.fromJson(Map<String, dynamic> json) {
    return InventoryNhomGroup(
      nhom: JsonUtils.readInt(json['nhom']),
      lineCount: JsonUtils.readInt(json['lineCount']) ?? 0,
      sumSo01: JsonUtils.readDouble(json['sumSo01']),
    );
  }
}
