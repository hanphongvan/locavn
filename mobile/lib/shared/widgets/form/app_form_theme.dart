import 'package:flutter/material.dart';

/// Tokens for citizen form surfaces (add vehicle, etc.) — aligned with login + task spec.
abstract final class AppFormTheme {
  static const Color border = Color(0xFFE5E7EB);
  static const Color focusBorder = Color(0xFF1D4ED8);
  static const Color labelColor = Color(0xFF111827);
  static const Color hintColor = Color(0xFF6B7280);
  static const double fieldRadius = 14;
  static const double cardRadius = 22;
  static const EdgeInsets fieldPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 16);

  static List<BoxShadow> get focusShadow => [
        BoxShadow(
          color: focusBorder.withValues(alpha: 0.18),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];

  static OutlineInputBorder outlineBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(fieldRadius),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
