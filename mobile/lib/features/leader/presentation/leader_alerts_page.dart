import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/async_value_body.dart';
import '../../map/presentation/map_screen_palette.dart';
import '../../reports/data/models/reports_overview_dto.dart';
import '../../reports/presentation/dashboard/dashboard_background.dart';
import '../../reports/presentation/dashboard/dashboard_section_title.dart';
import '../../reports/presentation/dashboard/loca_dashboard_tokens.dart';
import '../../reports/presentation/reports_providers.dart';
import '../data/leader_operational_alerts.dart';
import 'leader_theme.dart';

enum _AlertTab {
  all,
  critical,
  warning,
  watch,
}

Color _severityColor(LeaderAlertSeverity s) => switch (s) {
      LeaderAlertSeverity.critical => LeaderTheme.alert,
      LeaderAlertSeverity.warning => LeaderTheme.coverageWarn,
      LeaderAlertSeverity.watch => LeaderTheme.xang,
    };

IconData _severityIcon(LeaderAlertSeverity s) => switch (s) {
      LeaderAlertSeverity.critical => Icons.error_outline_rounded,
      LeaderAlertSeverity.warning => Icons.warning_amber_rounded,
      LeaderAlertSeverity.watch => Icons.visibility_outlined,
    };

String _alertTabLabel(_AlertTab tab) => switch (tab) {
      _AlertTab.all => 'Tất cả',
      _AlertTab.critical => 'Nghiêm trọng',
      _AlertTab.warning => 'Cảnh báo',
      _AlertTab.watch => 'Theo dõi',
    };

/// Tab **Cảnh báo điều hành** — chỉ Xăng / Dầu.
class LeaderAlertsPage extends ConsumerStatefulWidget {
  const LeaderAlertsPage({super.key});

  @override
  ConsumerState<LeaderAlertsPage> createState() => _LeaderAlertsPageState();
}

class _LeaderAlertsPageState extends ConsumerState<LeaderAlertsPage> {
  _AlertTab _tab = _AlertTab.all;

  List<LeaderOperationalAlert> _filter(List<LeaderOperationalAlert> all) {
    return switch (_tab) {
      _AlertTab.all => all,
      _AlertTab.critical => all.where((e) => e.severity == LeaderAlertSeverity.critical).toList(),
      _AlertTab.warning => all.where((e) => e.severity == LeaderAlertSeverity.warning).toList(),
      _AlertTab.watch => all.where((e) => e.severity == LeaderAlertSeverity.watch).toList(),
    };
  }

  void _openDetail(BuildContext context, LeaderOperationalAlert a) {
    final t = Theme.of(context).textTheme;
    final df = DateFormat('HH:mm · dd/MM/yyyy', 'vi');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: MapScreenPalette.filterSheetBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: 16 + MediaQuery.paddingOf(ctx).bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    a.title,
                    style: t.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: LocaDashboardTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text(LeaderOperationalAlert.fuelLabelVi(a.fuel)),
                        backgroundColor: a.fuel == LeaderAlertFuel.xang
                            ? LeaderTheme.xang.withValues(alpha: 0.12)
                            : LeaderTheme.dau.withValues(alpha: 0.12),
                        side: BorderSide.none,
                      ),
                      Chip(
                        label: Text(LeaderOperationalAlert.severityLabelVi(a.severity)),
                        backgroundColor: _severityColor(a.severity).withValues(alpha: 0.14),
                        labelStyle: TextStyle(
                          color: _severityColor(a.severity),
                          fontWeight: FontWeight.w700,
                        ),
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.place_outlined, size: 20, color: LocaDashboardTokens.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(a.location, style: t.bodyLarge?.copyWith(height: 1.35)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 20, color: LocaDashboardTokens.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        df.format(a.at),
                        style: t.bodyMedium?.copyWith(color: LocaDashboardTokens.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chi tiết',
                    style: t.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: LocaDashboardTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    a.detailBody,
                    style: t.bodyMedium?.copyWith(color: LocaDashboardTokens.textSecondary, height: 1.45),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      context.go(AppRoute.leaderMap);
                    },
                    icon: const Icon(Icons.map_rounded),
                    label: const Text('Xem trên bản đồ'),
                    style: FilledButton.styleFrom(
                      backgroundColor: LocaDashboardTokens.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(reportsOverviewProvider);
    final t = Theme.of(context).textTheme;

    return DashboardBackground(
      child: SafeArea(
        bottom: false,
        child: AsyncValueBody<ReportsOverviewDto>(
          value: async,
          errorLogLabel: 'Leader alerts',
          loadingLabel: 'Đang tải cảnh báo',
          onRetry: () => ref.invalidate(reportsOverviewProvider),
          dataBuilder: (overview) {
          final all = buildLeaderOperationalAlerts(overview);
          final filtered = _filter(all);
          final nCritical = all.where((e) => e.severity == LeaderAlertSeverity.critical).length;
          final nWarning = all.where((e) => e.severity == LeaderAlertSeverity.warning).length;
          final nDm = countDemoDistributorHubsUnder5Days();
          final nStoreRisk = countStoresAtRisk(all);

            return RefreshIndicator(
              color: LocaDashboardTokens.primaryBlue,
              onRefresh: () async {
                ref.invalidate(reportsOverviewProvider);
                await ref.read(reportsOverviewProvider.future);
              },
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Text(
                      'Chỉ Xăng và Dầu. Quy tắc: dưới 5 ngày → Nghiêm trọng; 5–10 ngày → Cảnh báo; biến động mạnh → Theo dõi.',
                      style: t.bodySmall?.copyWith(color: LocaDashboardTokens.textSecondary, height: 1.35),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tab in _AlertTab.values)
                          FilterChip(
                            label: Text(_alertTabLabel(tab)),
                            selected: _tab == tab,
                            onSelected: (_) => setState(() => _tab = tab),
                            selectedColor: MapScreenPalette.filterChipSelectedBg,
                            checkmarkColor: MapScreenPalette.filterPrimary,
                            showCheckmark: true,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 112,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      itemCount: 4,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final w = (MediaQuery.sizeOf(context).width - 16 * 2 - 10 * 3) / 3.2;
                        final cardW = w.clamp(148.0, 200.0);
                        final cards = <Widget>[
                          _SummaryCard(
                            title: 'Nghiêm trọng',
                            value: '$nCritical',
                            color: LeaderTheme.alert,
                          ),
                          _SummaryCard(
                            title: 'Cảnh báo',
                            value: '$nWarning',
                            color: LeaderTheme.coverageWarn,
                          ),
                          _SummaryCard(
                            title: 'Đầu mối <5 ngày',
                            value: '$nDm',
                            color: LeaderTheme.dau,
                          ),
                          _SummaryCard(
                            title: 'Cửa hàng nguy cơ',
                            value: '$nStoreRisk',
                            color: LeaderTheme.xang,
                          ),
                        ];
                        return SizedBox(width: cardW, child: cards[i]);
                      },
                    ),
                  ),
                  DashboardSectionTitle('Danh sách (${filtered.length})'),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: Text(
                        'Không có cảnh báo trong nhóm đã chọn.',
                        textAlign: TextAlign.center,
                        style: t.bodyMedium?.copyWith(color: LocaDashboardTokens.textSecondary),
                      ),
                    )
                  else
                    ...filtered.map(
                      (a) => Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: _AlertListTile(
                          alert: a,
                          onTap: () => _openDetail(context, a),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: LeaderTheme.cardDecoration(
        border: color.withValues(alpha: 0.35),
        context: context,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: t.labelSmall?.copyWith(color: LeaderTheme.muted, fontWeight: FontWeight.w600, height: 1.25),
          ),
          const SizedBox(height: 8),
          Text(value, style: t.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _AlertListTile extends StatelessWidget {
  const _AlertListTile({required this.alert, required this.onTap});

  final LeaderOperationalAlert alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final time = DateFormat('HH:mm', 'vi').format(alert.at);
    final date = DateFormat('dd/MM/yyyy', 'vi').format(alert.at);
    final c = _severityColor(alert.severity);
    final fuelColor = alert.fuel == LeaderAlertFuel.xang ? LeaderTheme.xang : LeaderTheme.dau;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: LeaderTheme.cardDecoration(
            border: LocaDashboardTokens.primaryBlue.withValues(alpha: 0.08),
            context: context,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: c.withValues(alpha: 0.12),
                child: Icon(_severityIcon(alert.severity), color: c, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: t.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: LocaDashboardTokens.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.location,
                      style: t.bodySmall?.copyWith(color: LocaDashboardTokens.textSecondary, height: 1.35),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _smallChip(
                          LeaderOperationalAlert.fuelLabelVi(alert.fuel),
                          fuelColor,
                        ),
                        _smallChip(LeaderOperationalAlert.severityLabelVi(alert.severity), c),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    time,
                    style: t.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: LocaDashboardTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: t.labelSmall?.copyWith(color: LocaDashboardTokens.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _smallChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
