import 'package:flutter/material.dart';

/// Design tokens for **Xe của tôi** (premium reference).
abstract final class MyVehiclesPalette {
  static const Color background = Color(0xFFF5F8FF);
  static const Color primary = Color(0xFF1F3C93);
  static const Color accentBlue = Color(0xFF1677FF);
  static const Color accentGreen = Color(0xFF32D074);
  static const Color navy = Color(0xFF102A5C);
  static const Color muted = Color(0xFF667085);
  static const Color borderSoft = Color(0xFFBFD6FF);
  static const Color cardWhite = Colors.white;
  static const Color cardTint = Color(0xFFF8FAFF);

  static const double radiusLg = 20;
  static const double radiusMd = 18;
  static const double radiusSm = 14;

  /// Header decorative gradient (very light blue).
  static const LinearGradient headerBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8F0FF), Color(0xFFF5F8FF)],
  );

  static const LinearGradient addButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [accentBlue, accentGreen],
  );

  static List<BoxShadow> cardShadow(BuildContext context, {double blur = 20, double y = 8}) => [
        BoxShadow(
          color: const Color(0xFF1F3C93).withValues(alpha: 0.07),
          blurRadius: blur,
          offset: Offset(0, y),
        ),
      ];
}
