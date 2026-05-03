import 'package:flutter/material.dart';

import '../../reports/presentation/dashboard/loca_dashboard_tokens.dart';

/// Token giao diện **Lãnh đạo** — bám [LocaDashboardTokens] / Citizen (không palette riêng).
abstract final class LeaderTheme {
  static Color get navy => LocaDashboardTokens.primaryBlue;
  static Color get navyLight => LocaDashboardTokens.textPrimary;
  static Color get pageBackground => LocaDashboardTokens.background;
  static Color get card => LocaDashboardTokens.cardWhite;
  static Color get xang => LocaDashboardTokens.primaryBlue;
  static const Color dau = Color(0xFFE65100);
  static const Color alert = Color(0xFFC62828);
  static const Color coverageWarn = Color(0xFFF9A825);
  static const Color coverageOk = Color(0xFF2E7D32);
  static Color get muted => LocaDashboardTokens.textSecondary;

  static List<BoxShadow> cardShadow(BuildContext context) => LocaDashboardTokens.cardShadow(context);

  static BoxDecoration cardDecoration({Color? border, BuildContext? context}) {
    return BoxDecoration(
      color: LocaDashboardTokens.cardWhite,
      borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusLg),
      border: border != null ? Border.all(color: border, width: 1) : null,
      boxShadow: context != null ? LocaDashboardTokens.cardShadow(context) : _cardShadowFallback,
    );
  }

  static final List<BoxShadow> _cardShadowFallback = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];

  static Color daysCoverageColor(double days) {
    if (days < 5) return alert;
    if (days <= 10) return coverageWarn;
    return coverageOk;
  }
}
