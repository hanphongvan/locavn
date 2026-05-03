import 'dart:math' as math;

import '../../../core/network/json_utils.dart';

/// Safe reads for `decimal` / `double` JSON from `StoreAdminStorePrice*` DTOs.
///
/// Backend sends `price` as JSON number; we reject NaN/Infinity and (optionally) negative values
/// to match server rules (`StoreAdminStorePriceValidator.ValidateUpsert`: Price >= 0).
abstract final class SalePriceJsonParsing {
  /// Parses a price field; returns `null` only when [value] is null or not parseable.
  ///
  /// Throws [FormatException] when the value is finite but **negative** (invalid per API rules).
  static double? readPriceOrNull(Object? value, {String field = 'price'}) {
    if (value == null) return null;
    final d = JsonUtils.readDouble(value);
    if (d == null) return null;
    if (d.isNaN || d.isInfinite) {
      throw FormatException('Expected finite number for $field, got $value');
    }
    if (d < 0) {
      throw FormatException('Price must be >= 0 for $field, got $value');
    }
    return d;
  }

  /// Required price for list/detail DTOs.
  static double readPriceRequired(Object? value, {String field = 'price'}) {
    final d = readPriceOrNull(value, field: field);
    if (d == null) {
      throw FormatException('Expected number for $field, got $value');
    }
    return d;
  }

  /// Validates a price before sending to the API (Angular: `Validators.min(0)`).
  static double assertNonNegativePrice(num value, {String field = 'price'}) {
    final d = value.toDouble();
    if (d.isNaN || d.isInfinite) {
      throw FormatException('Invalid $field: not finite');
    }
    if (d < 0) {
      throw FormatException('Invalid $field: must be >= 0');
    }
    // Avoid silent precision surprises for very large values (defensive).
    if (d.abs() > 1e15) {
      throw FormatException('Invalid $field: magnitude too large');
    }
    return d;
  }

  /// Rounds to at most [maxFractionDigits] (default 2 — Angular `vnGroupedNumberInput` default for prices).
  static double roundPriceForApi(double value, {int maxFractionDigits = 2}) {
    final n = math.max(0, math.min(6, maxFractionDigits));
    final p = math.pow(10, n).toDouble();
    return (value * p).round() / p;
  }
}
