import 'package:flutter/material.dart';

import '../../data/models/reports_overview_dto.dart';
import 'loca_dashboard_tokens.dart';

/// Three mini stats: total / open / closed — all from [ReportsOverviewDto] (same API).
class DashboardStatCards extends StatelessWidget {
  const DashboardStatCards({super.key, required this.overview});

  final ReportsOverviewDto overview;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _MiniStat(
              icon: Icons.local_gas_station_outlined,
              label: 'Tổng cây xăng',
              value: overview.totalStations.toString(),
              iconBg: LocaDashboardTokens.primaryBlue.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MiniStat(
              icon: Icons.storefront_outlined,
              label: 'Đang mở',
              value: overview.openStations.toString(),
              iconBg: LocaDashboardTokens.accentGreen.withValues(alpha: 0.15),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MiniStat(
              icon: Icons.store_mall_directory_outlined,
              label: 'Đóng cửa',
              value: overview.closedStations.toString(),
              iconBg: LocaDashboardTokens.textSecondary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconBg,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconBg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      decoration: BoxDecoration(
        color: LocaDashboardTokens.cardWhite,
        borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusMd),
        boxShadow: LocaDashboardTokens.cardShadow(context),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: LocaDashboardTokens.primaryBlue, size: 22),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: LocaDashboardTokens.textSecondary,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: LocaDashboardTokens.textPrimary,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
