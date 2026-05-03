import 'package:flutter/material.dart';

import '../../data/leader_analytics_dtos.dart';

extension LeaderAnalyticsSeriesColor on LeaderAnalyticsSeriesDto {
  Color get colorValue => _parseHexColor(color);
}

Color _parseHexColor(String hex) {
  var h = hex.trim();
  if (h.startsWith('#')) h = h.substring(1);
  if (h.length == 6) h = 'FF$h';
  if (h.length != 8) return const Color(0xFF2563EB);
  return Color(int.parse(h, radix: 16));
}
