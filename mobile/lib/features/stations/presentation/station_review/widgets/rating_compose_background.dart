import 'dart:ui';

import 'package:flutter/material.dart';

import '../station_review_compose_theme.dart';

/// Nền gradient mềm + họa tiết trang trí (chỉ trình bày).
class RatingComposeBackground extends StatelessWidget {
  const RatingComposeBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(decoration: BoxDecoration(gradient: StationReviewComposeTheme.screenGradient)),
        Positioned(
          top: -60,
          left: -40,
          child: IgnorePointer(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: StationReviewComposeTheme.primary.withValues(alpha: 0.12),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 48,
          right: -12,
          child: IgnorePointer(
            child: CustomPaint(
              size: const Size(120, 90),
              painter: _DottedPatternPainter(
                color: StationReviewComposeTheme.primary.withValues(alpha: 0.14),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _DottedPatternPainter extends CustomPainter {
  _DottedPatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 10.0;
    final paint = Paint()..color = color;
    for (var y = 0.0; y < size.height; y += spacing) {
      for (var x = 0.0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedPatternPainter oldDelegate) => oldDelegate.color != color;
}
