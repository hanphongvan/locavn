import 'package:flutter/material.dart';

/// Visual tokens aligned with the portal login reference (light blue, blue–green CTA).
abstract final class LoginScreenTheme {
  static const Color primaryBlue = Color(0xFF0055A5);
  static const Color titleBlue = Color(0xFF0D47A1);
  static const Color gradientStart = Color(0xFF1565C0);
  static const Color gradientEnd = Color(0xFF4CAF50);

  /// Login backdrop: light blue → cyan → light green wash.
  static const Color bgTop = Color(0xFFEFF6FF);
  static const Color bgMid = Color(0xFFECFEFF);
  static const Color bgBottom = Color(0xFFECFDF5);

  /// Soft atmosphere orbs (Tailwind-style blue / cyan / mint).
  static const Color atmosphereBlue = Color(0xFF60A5FA);
  static const Color atmosphereCyan = Color(0xFF22D3EE);
  static const Color atmosphereGreen = Color(0xFF34D399);
  static const Color fieldBorder = Color(0xFFE0E0E0);
  static const double cardRadius = 24;
  static const double controlRadius = 12;
}
