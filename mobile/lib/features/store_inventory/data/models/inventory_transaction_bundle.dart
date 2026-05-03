import '../../../../core/network/json_utils.dart';
import 'inventory_transaction_line.dart';

/// Backend: `StoreAdminInventoryTransactionBundleDto`.
class InventoryTransactionBundle {
  const InventoryTransactionBundle({
    required this.id,
    required this.donViId,
    required this.transactionType,
    required this.transactionDate,
    required this.note,
    required this.created,
    required this.createdBy,
    required this.modified,
    required this.modifiedBy,
    required this.details,
  });

  final int id;
  final int donViId;
  final int transactionType;
  final DateTime transactionDate;
  final String? note;
  final DateTime created;
  final String? createdBy;
  final DateTime modified;
  final String? modifiedBy;
  final List<InventoryTransactionLine> details;

  factory InventoryTransactionBundle.fromJson(Map<String, dynamic> json) {
    // Skip-null pattern: 1 entry hỏng trong list không nên phá toàn bộ parse.
    // Trước đây dùng `?? {}` truyền map rỗng → fromJson throw FormatException
    // do thiếu required field, fail toàn list. Pattern này nhất quán với
    // MyBadReportPage.fromJson + ReportsOverviewDto.fromJson + StationReviewsPageDto.fromJson.
    final details = <InventoryTransactionLine>[];
    final rawDetails = JsonUtils.readList(json['details']);
    if (rawDetails != null) {
      for (final e in rawDetails) {
        final m = JsonUtils.readMap(e);
        if (m != null) details.add(InventoryTransactionLine.fromJson(m));
      }
    }

    return InventoryTransactionBundle(
      id: JsonUtils.readIntRequired(json['id'], field: 'id'),
      donViId: JsonUtils.readIntRequired(json['donViId'], field: 'donViId'),
      transactionType:
          JsonUtils.readIntRequired(json['transactionType'], field: 'transactionType'),
      transactionDate: JsonUtils.readDateTime(json['transactionDate']) ??
          (throw const FormatException('transactionDate')),
      note: JsonUtils.readString(json['note']),
      created: JsonUtils.readDateTime(json['created']) ??
          (throw const FormatException('created')),
      createdBy: JsonUtils.readString(json['createdBy']),
      modified: JsonUtils.readDateTime(json['modified']) ??
          (throw const FormatException('modified')),
      modifiedBy: JsonUtils.readString(json['modifiedBy']),
      details: details,
    );
  }

  double get totalAmount =>
      details.fold<double>(0, (s, d) => s + (d.amount ?? 0));
}
