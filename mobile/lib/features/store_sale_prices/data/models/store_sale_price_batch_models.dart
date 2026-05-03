import '../sale_price_json_parsing.dart';
import 'store_sale_price_effective_date.dart';

/// Backend: `StoreAdminStorePriceBatchRowRequest`.
class StoreSalePriceBatchRowRequest {
  const StoreSalePriceBatchRowRequest({
    required this.productId,
    required this.price,
    this.unitId,
    this.note,
  });

  final int productId;
  final double price;
  final int? unitId;
  final String? note;

  /// Mirrors Angular `submitBatch` row mapping (`strOrNull` / `parseNullableInt`):
  /// always sends `unitId` and `note` keys so the wire shape matches `StoreAdminStorePriceBatchRowRequest`.
  Map<String, dynamic> toJson() {
    final p = SalePriceJsonParsing.assertNonNegativePrice(price, field: 'price');
    final trimmed = note?.trim();
    return <String, dynamic>{
      'productId': productId,
      'price': p,
      'unitId': unitId,
      'note': trimmed == null || trimmed.isEmpty ? null : trimmed,
    };
  }
}

/// Backend: `StoreAdminStorePriceBatchCreateRequest` — `POST /api/admin/store-prices/batch`.
///
/// Server enforces **1–50** rows, unique `productId`, each price >= 0 (`StoreAdminStorePriceService.ValidateBatch`).
class StoreSalePriceBatchCreateRequest {
  const StoreSalePriceBatchCreateRequest({
    required this.donViId,
    required this.effectiveDate,
    required this.isCurrent,
    required this.rows,
  });

  final int donViId;
  final DateTime effectiveDate;
  final bool isCurrent;
  final List<StoreSalePriceBatchRowRequest> rows;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'donViId': donViId,
        'effectiveDate': StoreSalePriceEffectiveDate.toApiWallDateTime(effectiveDate),
        'isCurrent': isCurrent,
        'rows': rows.map((e) => e.toJson()).toList(),
      };
}

/// Backend: `StoreAdminStorePriceBatchCreateResponseDto`.
class StoreSalePriceBatchCreateResponse {
  const StoreSalePriceBatchCreateResponse({
    required this.stationPricesId,
    required this.createdIds,
    required this.rowCount,
  });

  final int stationPricesId;
  final List<int> createdIds;
  final int rowCount;

  factory StoreSalePriceBatchCreateResponse.fromJson(Map<String, dynamic> json) {
    final rawIds = json['createdIds'];
    final ids = <int>[];
    if (rawIds is List) {
      for (final e in rawIds) {
        final i = switch (e) {
          int v => v,
          num v => v.toInt(),
          String v => int.tryParse(v),
          _ => null,
        };
        if (i != null) ids.add(i);
      }
    }
    return StoreSalePriceBatchCreateResponse(
      stationPricesId: switch (json['stationPricesId']) {
        int v => v,
        num v => v.toInt(),
        String v => int.parse(v),
        _ => throw const FormatException('Invalid stationPricesId'),
      },
      createdIds: ids,
      rowCount: switch (json['rowCount']) {
        int v => v,
        num v => v.toInt(),
        String v => int.tryParse(v) ?? ids.length,
        _ => ids.length,
      },
    );
  }
}
