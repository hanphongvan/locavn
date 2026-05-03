import 'package:flutter/material.dart';

/// Tokens for the station rate / review compose flow (spec).
abstract final class StationReviewComposeTheme {
  static const Color background = Color(0xFFF5FAFF);
  static const Color primary = Color(0xFF0F4C9A);
  static const Color accent = Color(0xFF35D66B);
  static const Color textPrimary = Color(0xFF0B3A7A);
  static const Color textSecondary = Color(0xFF6B7897);
  static const Color starSelected = Color(0xFFFFB82E);
  static const Color starUnselected = Color(0xFFD1D5DB);
  static const Color cardBorder = Color(0xFFE8EEF5);
  static const Color inputBorder = Color(0xFFD8DEE8);
  static const Color uploadFill = Color(0xFFF0F6FC);

  static const LinearGradient submitGradient = LinearGradient(
    colors: [primary, accent],
  );

  /// Top-left → white (screen background gradient).
  static const LinearGradient screenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE3EEF9),
      Color(0xFFF5FAFF),
      Color(0xFFFFFFFF),
    ],
    stops: [0.0, 0.45, 1.0],
  );

  static const double cardRadius = 20;
  static const double cardRadiusMd = 16;
  static const double inputRadius = 14;
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x140F4C9A),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
}
