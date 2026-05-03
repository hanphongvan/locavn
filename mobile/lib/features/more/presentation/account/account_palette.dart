import 'package:flutter/material.dart';

/// Token giao diện tab Tài khoản (đồng bộ Nhiên liệu / bản đồ).
abstract final class AccountPalette {
  static const Color primaryBlue = Color(0xFF0F4C9A);
  static const Color textPrimary = Color(0xFF0B3A7A);
  static const Color textSecondary = Color(0xFF6B7897);
  static const Color accentGreen = Color(0xFF35D66B);
  static const Color background = Color(0xFFF5FAFF);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE6EEF8);

  static const double radiusLg = 20;
  static const double radiusMd = 18;

  static List<BoxShadow> cardShadow(BuildContext context) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}
