import '../../../../core/network/json_utils.dart';

/// Backend: `StoreAdminInventoryTransactionLineDto`.
class InventoryTransactionLine {
  const InventoryTransactionLine({
    required this.id,
    required this.headerId,
    required this.productId,
    required this.unitId,
    required this.unitName,
    required this.quantity,
    required this.amount,
    required this.note,
  });

  final int id;
  final int headerId;
  final int productId;
  final int unitId;
  final String? unitName;
  final double quantity;
  final double? amount;
  final String? note;

  factory InventoryTransactionLine.fromJson(Map<String, dynamic> json) {
    return InventoryTransactionLine(
      id: JsonUtils.readIntRequired(json['id'], field: 'id'),
      headerId: JsonUtils.readIntRequired(json['headerId'], field: 'headerId'),
      productId: JsonUtils.readIntRequired(json['productId'], field: 'productId'),
      unitId: JsonUtils.readIntRequired(json['unitId'], field: 'unitId'),
      unitName: JsonUtils.readString(json['unitName']),
      quantity: JsonUtils.readDoubleRequired(json['quantity'], field: 'quantity'),
      amount: JsonUtils.readDouble(json['amount']),
      note: JsonUtils.readString(json['note']),
    );
  }
}
