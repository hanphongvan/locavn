import 'package:flutter/material.dart';

/// LocaVN / government-grade dashboard palette (UI only).
/// Aligns with [AppTheme] seed `Color(0xFF1F3C93)` — dùng chung Citizen / Lãnh đạo.
abstract final class LocaDashboardTokens {
  static const Color primaryBlue = Color(0xFF1F3C93);
  static const Color accentGreen = Color(0xFF35D66B);
  static const Color background = Color(0xFFF5FAFF);
  static const Color textPrimary = Color(0xFF0B3A7A);
  static const Color textSecondary = Color(0xFF6B7897);
  static const Color warningBg = Color(0xFFFFF4E5);

  static const Color cardWhite = Colors.white;
  static const Color gradientTop = Color(0xFFE8F4FF);
  static const Color gradientMid = Color(0xFFF5FAFF);

  static const double radiusLg = 20;
  static const double radiusMd = 16;
  static const double radiusSm = 14;
  static const double radiusPill = 50;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 16);

  static List<BoxShadow> cardShadow(BuildContext context) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];
}
