import 'package:flutter/material.dart';

/// Design tokens for Store "Giá bán" flows — aligned with [LoginScreenTheme] / dashboard feel.
abstract final class StorePriceDesignTokens {
  static const Color borderGray = Color(0xFFE5E7EB);
  static const Color focusBlue = Color(0xFF1D4ED8);
  static const Color priceBlue = Color(0xFF1D4ED8);
  static const Color badgeGreen = Color(0xFF16A34A);
  static const double cardRadius = 18;
  static const double inputRadius = 14;
  static const double sheetCardRadius = 20;
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 18);

  static List<Color> get primaryGradient => const [
        Color(0xFF1565C0),
        Color(0xFF0EA5E9),
        Color(0xFF22C55E),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];

  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    bool hasError = false,
  }) {
    final borderSide = BorderSide(color: hasError ? Colors.red.shade700 : borderGray);
    final focusBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(inputRadius),
      borderSide: const BorderSide(color: focusBlue, width: 1.5),
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: borderSide,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: borderSide,
      ),
      focusedBorder: focusBorder,
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: BorderSide(color: Colors.red.shade700),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
      ),
    );
  }
}
