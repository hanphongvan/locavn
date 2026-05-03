import '../../../../core/network/json_utils.dart';

/// Backend: `FuelStockLineDto`
class FuelStockLine {
  const FuelStockLine({
    required this.lineId,
    this.maSo,
    this.tenThongKe,
    this.nhom,
    this.so01,
    this.so02,
    this.so03,
  });

  final String lineId;
  final String? maSo;
  final String? tenThongKe;
  final int? nhom;
  final double? so01;
  final double? so02;
  final double? so03;

  factory FuelStockLine.fromJson(Map<String, dynamic> json) {
    return FuelStockLine(
      lineId: JsonUtils.readStringRequired(json['lineId'], field: 'lineId'),
      maSo: JsonUtils.readString(json['maSo']),
      tenThongKe: JsonUtils.readString(json['tenThongKe']),
      nhom: JsonUtils.readInt(json['nhom']),
      so01: JsonUtils.readDouble(json['so01']),
      so02: JsonUtils.readDouble(json['so02']),
      so03: JsonUtils.readDouble(json['so03']),
    );
  }
}
