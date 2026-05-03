import 'dart:math' as math;

/// Parse money-style input aligned with Angular `parseVnNumber` / `VnGroupedNumberInputDirective`
/// (`.` thousands, `,` decimal, max [maxFractionDigits]).
double? parseVnDecimalInput(String raw, {int maxFractionDigits = 2}) {
  final maxDec = math.max(0, math.min(6, maxFractionDigits));
  final t = raw.trim();
  if (t.isEmpty || t == ',' || t == '.') {
    return null;
  }
  final lastComma = t.lastIndexOf(',');
  if (lastComma >= 0) {
    final intRaw = t.substring(0, lastComma).replaceAll('.', '').replaceAll(RegExp(r'\D'), '');
    var decRaw = t.substring(lastComma + 1).replaceAll(RegExp(r'\D'), '');
    if (decRaw.length > maxDec) {
      decRaw = decRaw.substring(0, maxDec);
    }
    if (intRaw.isEmpty && decRaw.isEmpty) {
      return null;
    }
    final s = intRaw.isEmpty ? '0.$decRaw' : '$intRaw.$decRaw';
    final n = double.tryParse(s);
    return n != null && n.isFinite ? n : null;
  }
  final digits = t.replaceAll('.', '').replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) {
    return null;
  }
  final n = double.tryParse(digits);
  return n != null && n.isFinite ? n : null;
}

/// Display helper (optional grouping) — lightweight vs full `intl` currency.
String formatVnPriceDisplay(double value, {int maxFractionDigits = 2}) {
  final parts = value.toStringAsFixed(maxFractionDigits).split('.');
  final intPart = parts[0];
  final rev = intPart.split('').reversed.join();
  final groupedRev = StringBuffer();
  for (var i = 0; i < rev.length; i++) {
    if (i > 0 && i % 3 == 0) {
      groupedRev.write('.');
    }
    groupedRev.write(rev[i]);
  }
  final groupedInt = groupedRev.toString().split('').reversed.join();
  if (maxFractionDigits <= 0 || parts.length < 2) {
    return groupedInt;
  }
  final dec = parts[1].replaceAll(RegExp(r'0+$'), '');
  if (dec.isEmpty) {
    return groupedInt;
  }
  return '$groupedInt,$dec';
}
