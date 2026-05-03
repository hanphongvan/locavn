import 'package:intl/intl.dart';

/// Display helpers aligned with Angular `store-price-hub-page.component.ts`
/// (`formatEffectiveDateTimeHcm`) and batch default wall clock (`hcmPartsFromDate`).
///
/// Vietnam has no DST; **UTC instant → wall clock in UTC+7** matches
/// `Intl` with `timeZone: 'Asia/Ho_Chi_Minh'` for UTC-valued instants.
/// For API datetimes parsed as **local unspecified** (no `Z`), we use **calendar
/// components as-is** (same as a browser in VN parsing the same naive string).
abstract final class VietnamWallTime {
  static DateTime _shiftedUtcInstant(DateTime utc) => utc.add(const Duration(hours: 7));

  static DateTime _wallForDisplay(DateTime api) {
    if (api.isUtc) {
      final s = _shiftedUtcInstant(api.toUtc());
      return DateTime(s.year, s.month, s.day, s.hour, s.minute, s.second);
    }
    final l = api.toLocal();
    return DateTime(l.year, l.month, l.day, l.hour, l.minute, l.second);
  }

  /// Form **Thêm giá** (batch): `dd/MM/yy HH:mm` — wall time như [_wallForDisplay].
  static String formatBatchEffectivePickerDisplay(DateTime api) {
    final w = _wallForDisplay(api);
    final yy = (w.year % 100).toString().padLeft(2, '0');
    return '${w.day.toString().padLeft(2, '0')}/${w.month.toString().padLeft(2, '0')}/$yy '
        '${w.hour.toString().padLeft(2, '0')}:${w.minute.toString().padLeft(2, '0')}';
  }

  /// Angular hub column **Hiệu lực**: `HH:mm dd/MM/yy` (HCM for UTC-backed instants).
  static String formatEffectiveLikeHub(DateTime api) {
    final w = _wallForDisplay(api);
    final yy = (w.year % 100).toString().padLeft(2, '0');
    return '${w.hour.toString().padLeft(2, '0')}:${w.minute.toString().padLeft(2, '0')} '
        '${w.day.toString().padLeft(2, '0')}/${w.month.toString().padLeft(2, '0')}/$yy';
  }

  /// Angular `vnWallNowEffectiveDisplay` + batch `DateTime` used for API wall encoding.
  /// Uses current instant in Vietnam (+7 from UTC).
  static DateTime batchDefaultEffectiveWallNow() {
    final s = _shiftedUtcInstant(DateTime.now().toUtc());
    return DateTime(s.year, s.month, s.day, s.hour, s.minute, s.second);
  }

  /// Angular `productLabel`: map value is `` ` ${p.name}` `` (leading space + name).
  static String hubProductLabel(String name) => ' $name';

  /// Angular `number: '1.2-2'` for price cells.
  static String formatPriceAngular(num price) {
    return NumberFormat('#,##0.00', 'vi').format(price);
  }

  /// Hub header "today" line — calendar date in Vietnam wall time (same instant basis as batch default).
  ///
  /// Implemented without `DateFormat(..., 'vi')` so we do not require
  /// `initializeDateFormatting('vi')` at app startup (avoids [UninitializedLocaleData]).
  static String formatHubTodayHeadingVi() {
    final w = batchDefaultEffectiveWallNow();
    const weekdays = <String>[
      'Thứ hai',
      'Thứ ba',
      'Thứ tư',
      'Thứ năm',
      'Thứ sáu',
      'Thứ bảy',
      'Chủ nhật',
    ];
    final dayName = weekdays[w.weekday - 1];
    return '$dayName, ${w.day} tháng ${w.month} năm ${w.year}';
  }
}
