/// Phần số VND làm tròn nguyên, nhóm nghìn bằng dấu `.` (vd. 24867 → `24.867`).
String formatVndIntegerDigits(double? value) {
  if (value == null) return '—';
  final n = value.round();
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) {
      buf.write('.');
    }
    buf.write(s[i]);
  }
  return buf.toString();
}

/// Integer VND display (thousands with `.`) — used for API-backed prices only.
String formatVndCurrency(double? value) {
  if (value == null) return '—';
  return '${formatVndIntegerDigits(value)} đ';
}
