import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Màu chủ đạo màn Quỹ bình ổn (theo spec).
const Color kStabilizationFundPrimary = Color(0xFF1F3C93);

/// Định dạng tiền VND cho màn Quỹ bình ổn (tỷ đồng khi lớn).
String formatStabilizationFundMoney(double? value) {
  if (value == null) return '—';
  final v = value;
  final sign = v < 0 ? '−' : '';
  final x = v.abs();
  if (x >= 1e9) {
    final t = x / 1e9;
    final s = NumberFormat.decimalPattern('vi').format(t);
    return '$sign$s tỷ đồng';
  }
  final n = NumberFormat.decimalPattern('vi');
  return '$sign${n.format(x)} đ';
}

String formatSignedStabilizationMoney(double? value) {
  if (value == null) return '—';
  if (value > 0) return '+${formatStabilizationFundMoney(value)}';
  return formatStabilizationFundMoney(value);
}
