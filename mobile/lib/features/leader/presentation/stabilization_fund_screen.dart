import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../reports/presentation/dashboard/loca_dashboard_tokens.dart';
import '../data/stabilization_fund_models.dart';
import '../data/stabilization_fund_service.dart';
import 'leader_theme.dart';
import 'stabilization_fund_filter_bus.dart';
import 'stabilization_fund_money_format.dart';
import 'widgets/stabilization_fund_detail_sheet.dart';

final class _StabilizationPeriodChoice {
  const _StabilizationPeriodChoice.latest() : useServerDefault = true, month = 0, year = 0;
  const _StabilizationPeriodChoice.pick({required this.month, required this.year}) : useServerDefault = false;

  final bool useServerDefault;
  final int month;
  final int year;
}

/// Tab **Quỹ bình ổn** — Lãnh đạo (`Loai == 6`).
class StabilizationFundScreen extends ConsumerStatefulWidget {
  const StabilizationFundScreen({super.key});

  @override
  ConsumerState<StabilizationFundScreen> createState() => _StabilizationFundScreenState();
}

class _StabilizationFundScreenState extends ConsumerState<StabilizationFundScreen> {
  /// Khi false: gọi API không gửi tháng/năm — máy chủ chọn kỳ BC08 mới nhất.
  bool _useExplicitPeriod = false;
  int? _filterMonth;
  int? _filterYear;
  final TextEditingController _search = TextEditingController();
  String _statusChip = 'all';
  Future<({StabilizationFundSummaryDto s, StabilizationFundDistributorsDto d})>? _bundle;
  StabilizationFundSummaryDto? _lastSummary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(stabilizationFundFilterBusProvider).register(() {
        if (!mounted) return;
        _openPeriodFilter(context, _lastSummary);
      });
    });
  }

  @override
  void dispose() {
    ref.read(stabilizationFundFilterBusProvider).clear();
    _search.dispose();
    super.dispose();
  }

  Future<({StabilizationFundSummaryDto s, StabilizationFundDistributorsDto d})> _trackSummary(
    Future<({StabilizationFundSummaryDto s, StabilizationFundDistributorsDto d})> future,
  ) {
    future.then((v) {
      if (mounted) setState(() => _lastSummary = v.s);
    });
    return future;
  }

  Future<({StabilizationFundSummaryDto s, StabilizationFundDistributorsDto d})> _load() async {
    final svc = ref.read(stabilizationFundServiceProvider);
    if (_useExplicitPeriod && _filterMonth != null && _filterYear != null) {
      final m = _filterMonth!;
      final y = _filterYear!;
      final s = await svc.getSummary(month: m, year: y);
      final d = await svc.getDistributors(month: m, year: y);
      return (s: s, d: d);
    }
    final s = await svc.getSummary();
    final d = await svc.getDistributors();
    return (s: s, d: d);
  }

  Future<void> _openPeriodFilter(BuildContext context, StabilizationFundSummaryDto? summary) async {
    final initialM = _useExplicitPeriod && _filterMonth != null
        ? _filterMonth!
        : (summary != null && summary.reportMonth > 0 ? summary.reportMonth : DateTime.now().month);
    final initialY = _useExplicitPeriod && _filterYear != null
        ? _filterYear!
        : (summary != null && summary.reportYear > 0 ? summary.reportYear : DateTime.now().year);

    final choice = await showModalBottomSheet<_StabilizationPeriodChoice>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        var m = initialM.clamp(1, 12);
        var y = initialY;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: StatefulBuilder(
              builder: (ctx, setModal) {
                final years = [for (var yy = DateTime.now().year; yy >= DateTime.now().year - 8; yy--) yy];
                if (!years.contains(y)) {
                  y = years.first;
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Lọc kỳ ',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: kStabilizationFundPrimary),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tháng', style: Theme.of(ctx).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800, color: LeaderTheme.muted)),
                              const SizedBox(height: 6),
                              DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  isExpanded: true,
                                  value: m,
                                  items: [
                                    for (var mm = 1; mm <= 12; mm++) DropdownMenuItem(value: mm, child: Text('Tháng $mm')),
                                  ],
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setModal(() => m = v);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Năm', style: Theme.of(ctx).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800, color: LeaderTheme.muted)),
                              const SizedBox(height: 6),
                              DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  isExpanded: true,
                                  value: y,
                                  items: [for (final yy in years) DropdownMenuItem(value: yy, child: Text('$yy'))],
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setModal(() => y = v);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, _StabilizationPeriodChoice.pick(month: m, year: y)),
                      style: FilledButton.styleFrom(backgroundColor: kStabilizationFundPrimary),
                      child: const Text('Áp dụng'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, const _StabilizationPeriodChoice.latest()),
                      child: const Text('Kỳ mới nhất '),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    if (!context.mounted || choice == null) return;
    if (choice.useServerDefault) {
      setState(() {
        _useExplicitPeriod = false;
        _filterMonth = null;
        _filterYear = null;
        _bundle = _trackSummary(_load());
      });
    } else {
      setState(() {
        _useExplicitPeriod = true;
        _filterMonth = choice.month;
        _filterYear = choice.year;
        _bundle = _trackSummary(_load());
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bundle ??= _trackSummary(_load());
  }

  void _reload() {
    setState(() {
      _bundle = _trackSummary(_load());
    });
  }

  bool _statusMatch(StabilizationFundDistributorRow r) {
    if (_statusChip == 'all') return true;
    return r.reportStatus == _statusChip;
  }

  List<StabilizationFundDistributorRow> _filtered(List<StabilizationFundDistributorRow> raw) {
    final q = _search.text.trim().toLowerCase();
    var list = raw.where(_statusMatch).toList();
    if (q.isNotEmpty) {
      list = list
          .where((r) {
            final n = r.distributorName.toLowerCase();
            final a = (r.address ?? '').toLowerCase();
            return n.contains(q) || a.contains(q);
          })
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return ColoredBox(
      color: LocaDashboardTokens.background,
      child: FutureBuilder(
        future: _bundle,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _LoadingSkeleton();
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 48, color: LeaderTheme.alert),
                    const SizedBox(height: 12),
                    Text(
                      'Không tải được dữ liệu',
                      style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Thử lại'),
                      style: FilledButton.styleFrom(backgroundColor: kStabilizationFundPrimary),
                    ),
                  ],
                ),
              ),
            );
          }
          final data = snap.data!;
          final summary = data.s;
          final distributors = data.d.items;
          final filtered = _filtered(distributors);
          final empty = distributors.isEmpty && summary.totalBalance == 0 && summary.reportedDistributorCount == 0;

          return RefreshIndicator(
            color: kStabilizationFundPrimary,
            onRefresh: () async {
              final f = _trackSummary(_load());
              setState(() => _bundle = f);
              await f;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
               
                if (summary.reportMonth > 0 && summary.reportYear > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Kỳ hiển thị: ${summary.reportMonth.toString().padLeft(2, '0')}/${summary.reportYear} · Mốc ngày ${summary.reportCutoffDayOfMonth} trong tháng (VN)',
                    style: t.bodySmall?.copyWith(color: LeaderTheme.muted, fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 20),
                _SummaryGrid(summary: summary),
                const SizedBox(height: 24),
                Text(
                  'Biến động quỹ theo tháng',
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: LeaderTheme.navy),
                ),
                const SizedBox(height: 12),
                _MonthlyTrendChart(points: summary.monthlyTrend),
                const SizedBox(height: 28),
                Text(
                  'Số dư theo doanh nghiệp',
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: LeaderTheme.navy),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: 'Tìm doanh nghiệp',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: LocaDashboardTokens.cardWhite,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusLg)),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _StatusChip(
                        label: 'Tất cả',
                        selected: _statusChip == 'all',
                        onTap: () => setState(() => _statusChip = 'all'),
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(
                        label: 'Đã báo cáo',
                        selected: _statusChip == 'Đã báo cáo',
                        onTap: () => setState(() => _statusChip = 'Đã báo cáo'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (empty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'Chưa có dữ liệu quỹ bình ổn',
                        style: t.titleMedium?.copyWith(color: LeaderTheme.muted, fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ...filtered.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DistributorCard(
                        row: r,
                        onTap: () => showStabilizationFundDetailSheet(
                          context,
                          row: r,
                          reportMonth: r.reportMonth,
                          reportYear: r.reportYear,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});

  final StabilizationFundSummaryDto summary;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, c) {
        final w = (c.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _SummaryCard(
              width: w,
              title: 'Tổng tồn quỹ',
              value: formatStabilizationFundMoney(summary.totalBalance),
              t: t,
            ),
            _SummaryCard(
              width: w,
              title: 'Tăng/giảm so với tháng trước',
              value: formatSignedStabilizationMoney(summary.changeFromPreviousMonth),
              t: t,
            ),
            _SummaryCard(
              width: w,
              title: 'Số đơn vị báo cáo',
              value: '${summary.reportedDistributorCount}',
              t: t,
            ),
            _SummaryCard(
              width: w,
              title: 'Bình quân / đơn vị',
              value: formatStabilizationFundMoney(
                summary.reportedDistributorCount > 0
                    ? summary.totalBalance / summary.reportedDistributorCount
                    : 0,
              ),
              t: t,
            ),            
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.width,
    required this.title,
    required this.value,
    required this.t,
  });

  final double width;
  final String title;
  final String value;
  final TextTheme t;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LocaDashboardTokens.cardWhite,
          borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusLg),
          border: Border.all(color: kStabilizationFundPrimary.withValues(alpha: 0.15)),
          boxShadow: LeaderTheme.cardShadow(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: t.labelLarge?.copyWith(color: LeaderTheme.muted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(value, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: kStabilizationFundPrimary)),
          ],
        ),
      ),
    );
  }
}

class _MonthlyTrendChart extends StatelessWidget {
  const _MonthlyTrendChart({required this.points});

  final List<StabilizationFundMonthlyPointDto> points;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    if (points.isEmpty) {
      return Text('Chưa có chuỗi tháng.', style: t.bodyMedium?.copyWith(color: LeaderTheme.muted));
    }
    final maxY = points.map((e) => e.totalBalance).fold<double>(0, math.max);
    final safeMax = maxY <= 0 ? 1.0 : maxY;
    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final p in points)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Tooltip(
                      message: formatStabilizationFundMoney(p.totalBalance),
                      child: Container(
                        height: (p.totalBalance / safeMax * 140).clamp(6.0, 140.0),
                        decoration: BoxDecoration(
                          color: kStabilizationFundPrimary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${p.month}/${p.year.toString().substring(2)}',
                      style: t.labelSmall?.copyWith(color: LeaderTheme.muted, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (v) {
        if (v) onTap();
      },
      showCheckmark: false,
      selectedColor: kStabilizationFundPrimary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w800,
        color: selected ? kStabilizationFundPrimary : LeaderTheme.muted,
      ),
      side: BorderSide(color: selected ? kStabilizationFundPrimary : Colors.black12),
    );
  }
}

class _DistributorCard extends StatelessWidget {
  const _DistributorCard({required this.row, required this.onTap});

  final StabilizationFundDistributorRow row;
  final VoidCallback onTap;

  Color _statusColor() {
    switch (row.reportStatus) {
      case 'Đã báo cáo':
        return LeaderTheme.coverageOk;
      case 'Chưa báo cáo':
        return LeaderTheme.muted;
      case 'Bất thường':
        return LeaderTheme.alert;
      default:
        return LeaderTheme.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final st = _statusColor();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusLg),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: LocaDashboardTokens.cardWhite,
            borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusLg),
            border: Border.all(color: st.withValues(alpha: 0.25)),
            boxShadow: LeaderTheme.cardShadow(context),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tên doanh nghiệp', style: t.labelSmall?.copyWith(color: LeaderTheme.muted)),
                Text(row.distributorName, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: LeaderTheme.navy)),
                if ((row.address ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Địa chỉ', style: t.labelSmall?.copyWith(color: LeaderTheme.muted)),
                  Text(row.address!.trim(), style: t.bodyMedium?.copyWith(color: LeaderTheme.muted)),
                ],
                const SizedBox(height: 10),
                Text('Số dư quỹ', style: t.labelSmall?.copyWith(color: LeaderTheme.muted)),
                Text(formatStabilizationFundMoney(row.balance), style: t.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: kStabilizationFundPrimary)),
                const SizedBox(height: 8),
                Text('Tháng báo cáo', style: t.labelSmall?.copyWith(color: LeaderTheme.muted)),
                Text('${row.reportMonth.toString().padLeft(2, '0')}/${row.reportYear}', style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Tăng/giảm so với tháng trước', style: t.labelSmall?.copyWith(color: LeaderTheme.muted)),
                Text(formatSignedStabilizationMoney(row.changeFromPreviousMonth), style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: st.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: st.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      'Trạng thái báo cáo: ${row.reportStatus}',
                      style: t.labelLarge?.copyWith(color: st, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sk(),
        const SizedBox(height: 12),
        _sk(h: 20),
        const SizedBox(height: 24),
        Row(children: [Expanded(child: _sk(h: 80)), const SizedBox(width: 12), Expanded(child: _sk(h: 80))]),
        const SizedBox(height: 12),
        _sk(h: 80),
      ],
    );
  }

  Widget _sk({double h = 120}) {
    return Container(
      height: h,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
