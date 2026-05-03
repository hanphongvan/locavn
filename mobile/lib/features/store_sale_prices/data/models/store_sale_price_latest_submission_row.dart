import '../../../../core/network/json_utils.dart';
import '../sale_price_json_parsing.dart';

/// Backend: `StoreAdminStorePriceLatestSubmissionRowDto` — `GET .../latest-submission?donViId=`.
///
/// Angular uses this for **"Sao chép lần gần nhất"** on the batch form (`copyFromLatest`).
class StoreSalePriceLatestSubmissionRow {
  const StoreSalePriceLatestSubmissionRow({
    required this.productId,
    required this.price,
    required this.unitId,
    required this.note,
    required this.effectiveDate,
    required this.isCurrent,
  });

  final int productId;
  final double price;
  final int? unitId;
  final String? note;
  final DateTime effectiveDate;
  final bool isCurrent;

  factory StoreSalePriceLatestSubmissionRow.fromJson(Map<String, dynamic> json) {
    return StoreSalePriceLatestSubmissionRow(
      productId: JsonUtils.readIntRequired(json['productId'], field: 'productId'),
      price: SalePriceJsonParsing.readPriceRequired(json['price'], field: 'price'),
      unitId: JsonUtils.readInt(json['unitId']),
      note: JsonUtils.readString(json['note']),
      effectiveDate: JsonUtils.readDateTime(json['effectiveDate']) ??
          (throw FormatException('Missing or invalid effectiveDate')),
      isCurrent: JsonUtils.readBool(json['isCurrent']) ??
          (throw FormatException('Missing or invalid isCurrent')),
    );
  }
}
