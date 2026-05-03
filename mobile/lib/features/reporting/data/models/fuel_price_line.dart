import '../../../../core/network/json_utils.dart';

/// Backend: `FuelPriceLineDto`
class FuelPriceLine {
  const FuelPriceLine({
    required this.stationId,
    this.stationName,
    required this.thongKeId,
    required this.lineId,
    this.maSo,
    this.tenThongKe,
    this.loaiGia,
    this.thoiDiemDinhGia,
    this.so01,
    this.so02,
    this.so03,
  });

  final int stationId;
  final String? stationName;
  final String thongKeId;
  final String lineId;
  final String? maSo;
  final String? tenThongKe;
  final int? loaiGia;
  final DateTime? thoiDiemDinhGia;
  final double? so01;
  final double? so02;
  final double? so03;

  factory FuelPriceLine.fromJson(Map<String, dynamic> json) {
    return FuelPriceLine(
      stationId: JsonUtils.readIntRequired(json['stationId'], field: 'stationId'),
      stationName: JsonUtils.readString(json['stationName']),
      thongKeId: JsonUtils.readStringRequired(json['thongKeId'], field: 'thongKeId'),
      lineId: JsonUtils.readStringRequired(json['lineId'], field: 'lineId'),
      maSo: JsonUtils.readString(json['maSo']),
      tenThongKe: JsonUtils.readString(json['tenThongKe']),
      loaiGia: JsonUtils.readInt(json['loaiGia']),
      thoiDiemDinhGia: JsonUtils.readDateTime(json['thoiDiemDinhGia']),
      so01: JsonUtils.readDouble(json['so01']),
      so02: JsonUtils.readDouble(json['so02']),
      so03: JsonUtils.readDouble(json['so03']),
    );
  }
}
