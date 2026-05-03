import '../../../../core/network/json_utils.dart';

/// Backend: `StoreAdminInventoryTransactionHeaderListItemDto`.
class InventoryTransactionHeaderListItem {
  const InventoryTransactionHeaderListItem({
    required this.id,
    required this.donViId,
    required this.transactionType,
    required this.transactionDate,
    required this.note,
    required this.lineCount,
    required this.created,
    required this.createdBy,
    required this.modified,
    required this.modifiedBy,
  });

  final int id;
  final int donViId;
  final int transactionType;
  final DateTime transactionDate;
  final String? note;
  final int lineCount;
  final DateTime created;
  final String? createdBy;
  final DateTime modified;
  final String? modifiedBy;

  factory InventoryTransactionHeaderListItem.fromJson(Map<String, dynamic> json) {
    return InventoryTransactionHeaderListItem(
      id: JsonUtils.readIntRequired(json['id'], field: 'id'),
      donViId: JsonUtils.readIntRequired(json['donViId'], field: 'donViId'),
      transactionType:
          JsonUtils.readIntRequired(json['transactionType'], field: 'transactionType'),
      transactionDate: JsonUtils.readDateTime(json['transactionDate']) ??
          (throw const FormatException('transactionDate')),
      note: JsonUtils.readString(json['note']),
      lineCount: JsonUtils.readInt(json['lineCount']) ?? 0,
      created: JsonUtils.readDateTime(json['created']) ??
          (throw const FormatException('created')),
      createdBy: JsonUtils.readString(json['createdBy']),
      modified: JsonUtils.readDateTime(json['modified']) ??
          (throw const FormatException('modified')),
      modifiedBy: JsonUtils.readString(json['modifiedBy']),
    );
  }

  bool get isImport => transactionType == 1;
}
