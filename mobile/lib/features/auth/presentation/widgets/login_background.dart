import 'dart:ui';

import 'package:flutter/material.dart';

import 'login_screen_theme.dart';

/// Soft blue–cyan–mint gradient with blurred abstract orbs (no images).
class LoginBackground extends StatelessWidget {
  const LoginBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  LoginScreenTheme.bgTop,
                  LoginScreenTheme.bgMid,
                  LoginScreenTheme.bgBottom,
                ],
                stops: [0.0, 0.48, 1.0],
              ),
            ),
          ),
          // Large blue orb — top trailing, mostly off-screen
          Positioned(
            top: -140,
            right: -100,
            child: _BlurredOrb(
              diameter: 340,
              color: LoginScreenTheme.atmosphereBlue,
              opacity: 0.26,
              blurSigma: 80,
            ),
          ),
          // Cyan orb — upper leading
          Positioned(
            top: -60,
            left: -120,
            child: _BlurredOrb(
              diameter: 300,
              color: LoginScreenTheme.atmosphereCyan,
              opacity: 0.24,
              blurSigma: 72,
            ),
          ),
          // Green orb — mid / lower leading
          Positioned(
            top: MediaQuery.sizeOf(context).height * 0.28,
            left: -140,
            child: _BlurredOrb(
              diameter: 280,
              color: LoginScreenTheme.atmosphereGreen,
              opacity: 0.22,
              blurSigma: 76,
            ),
          ),
          // Cyan — bottom, partially clipped
          Positioned(
            bottom: -100,
            left: -40,
            child: _BlurredOrb(
              diameter: 320,
              color: LoginScreenTheme.atmosphereCyan,
              opacity: 0.2,
              blurSigma: 88,
            ),
          ),
          // Blue-green blend — bottom trailing
          Positioned(
            bottom: -80,
            right: -100,
            child: _BlurredOrb(
              diameter: 300,
              color: LoginScreenTheme.atmosphereGreen,
              opacity: 0.24,
              blurSigma: 74,
            ),
          ),
          // Small blue accent (depth, still soft)
          Positioned(
            top: MediaQuery.sizeOf(context).height * 0.42,
            right: -60,
            child: _BlurredOrb(
              diameter: 200,
              color: LoginScreenTheme.atmosphereBlue,
              opacity: 0.2,
              blurSigma: 56,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlurredOrb extends StatelessWidget {
  const _BlurredOrb({
    required this.diameter,
    required this.color,
    required this.opacity,
    required this.blurSigma,
  });

  final double diameter;
  final Color color;
  final double opacity;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: opacity),
        ),
      ),
    );
  }
}
