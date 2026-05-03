import '../../../../core/network/json_utils.dart';

/// Backend: `StoreAdminInventoryCurrentLineDto`.
class InventoryCurrentLine {
  const InventoryCurrentLine({
    required this.donViId,
    required this.productId,
    required this.currentQuantity,
    required this.productCode,
    required this.productName,
    required this.unitId,
    required this.unitMa,
    required this.unitTen,
    required this.lastTransactionDate,
  });

  final int donViId;
  final int productId;
  final double currentQuantity;
  final String productCode;
  final String productName;
  final int? unitId;
  final String? unitMa;
  final String? unitTen;
  final DateTime lastTransactionDate;

  factory InventoryCurrentLine.fromJson(Map<String, dynamic> json) {
    return InventoryCurrentLine(
      donViId: JsonUtils.readIntRequired(json['donViId'], field: 'donViId'),
      productId: JsonUtils.readIntRequired(json['productId'], field: 'productId'),
      currentQuantity:
          JsonUtils.readDoubleRequired(json['currentQuantity'], field: 'currentQuantity'),
      productCode: JsonUtils.readString(json['productCode']) ?? '',
      productName: JsonUtils.readString(json['productName']) ?? '',
      unitId: JsonUtils.readInt(json['unitId']),
      unitMa: JsonUtils.readString(json['unitMa']),
      unitTen: JsonUtils.readString(json['unitTen']),
      lastTransactionDate: JsonUtils.readDateTime(json['lastTransactionDate']) ??
          (throw const FormatException('lastTransactionDate')),
    );
  }
}
