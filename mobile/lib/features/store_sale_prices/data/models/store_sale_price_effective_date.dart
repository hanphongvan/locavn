/// Serializes **effective date** for store price APIs.
///
/// Angular sends `yyyy-MM-ddTHH:mm:ss` **without** `Z` as "wall clock" for SQL `datetime`
/// (`store-price-form-page.component.ts` → `vnEffectiveDateTimeToIso`; backend
/// [VietnamWallDateTimeJsonConverter]).
///
/// [wallClock] should represent the business instant the user chose (typically **local**
/// device time when the user is in VN, matching Angular `Date(year, month-1, day, h, m)`).
abstract final class StoreSalePriceEffectiveDate {
  static String _pad2(int n) => n.toString().padLeft(2, '0');

  static String toApiWallDateTime(DateTime wallClock) {
    final l = wallClock.toLocal();
    return '${l.year.toString().padLeft(4, '0')}-'
        '${_pad2(l.month)}-'
        '${_pad2(l.day)}T'
        '${_pad2(l.hour)}:'
        '${_pad2(l.minute)}:'
        '${_pad2(l.second)}';
  }
}
