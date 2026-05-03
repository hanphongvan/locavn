import '../../../../core/network/json_utils.dart';

/// Backend: `ReportsSystemInventoryLineDto`
class ReportsSystemInventoryLineDto {
  const ReportsSystemInventoryLineDto({
    required this.productId,
    required this.productCode,
    required this.productName,
    required this.currentQuantity,
    this.unitId,
    this.unitMa,
    this.unitTen,
    this.lastTransactionDate,
  });

  final int productId;
  final String productCode;
  final String productName;
  final double currentQuantity;
  final int? unitId;
  final String? unitMa;
  final String? unitTen;
  final DateTime? lastTransactionDate;

  factory ReportsSystemInventoryLineDto.fromJson(Map<String, dynamic> json) {
    return ReportsSystemInventoryLineDto(
      productId: JsonUtils.readInt(json['productId']) ?? 0,
      productCode: JsonUtils.readString(json['productCode']) ?? '',
      productName: JsonUtils.readString(json['productName']) ?? '',
      currentQuantity: JsonUtils.readDouble(json['currentQuantity']) ?? 0,
      unitId: JsonUtils.readInt(json['unitId']),
      unitMa: JsonUtils.readString(json['unitMa']),
      unitTen: JsonUtils.readString(json['unitTen']),
      lastTransactionDate: JsonUtils.readDateTime(json['lastTransactionDate']),
    );
  }
}
