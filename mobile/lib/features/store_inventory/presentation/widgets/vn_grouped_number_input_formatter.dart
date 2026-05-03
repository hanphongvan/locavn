import 'package:flutter/services.dart';

/// Nhập số kiểu VN: phần nguyên nhóm 3 chữ số bằng dấu `.` (vd. `15.000`), phần thập phân tùy chọn sau dấu `,`.
class VnGroupedNumberInputFormatter extends TextInputFormatter {
  VnGroupedNumberInputFormatter({this.maxFractionDigits = 6});

  final int maxFractionDigits;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }

    var raw = newValue.text.replaceAll('.', '');
    final sb = StringBuffer();
    var hasComma = false;
    for (var i = 0; i < raw.length; i++) {
      final c = raw[i];
      if (c == ',') {
        if (hasComma) {
          continue;
        }
        hasComma = true;
        sb.write(c);
      } else if (c.compareTo('0') >= 0 && c.compareTo('9') <= 0) {
        sb.write(c);
      }
    }
    var s = sb.toString();
    if (s.isEmpty || s == ',') {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }

    String intDigits;
    String? fracDigits;
    final ci = s.indexOf(',');
    if (ci >= 0) {
      intDigits = s.substring(0, ci);
      fracDigits = s.substring(ci + 1);
      if (fracDigits.length > maxFractionDigits) {
        fracDigits = fracDigits.substring(0, maxFractionDigits);
      }
    } else {
      intDigits = s;
      fracDigits = null;
    }

    intDigits = intDigits.replaceAll(RegExp(r'^0+(?=\d)'), '');
    if (intDigits.isEmpty) {
      intDigits = '0';
    }

    final grouped = _groupIntDigits(intDigits);
    final out = fracDigits != null ? '$grouped,$fracDigits' : grouped;
    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }

  static String _groupIntDigits(String digits) {
    if (digits.isEmpty) {
      return '';
    }
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buf.write('.');
      }
      buf.write(digits[i]);
    }
    return buf.toString();
  }
}
