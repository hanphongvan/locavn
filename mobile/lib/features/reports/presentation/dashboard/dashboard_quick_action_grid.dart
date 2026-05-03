import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import 'loca_dashboard_tokens.dart';

class DashboardQuickActionGrid extends StatelessWidget {
  const DashboardQuickActionGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_QuickItem>[
      _QuickItem(
        label: 'Tìm gần đây',
        icon: Icons.near_me_outlined,
        color: LocaDashboardTokens.primaryBlue,
        onTap: () => context.go(AppRoute.map.path),
      ),
      _QuickItem(
        label: 'Giá rẻ nhất',
        icon: Icons.savings_outlined,
        color: LocaDashboardTokens.accentGreen,
        onTap: () => context.go(AppRoute.map.path),
      ),
      _QuickItem(
        label: 'Cây xăng uy tín',
        icon: Icons.verified_outlined,
        color: const Color(0xFFFF8A34),
        onTap: () => context.go(AppRoute.map.path),
      ),
      _QuickItem(
        label: 'Báo cáo cây xăng',
        icon: Icons.bar_chart_rounded,
        color: const Color(0xFFE53935),
        onTap: () => context.go(AppRoute.fuel.path),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tiện ích nhanh',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: LocaDashboardTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.55,
            children: items
                .map(
                  (e) => Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusMd),
                      onTap: e.onTap,
                      child: Container(
                        decoration: BoxDecoration(
                          color: LocaDashboardTokens.cardWhite,
                          borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusMd),
                          boxShadow: LocaDashboardTokens.cardShadow(context),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: e.color.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(e.icon, color: e.color, size: 24),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              e.label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: LocaDashboardTokens.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _QuickItem {
  _QuickItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}
