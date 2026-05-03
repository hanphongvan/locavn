import 'package:flutter/material.dart';

import 'login_screen_theme.dart';

/// Lightweight vector-style footer art (no raster assets).
class LoginBottomIllustration extends StatelessWidget {
  const LoginBottomIllustration({super.key, this.height = 100});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _StationSilhouettePainter(),
      ),
    );
  }
}

class _StationSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final baseY = h * 0.72;

    final canopy = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          LoginScreenTheme.gradientStart.withValues(alpha: 0.35),
          LoginScreenTheme.gradientStart.withValues(alpha: 0.08),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final pillar = Paint()
      ..color = LoginScreenTheme.primaryBlue.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final road = Paint()
      ..color = LoginScreenTheme.titleBlue.withValues(alpha: 0.08);

    // Road
    canvas.drawRect(Rect.fromLTWH(0, baseY + 8, w, h), road);

    // Canopy
    final canopyPath = Path()
      ..moveTo(w * 0.12, baseY)
      ..lineTo(w * 0.88, baseY)
      ..lineTo(w * 0.82, baseY - h * 0.35)
      ..lineTo(w * 0.18, baseY - h * 0.35)
      ..close();
    canvas.drawPath(canopyPath, canopy);

    // Pillars
    canvas.drawRect(Rect.fromLTWH(w * 0.22, baseY - h * 0.32, w * 0.05, h * 0.36), pillar);
    canvas.drawRect(Rect.fromLTWH(w * 0.73, baseY - h * 0.32, w * 0.05, h * 0.36), pillar);

    // Pump block
    final pump = Paint()..color = LoginScreenTheme.gradientEnd.withValues(alpha: 0.35);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.42, baseY - h * 0.22, w * 0.14, h * 0.26),
        const Radius.circular(6),
      ),
      pump,
    );

    // Car silhouette
    final car = Paint()..color = LoginScreenTheme.titleBlue.withValues(alpha: 0.22);
    final carPath = Path()
      ..moveTo(w * 0.52, baseY + 2)
      ..lineTo(w * 0.78, baseY + 2)
      ..lineTo(w * 0.82, baseY - h * 0.08)
      ..lineTo(w * 0.5, baseY - h * 0.08)
      ..quadraticBezierTo(w * 0.44, baseY - h * 0.12, w * 0.4, baseY + 2)
      ..close();
    canvas.drawPath(carPath, car);

    // Fade into background
    final fade = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          LoginScreenTheme.bgBottom,
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.35, w, h * 0.65));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.35, w, h * 0.65), fade);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
