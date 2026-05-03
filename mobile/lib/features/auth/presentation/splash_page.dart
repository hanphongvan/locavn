import 'package:flutter/material.dart';

/// Bootstrap session restore — nền trùng native splash (`assets/banner/splash.jpg`) để không nháy trắng.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  /// Nền dự phòng khi decode ảnh (gần tông splash xanh nhạt).
  static const Color _fallbackBg = Color(0xFFE8F2FC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fallbackBg,
      body: SizedBox.expand(
        child: Image.asset(
          'assets/banner/splash.jpg',
          fit: BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
