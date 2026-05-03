import 'package:flutter/material.dart';

/// Map + shell tokens aligned with login / modern mobile spec.
abstract final class MapScreenPalette {
  static const Color primaryBlue = Color(0xFF1D4ED8);
  static const Color cyan = Color(0xFF06B6D4);
  static const Color green = Color(0xFF34D399);
  static const Color screenBackground = Color(0xFFF4F8FB);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color chipInactiveBorder = Color(0xFFE2E8F0);

  /// Bộ lọc bản đồ (bottom sheet) — đồng bộ spec #F5FAFF / #0F4C9A / #35D66B.
  static const Color filterSheetBackground = Color(0xFFF5FAFF);
  static const Color filterPrimary = Color(0xFF0F4C9A);
  static const Color filterAccent = Color(0xFF35D66B);
  static const Color filterChipSelectedBg = Color(0xFFE8F4FC);
  static const Color filterChipSelectedBorder = Color(0xFF0F4C9A);
  static const Color filterChipSelectedText = Color(0xFF0F4C9A);
  static const Color filterChipBorder = Color(0xFFD1D5DB);
  static const Color filterTextPrimary = Color(0xFF0F172A);
  static const Color filterTextSecondary = Color(0xFF64748B);
  static const Color filterClearAction = Color(0xFFE57373);
  static const double radiusLg = 20;
  static const double radiusMd = 16;
  static const double radiusSm = 12;

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
}
