import '../../../../core/network/json_utils.dart';
import '../sale_price_json_parsing.dart';

/// Backend: `StoreAdminStorePriceDetailDto` — `GET /api/admin/store-prices/{id}`.
class StoreSalePriceDetail {
  const StoreSalePriceDetail({
    required this.id,
    required this.donViId,
    required this.productId,
    required this.price,
    required this.unitId,
    required this.effectiveDate,
    required this.isCurrent,
    required this.note,
    required this.stationPricesId,
    required this.created,
    required this.createdBy,
    required this.modified,
    required this.modifiedBy,
  });

  final int id;
  final int donViId;
  final int productId;
  final double price;
  final int? unitId;
  final DateTime effectiveDate;
  final bool isCurrent;
  final String? note;
  final int stationPricesId;
  final DateTime created;
  final String? createdBy;
  final DateTime modified;
  final String? modifiedBy;

  factory StoreSalePriceDetail.fromJson(Map<String, dynamic> json) {
    return StoreSalePriceDetail(
      id: JsonUtils.readIntRequired(json['id'], field: 'id'),
      donViId: JsonUtils.readIntRequired(json['donViId'], field: 'donViId'),
      productId: JsonUtils.readIntRequired(json['productId'], field: 'productId'),
      price: SalePriceJsonParsing.readPriceRequired(json['price'], field: 'price'),
      unitId: JsonUtils.readInt(json['unitId']),
      effectiveDate: JsonUtils.readDateTime(json['effectiveDate']) ??
          (throw FormatException('Missing or invalid effectiveDate')),
      isCurrent: JsonUtils.readBool(json['isCurrent']) ??
          (throw FormatException('Missing or invalid isCurrent')),
      note: JsonUtils.readString(json['note']),
      stationPricesId:
          JsonUtils.readIntRequired(json['stationPricesId'], field: 'stationPricesId'),
      created: JsonUtils.readDateTime(json['created']) ??
          (throw FormatException('Missing or invalid created')),
      createdBy: JsonUtils.readString(json['createdBy']),
      modified: JsonUtils.readDateTime(json['modified']) ??
          (throw FormatException('Missing or invalid modified')),
      modifiedBy: JsonUtils.readString(json['modifiedBy']),
    );
  }
}
