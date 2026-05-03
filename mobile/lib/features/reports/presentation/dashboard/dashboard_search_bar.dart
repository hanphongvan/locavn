import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import 'loca_dashboard_tokens.dart';

class DashboardSearchBar extends StatelessWidget {
  const DashboardSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Material(
        color: LocaDashboardTokens.cardWhite,
        borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusPill),
        elevation: 0,
        shadowColor: Colors.black26,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusPill),
            boxShadow: LocaDashboardTokens.cardShadow(context),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusPill),
            onTap: () => context.go(AppRoute.map.path),
            child: SizedBox(
              height: 50,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.search_rounded, color: LocaDashboardTokens.textSecondary, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Tìm cây xăng, địa điểm...',
                      style: TextStyle(
                        fontSize: 15,
                        color: LocaDashboardTokens.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const _FilterTap(),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterTap extends StatelessWidget {
  const _FilterTap();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(AppRoute.more.path),
        borderRadius: BorderRadius.circular(24),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(Icons.tune_rounded, color: LocaDashboardTokens.primaryBlue, size: 22),
        ),
      ),
    );
  }
}
