/// Defensive JSON reads for System.Text.Json camelCase payloads (no extra fields assumed).
abstract final class JsonUtils {
  static Map<String, dynamic>? readMap(Object? value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return null;
  }

  static List<dynamic>? readList(Object? value) {
    if (value == null) return null;
    if (value is List) return value;
    return null;
  }

  static int? readInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static int readIntRequired(Object? value, {String field = 'value'}) {
    final i = readInt(value);
    if (i == null) {
      throw FormatException('Expected int for $field, got $value');
    }
    return i;
  }

  static double? readDouble(Object? value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static double readDoubleRequired(Object? value, {String field = 'value'}) {
    final d = readDouble(value);
    if (d == null) {
      throw FormatException('Expected double for $field, got $value');
    }
    return d;
  }

  static String? readString(Object? value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  static String readStringRequired(Object? value, {String field = 'value'}) {
    final s = readString(value);
    if (s == null || s.isEmpty) {
      throw FormatException('Expected non-empty string for $field, got $value');
    }
    return s;
  }

  static bool? readBool(Object? value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    return null;
  }

  /// ISO 8601 or .NET default date-time JSON.
  static DateTime? readDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// `DateOnly` from API is typically a `"yyyy-MM-dd"` string.
  static DateTime? readDateOnly(Object? value) => readDateTime(value);
}
