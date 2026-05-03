import '../../../../core/network/json_utils.dart';

/// Backend: `Httm.XangDau.Api.Shared.Reporting.ReportingPeriodDto`
class ReportingPeriod {
  const ReportingPeriod({
    this.kieuKyBaoCaoId,
    this.kieuKyMa,
    this.kieuKyTen,
    this.tuNgay,
    this.denNgay,
  });

  final int? kieuKyBaoCaoId;
  final String? kieuKyMa;
  final String? kieuKyTen;
  final DateTime? tuNgay;
  final DateTime? denNgay;

  factory ReportingPeriod.fromJson(Map<String, dynamic> json) {
    return ReportingPeriod(
      kieuKyBaoCaoId: JsonUtils.readInt(json['kieuKyBaoCaoId']),
      kieuKyMa: JsonUtils.readString(json['kieuKyMa']),
      kieuKyTen: JsonUtils.readString(json['kieuKyTen']),
      tuNgay: JsonUtils.readDateOnly(json['tuNgay']),
      denNgay: JsonUtils.readDateOnly(json['denNgay']),
    );
  }

  static ReportingPeriod? parseNullable(Object? json) {
    final m = JsonUtils.readMap(json);
    if (m == null) return null;
    return ReportingPeriod.fromJson(m);
  }
}
