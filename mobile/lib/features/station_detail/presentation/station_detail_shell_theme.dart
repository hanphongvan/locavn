import 'package:flutter/material.dart';

import '../../stations/presentation/station_review/station_review_compose_theme.dart';

/// Visual tokens aligned with Login / Rate / Report flows.
abstract final class StationDetailShellTheme {
  static const Color background = StationReviewComposeTheme.background;
  static const Color primary = StationReviewComposeTheme.primary;
  static const Color accent = StationReviewComposeTheme.accent;
  static const Color textPrimary = Color(0xFF0B3A7A);
  static const Color textSecondary = Color(0xFF6B7897);
  static const Color star = Color(0xFFFFB82E);
  static const Color badgeOpenBg = Color(0xFFE8F8EE);
  static const Color badgeOpenFg = Color(0xFF15803D);
  static const Color badgeClosedBg = Color(0xFFFEE2E2);
  static const Color badgeClosedFg = Color(0xFFB91C1C);
  static const Color badgePausedBg = Color(0xFFFFF4E5);
  static const Color badgePausedFg = Color(0xFFC2410C);
  static const Color priceHighlightBg = Color(0xFFE8F5E9);
  static const Color cardShadow = Color(0x140F4C9A);

  static const double cardRadius = 20;
  static const double sectionGap = 18;
}
