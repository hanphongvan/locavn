import 'package:flutter/material.dart';

import '../account_palette.dart';

class ActivitySummaryRow extends StatelessWidget {
  const ActivitySummaryRow({
    super.key,
    this.reviewsCount,
    this.reportsCount,
    this.fuelCount,
  });

  final int? reviewsCount;
  final int? reportsCount;
  final int? fuelCount;

  static String _fmt(int? v) {
    if (v == null) return '—';
    return '$v';
  }

  @override
  Widget build(BuildContext context) {
    final r = reviewsCount ?? 0;
    final p = reportsCount ?? 0;
    final f = fuelCount ?? 0;
    final hasTotals = reviewsCount != null && reportsCount != null && fuelCount != null;
    final showEmptyHint = !hasTotals || (r + p + f == 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCell(
                icon: Icons.star_rounded,
                iconColor: const Color(0xFFF59E0B),
                value: _fmt(reviewsCount),
                label: 'Đánh giá đã gửi',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCell(
                icon: Icons.flag_outlined,
                iconColor: AccountPalette.primaryBlue,
                value: _fmt(reportsCount),
                label: 'Báo cáo đã gửi',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCell(
                icon: Icons.local_gas_station_outlined,
                iconColor: AccountPalette.accentGreen,
                value: _fmt(fuelCount),
                label: 'Lần đổ xăng',
              ),
            ),
          ],
        ),
        if (showEmptyHint) ...[
          const SizedBox(height: 12),
          Text(
            'Bạn chưa có hoạt động nào',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AccountPalette.textSecondary.withValues(alpha: 0.95),
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AccountPalette.cardWhite,
        borderRadius: BorderRadius.circular(AccountPalette.radiusMd),
        border: Border.all(color: AccountPalette.border),
        boxShadow: AccountPalette.cardShadow(context),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AccountPalette.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AccountPalette.textSecondary,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}
