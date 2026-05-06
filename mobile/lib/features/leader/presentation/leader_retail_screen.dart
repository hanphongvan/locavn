import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../reports/presentation/dashboard/loca_dashboard_tokens.dart';
import '../data/leader_retail_service.dart';
import 'widgets/retail_widgets.dart';

/// Tab **Bán lẻ** (`Loai == 6`) — KPI cửa hàng + xếp hạng tỉnh + cảnh báo.
///
/// Data: `leaderRetailDashboardProvider` (mock service); tap tỉnh mở
/// bottom sheet drill-down có nút "Xem trên bản đồ" → `/leader/map`.
class LeaderRetailScreen extends ConsumerWidget {
  const LeaderRetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(leaderRetailDashboardProvider);
    final filter = ref.watch(leaderRetailFilterProvider);

    return Container(
      color: LocaDashboardTokens.background,
      child: dashboard.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorView(
          message: 'Không tải được dữ liệu: $err',
          onRetry: () => ref.invalidate(leaderRetailDashboardProvider),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(leaderRetailDashboardProvider);
            await ref.read(leaderRetailDashboardProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              const SizedBox(height: 4),
              RetailFilterBar(
                filter: filter,
                regions: data.regions,
                provinces: data.provinces.map((p) => p.province).toList(),
                onChanged: (next) => ref
                    .read(leaderRetailFilterProvider.notifier)
                    .state = next,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _KpiGrid(kpi: data.kpi),
              ),
              const SizedBox(height: 16),
              if (data.warnings.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _SectionHeader(
                    icon: Icons.warning_amber_rounded,
                    title: 'Cảnh báo điều hành',
                    count: data.warnings.length,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      for (final w in data.warnings)
                        RetailWarningCard(warning: w),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: RetailProvinceRanking(
                  provinces: data.provinces,
                  onTap: (p) => _showProvinceDetail(context, p),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProvinceDetail(BuildContext context, RetailProvinceStat stat) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => _ProvinceDetailSheet(stat: stat),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.kpi});
  final RetailKpiSummary kpi;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: RetailKpiCard(
                label: 'Tổng cửa hàng',
                value: '${kpi.totalStores}',
                icon: Icons.storefront_rounded,
                iconColor: LocaDashboardTokens.primaryBlue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RetailKpiCard(
                label: 'Đang hoạt động',
                value: '${kpi.activeStores}',
                icon: Icons.check_circle_rounded,
                iconColor: LocaDashboardTokens.accentGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: RetailKpiCard(
                label: 'Tạm dừng',
                value: '${kpi.pausedStores}',
                icon: Icons.pause_circle_outline_rounded,
                iconColor: Colors.amber.shade700,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RetailKpiCard(
                label: 'Gián đoạn / hết hàng',
                value: '${kpi.outOfStockStores}',
                icon: Icons.error_outline_rounded,
                iconColor: Colors.redAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ActiveRateCard(rate: kpi.activeRate),
      ],
    );
  }
}

class _ActiveRateCard extends StatelessWidget {
  const _ActiveRateCard({required this.rate});
  final double rate;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final pct = (rate * 100).clamp(0, 100);
    final accent = rate >= 0.85
        ? LocaDashboardTokens.accentGreen
        : rate >= 0.7
            ? Colors.amber.shade700
            : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LocaDashboardTokens.cardWhite,
        borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusMd),
        boxShadow: LocaDashboardTokens.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.speed_rounded, size: 20, color: accent),
              ),
              const SizedBox(width: 10),
              Text(
                'Tỷ lệ hoạt động',
                style: t.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: LocaDashboardTokens.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${pct.toStringAsFixed(1)}%',
                style: t.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: accent,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: rate.clamp(0, 1).toDouble(),
              minHeight: 8,
              backgroundColor: accent.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.count,
  });
  final IconData icon;
  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: LocaDashboardTokens.primaryBlue),
        const SizedBox(width: 8),
        Text(
          title,
          style: t.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: LocaDashboardTokens.textPrimary,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: t.labelSmall?.copyWith(
                color: Colors.redAccent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ProvinceDetailSheet extends StatelessWidget {
  const _ProvinceDetailSheet({required this.stat});
  final RetailProvinceStat stat;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: LocaDashboardTokens.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: LocaDashboardTokens.textSecondary.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                stat.province,
                style: t.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: LocaDashboardTokens.textPrimary,
                ),
              ),
              Text(
                'Khu vực: ${stat.region}',
                style: t.bodyMedium?.copyWith(
                  color: LocaDashboardTokens.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: RetailKpiCard(
                      label: 'Tổng cửa hàng',
                      value: '${stat.totalStores}',
                      icon: Icons.storefront_rounded,
                      iconColor: LocaDashboardTokens.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RetailKpiCard(
                      label: 'Đang hoạt động',
                      value: '${stat.activeStores}',
                      icon: Icons.check_circle_rounded,
                      iconColor: LocaDashboardTokens.accentGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: RetailKpiCard(
                      label: 'Tạm dừng',
                      value: '${stat.pausedStores}',
                      icon: Icons.pause_circle_outline_rounded,
                      iconColor: Colors.amber.shade700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RetailKpiCard(
                      label: 'Gián đoạn',
                      value: '${stat.outOfStockStores}',
                      icon: Icons.error_outline_rounded,
                      iconColor: Colors.redAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ActiveRateCard(rate: stat.activeRate),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    ctx.go(AppRoute.leaderMap);
                  },
                  icon: const Icon(Icons.map_rounded),
                  label: const Text('Xem trên bản đồ'),
                  style: FilledButton.styleFrom(
                    backgroundColor: LocaDashboardTokens.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(LocaDashboardTokens.radiusMd),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: LocaDashboardTokens.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: LocaDashboardTokens.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
