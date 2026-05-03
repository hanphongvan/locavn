/// Thrown when the signed-in user is not **Store** (`Loai == 4`) or lacks data needed for sale prices.
///
/// Parity: Angular `RETAIL_PORTAL_ROLES` allows Admin/Trader too, but this Flutter feature is
/// intentionally scoped to **Store** only per product requirements.
final class StoreSalePricesAccessException implements Exception {
  StoreSalePricesAccessException(this.message);

  final String message;

  @override
  String toString() => 'StoreSalePricesAccessException: $message';
}

/// Session / local identity is missing or inconsistent for store sale price APIs.
///
/// Example: `Loai == 4` but `donViId` is null — Angular batch form shows an error and blocks save
/// (`store-price-form-page.component.ts`: "Tài khoản chưa gắn DonViId").
final class StoreSalePricesSessionException implements Exception {
  StoreSalePricesSessionException(this.message);

  final String message;

  @override
  String toString() => 'StoreSalePricesSessionException: $message';
}
