import 'package:flutter/material.dart';

/// Bảng màu cho màn Loca AI Leader — đồng bộ với LeaderExecutiveAppBar
/// (`#0B2F6B → #1F3C93`) nhưng xài tone phẳng cho chat bubble.
class LeaderAiPalette {
  LeaderAiPalette._();

  /// Bubble user + accents — navy đậm Section 7 yêu cầu (#1B3A6B).
  static const Color primaryNavy = Color(0xFF1B3A6B);

  /// Bubble AI + card background nhẹ — Section 7 yêu cầu (#EBF2FB).
  static const Color softBlue = Color(0xFFEBF2FB);

  /// Border bubble AI / table cell.
  static const Color borderLight = Color(0xFFE0E7F0);

  /// Cảnh báo amber khi rate limit còn < 10 request/ngày.
  static const Color warningAmber = Color(0xFFFFA726);

  /// Text trên nền primaryNavy.
  static const Color onPrimary = Colors.white;

  /// Text phụ — header table, metadata bubble.
  static const Color textMuted = Color(0xFF6B7280);

  /// Border radius card.
  static const double cardRadius = 12;
}
