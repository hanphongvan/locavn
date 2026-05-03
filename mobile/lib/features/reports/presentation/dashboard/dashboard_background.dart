import 'package:flutter/material.dart';

import 'loca_dashboard_tokens.dart';

/// Soft gradient + subtle decorative blobs (no layout impact on children).
class DashboardBackground extends StatelessWidget {
  const DashboardBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomCenter,
              colors: [
                LocaDashboardTokens.gradientTop,
                LocaDashboardTokens.gradientMid,
                LocaDashboardTokens.background,
              ],
              stops: [0.0, 0.35, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -40,
          right: -30,
          child: _Blob(diameter: 140, color: LocaDashboardTokens.primaryBlue.withValues(alpha: 0.06)),
        ),
        Positioned(
          top: 80,
          left: -50,
          child: _Blob(diameter: 120, color: LocaDashboardTokens.accentGreen.withValues(alpha: 0.08)),
        ),
        child,
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
