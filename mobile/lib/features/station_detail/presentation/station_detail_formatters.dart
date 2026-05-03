import '../../reporting/data/models/reporting_period.dart';

String? stationDetailNonEmpty(String? s) {
  final t = s?.trim();
  if (t == null || t.isEmpty) return null;
  return t;
}

/// `DD/MM/YYYY` for display on detail screen.
String? stationDetailFormatDateDdMmYyyy(DateTime? d) {
  if (d == null) return null;
  final day = d.day.toString().padLeft(2, '0');
  final m = d.month.toString().padLeft(2, '0');
  final y = d.year.toString().padLeft(4, '0');
  return '$day/$m/$y';
}

String stationDetailFormatDateTimeShort(DateTime d) {
  final date = stationDetailFormatDateDdMmYyyy(d) ?? '';
  final h = d.hour.toString().padLeft(2, '0');
  final min = d.minute.toString().padLeft(2, '0');
  return '$date $h:$min';
}

/// Đơn giá làm tròn — `20.000đ` (giống bản đồ).
String stationDetailFormatRoundDong(double v) {
  final n = v.round();
  final s = n.toString();
  final buf = StringBuffer();
  final len = s.length;
  for (var i = 0; i < len; i++) {
    if (i > 0 && (len - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '$bufđ';
}

String stationDetailPeriodLine(ReportingPeriod p) {
  final bits = <String>[];
  final ky = stationDetailNonEmpty(p.kieuKyTen) ?? stationDetailNonEmpty(p.kieuKyMa);
  if (ky != null) bits.add(ky);
  final from = p.tuNgay;
  final to = p.denNgay;
  if (from != null || to != null) {
    bits.add(
      '${from != null ? stationDetailFormatDateDdMmYyyy(from) : '…'} → ${to != null ? stationDetailFormatDateDdMmYyyy(to) : '…'}',
    );
  }
  if (bits.isEmpty) return '';
  return bits.join(' · ');
}
