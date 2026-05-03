import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final seed = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1F3C93),
      brightness: Brightness.light,
    );
    return ThemeData(
      colorScheme: seed,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: seed.surface,
        foregroundColor: seed.onSurface,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: seed.primaryContainer,
      ),
    );
  }
}
