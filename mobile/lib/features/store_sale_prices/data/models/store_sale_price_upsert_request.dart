import '../sale_price_json_parsing.dart';
import 'store_sale_price_effective_date.dart';

/// Backend: `StoreAdminStorePriceUpsertRequest` — `POST` / `PUT /api/admin/store-prices/{id}`.
class StoreSalePriceUpsertRequest {
  const StoreSalePriceUpsertRequest({
    required this.donViId,
    required this.productId,
    required this.price,
    required this.effectiveDate,
    required this.isCurrent,
    this.unitId,
    this.note,
  });

  final int donViId;
  final int productId;
  final double price;
  final int? unitId;
  final DateTime effectiveDate;
  final bool isCurrent;
  final String? note;

  /// JSON keys camelCase — matches Angular `StoreAdminStorePriceUpsertRequest` / ASP.NET defaults.
  Map<String, dynamic> toJson() {
    final p = SalePriceJsonParsing.assertNonNegativePrice(price, field: 'price');
    final trimmed = note?.trim();
    return <String, dynamic>{
      'donViId': donViId,
      'productId': productId,
      'price': p,
      'unitId': unitId,
      'effectiveDate': StoreSalePriceEffectiveDate.toApiWallDateTime(effectiveDate),
      'isCurrent': isCurrent,
      if (trimmed != null && trimmed.isNotEmpty) 'note': trimmed,
    };
  }
}
