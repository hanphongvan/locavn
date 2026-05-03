import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../reports/presentation/dashboard/dashboard_background.dart';
import '../../reports/presentation/dashboard/loca_dashboard_tokens.dart';
import '../data/leader_analytics_dtos.dart';
import '../data/leader_analytics_providers.dart';
import '../data/leader_map_ui_state.dart';
import 'leader_theme.dart';
import 'widgets/leader_analytics_color.dart';
import 'widgets/leader_chart_painters.dart';
import 'widgets/leader_grouped_bar_chart.dart';

/// Tab **Phân tích** — dữ liệu từ `GET /api/leader/analytics/*` (cùng SP với DMPPortal home).
class LeaderAnalyticsPage extends ConsumerStatefulWidget {
  const LeaderAnalyticsPage({super.key});

  @override
  ConsumerState<LeaderAnalyticsPage> createState() => _LeaderAnalyticsPageState();
}

class _LeaderAnalyticsPageState extends ConsumerState<LeaderAnalyticsPage> {
  LeaderAnalyticsWindow _window = LeaderAnalyticsWindow.d30;
  LeaderMapFuelFilter _barFuel = LeaderMapFuelFilter.xang;

  static final NumberFormat _qty = NumberFormat.decimalPattern('vi');

  LeaderAnalyticsQuery get _query =>
      LeaderAnalyticsQuery(window: _window, barFuel: _barFuel);

  String get _kyBaoCaoLine {
    switch (_window) {
      case LeaderAnalyticsWindow.d7:
      case LeaderAnalyticsWindow.d30:
        return 'Kỳ báo cáo: tháng hiện tại (lọc hiển thị theo khung thời gian bên dưới).';
      case LeaderAnalyticsWindow.m3:
        return 'Kỳ báo cáo: quý hiện tại.';
      case LeaderAnalyticsWindow.m6:
        return 'Kỳ báo cáo: năm hiện tại.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(leaderAnalyticsBundleProvider(_query));
    final t = Theme.of(context).textTheme;

    return DashboardBackground(
      child: SafeArea(
        bottom: false,
        child: async.when(
          loading: () => _AnalyticsSkeleton(),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off_rounded, size: 48, color: LeaderTheme.muted),
                  const SizedBox(height: 12),
                  Text(
                    e is ApiException ? e.message : e.toString(),
                    textAlign: TextAlign.center,
                    style: t.bodyMedium?.copyWith(color: LocaDashboardTokens.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.invalidate(leaderAnalyticsBundleProvider(_query)),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
          data: (bundle) => RefreshIndicator(
            color: LocaDashboardTokens.primaryBlue,
            onRefresh: () async {
              ref.invalidate(leaderAnalyticsBundleProvider(_query));
              await ref.read(leaderAnalyticsBundleProvider(_query).future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _FilterCard(
                  kyBaoCaoLine: _kyBaoCaoLine,
                  window: _window,
                  onWindow: (w) => setState(() => _window = w),
                ),
                if (_isUnavailable(bundle.inventory.dataSource)) ...[
                  const SizedBox(height: 10),
                  _SourceBanner(message: _unavailableHint(bundle.inventory.dataSource)),
                ],
                const SizedBox(height: 16),
                _sectionTitle(t, Icons.show_chart_rounded, 'Biến động tồn kho'),
                const SizedBox(height: 10),
                _Card(
                  child: _inventorySection(t, bundle.inventory),
                ),
                const SizedBox(height: 22),
                _sectionTitle(t, Icons.bar_chart_rounded, 'Biến động nhập – xuất'),
                const SizedBox(height: 8),
                Text(
                  'Loại nhiên liệu',
                  style: t.labelLarge?.copyWith(color: LeaderTheme.muted, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Xăng'),
                      selected: _barFuel == LeaderMapFuelFilter.xang,
                      onSelected: (_) => setState(() => _barFuel = LeaderMapFuelFilter.xang),
                      selectedColor: LocaDashboardTokens.primaryBlue.withValues(alpha: 0.15),
                      checkmarkColor: LocaDashboardTokens.primaryBlue,
                    ),
                    ChoiceChip(
                      label: const Text('Dầu'),
                      selected: _barFuel == LeaderMapFuelFilter.dau,
                      onSelected: (_) => setState(() => _barFuel = LeaderMapFuelFilter.dau),
                      selectedColor: LocaDashboardTokens.primaryBlue.withValues(alpha: 0.15),
                      checkmarkColor: LocaDashboardTokens.primaryBlue,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _Card(
                  child: _importExportSection(t, bundle.importExport),
                ),
                const SizedBox(height: 22),
                _sectionTitle(t, Icons.payments_outlined, 'Biến động giá'),
                const SizedBox(height: 10),
                _Card(
                  child: _priceSection(t, bundle.price),
                ),
                const SizedBox(height: 22),
                _sectionTitle(t, Icons.compare_arrows_rounded, 'So với kỳ trước'),
                const SizedBox(height: 10),
                SizedBox(
                  height: 148,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    clipBehavior: Clip.none,
                    itemCount: 4,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      const w = 168.0;
                      final cards = [
                        bundle.period.tonKhoXang,
                        bundle.period.tonKhoDau,
                        bundle.period.nhap,
                        bundle.period.xuat,
                      ];
                      return SizedBox(width: w, child: _PctCard(card: cards[i]));
                    },
                  ),
                ),
                const SizedBox(height: 22),
                _sectionTitle(t, Icons.psychology_outlined, 'Nhận định thị trường'),
                const SizedBox(height: 10),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _insightRow(t, 'Xu hướng giá', bundle.insight.xuHuongGia),
                      const SizedBox(height: 12),
                      _insightRow(t, 'Rủi ro cung cầu', bundle.insight.ruiRoCungCau),
                      const SizedBox(height: 12),
                      _insightRow(t, 'Khu vực bất thường', bundle.insight.khuVucBatThuong),
                      const SizedBox(height: 12),
                      _insightRow(t, 'Đề xuất', bundle.insight.deXuat),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isUnavailable(String source) =>
      source == 'unavailable' || source.toLowerCase().contains('missing');

  String _unavailableHint(String source) =>
      'Nguồn dữ liệu: $source. Kiểm tra SP dbo.sp_Dashboard_Home_* trên SQL Server hoặc thử lại sau.';

  Widget _sectionTitle(TextTheme t, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 22, color: LocaDashboardTokens.primaryBlue),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: t.titleSmall?.copyWith(
              color: LocaDashboardTokens.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _inventorySection(TextTheme t, LeaderAnalyticsInventoryTrendDto dto) {
    if (dto.labels.isEmpty || dto.series.isEmpty) {
      return _emptyChartHint(t, 'Chưa có chuỗi tồn kho từ máy chủ cho khung thời gian đã chọn.');
    }
    final series = dto.series
        .map(
          (s) => LeaderLineSeries(
            values: s.values,
            color: s.colorValue,
            label: s.label,
          ),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LeaderMultiLineChart(height: 200, series: series),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            for (final s in series) _miniLegend(s.color, s.label),
          ],
        ),
      ],
    );
  }

  Widget _importExportSection(TextTheme t, LeaderAnalyticsImportExportTrendDto dto) {
    if (dto.labels.isEmpty) {
      return _emptyChartHint(t, 'Chưa có chuỗi nhập – xuất cho khung thời gian đã chọn.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          dto.fuel == 'xang' ? 'Ước lượng theo tỷ trọng tồn xăng từng kỳ (API tổng hợp).' : 'Ước lượng theo tỷ trọng tồn dầu từng kỳ (API tổng hợp).',
          style: t.bodySmall?.copyWith(color: LocaDashboardTokens.textSecondary, height: 1.35),
        ),
        const SizedBox(height: 12),
        LeaderGroupedBarChart(
          labels: dto.labels,
          nhap: dto.nhap,
          xuat: dto.xuat,
          height: 200,
          nhapColor: LeaderTheme.xang,
          xuatColor: LeaderTheme.dau,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _miniLegend(LeaderTheme.xang, 'Nhập'),
            const SizedBox(width: 20),
            _miniLegend(LeaderTheme.dau, 'Xuất'),
          ],
        ),
      ],
    );
  }

  Widget _priceSection(TextTheme t, LeaderAnalyticsPriceTrendDto dto) {
    final ron = _pickPrice(dto.currentPrices, 'RON 95');
    final e5 = _pickPrice(dto.currentPrices, 'E5');
    final die = _pickPrice(dto.currentPrices, 'Diesel');

    Widget cardsRow() => Row(
          children: [
            Expanded(child: _PriceMiniCard(title: 'RON 95', value: _fmtPrice(ron), color: const Color(0xFF0D47A1))),
            const SizedBox(width: 10),
            Expanded(child: _PriceMiniCard(title: 'E5 RON 92', value: _fmtPrice(e5), color: const Color(0xFF1976D2))),
            const SizedBox(width: 10),
            Expanded(child: _PriceMiniCard(title: 'Diesel', value: _fmtPrice(die), color: const Color(0xFFEF6C00))),
          ],
        );

    if (dto.labels.isEmpty || dto.series.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          cardsRow(),
          const SizedBox(height: 12),
          _emptyChartHint(t, 'Chưa có chuỗi giá từ máy chủ.'),
        ],
      );
    }

    final series = dto.series
        .map(
          (s) => LeaderLineSeries(
            values: s.values,
            color: s.colorValue,
            label: s.label,
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (dto.ngayDinhGiaGanNhat != null && dto.ngayDinhGiaGanNhat!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Cập nhật giá gần nhất: ${dto.ngayDinhGiaGanNhat}',
              style: t.bodySmall?.copyWith(color: LeaderTheme.muted),
            ),
          ),
        LeaderMultiLineChart(height: 200, series: series),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [for (final s in series) _miniLegend(s.color, s.label)],
        ),
        const SizedBox(height: 12),
        cardsRow(),
      ],
    );
  }

  static LeaderAnalyticsCurrentPriceDto? _pickPrice(List<LeaderAnalyticsCurrentPriceDto> list, String key) {
    for (final p in list) {
      if (p.label.toUpperCase().contains(key.toUpperCase())) return p;
    }
    return list.isNotEmpty ? list.first : null;
  }

  static String _fmtPrice(LeaderAnalyticsCurrentPriceDto? v) {
    if (v == null) return '—';
    return '${_qty.format(v.value.round())} đ/L';
  }

  Widget _miniLegend(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _emptyChartHint(TextTheme t, String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        msg,
        textAlign: TextAlign.center,
        style: t.bodyMedium?.copyWith(color: LocaDashboardTokens.textSecondary, height: 1.4),
      ),
    );
  }

  Widget _insightRow(TextTheme t, String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: t.labelLarge?.copyWith(
            color: LocaDashboardTokens.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: t.bodyMedium?.copyWith(color: LocaDashboardTokens.textSecondary, height: 1.4),
        ),
      ],
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.kyBaoCaoLine,
    required this.window,
    required this.onWindow,
  });

  final String kyBaoCaoLine;
  final LeaderAnalyticsWindow window;
  final ValueChanged<LeaderAnalyticsWindow> onWindow;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kỳ báo cáo', style: t.labelLarge?.copyWith(fontWeight: FontWeight.w800, color: LeaderTheme.navy)),
          const SizedBox(height: 4),
          Text(kyBaoCaoLine, style: t.bodySmall?.copyWith(color: LocaDashboardTokens.textSecondary, height: 1.35)),
          const SizedBox(height: 14),
          Text('Thời gian', style: t.labelLarge?.copyWith(fontWeight: FontWeight.w800, color: LeaderTheme.navy)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final w in LeaderAnalyticsWindow.values)
                ChoiceChip(
                  label: Text(w.labelVi),
                  selected: window == w,
                  onSelected: (_) => onWindow(w),
                  selectedColor: LocaDashboardTokens.primaryBlue.withValues(alpha: 0.15),
                  checkmarkColor: LocaDashboardTokens.primaryBlue,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Biểu đồ gọi cùng SP với DMPPortal (THANG / QUY / NAM tùy khung).',
            style: t.bodySmall?.copyWith(color: LeaderTheme.muted, height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _SourceBanner extends StatelessWidget {
  const _SourceBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LocaDashboardTokens.warningBg.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusMd),
        border: Border.all(color: LocaDashboardTokens.primaryBlue.withValues(alpha: 0.12)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: LocaDashboardTokens.textPrimary,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: LeaderTheme.cardDecoration(
        border: LocaDashboardTokens.primaryBlue.withValues(alpha: 0.08),
        context: context,
      ),
      child: child,
    );
  }
}

class _PriceMiniCard extends StatelessWidget {
  const _PriceMiniCard({
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
        border: color.withValues(alpha: 0.25),
        context: context,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: t.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            value,
            style: t.titleSmall?.copyWith(
              color: LocaDashboardTokens.textPrimary,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PctCard extends StatelessWidget {
  const _PctCard({required this.card});

  final LeaderAnalyticsDeltaCardDto card;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final v = card.pctChange;
    final color = v > 0
        ? LeaderTheme.coverageOk
        : v < 0
            ? LeaderTheme.alert
            : LocaDashboardTokens.textSecondary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: LeaderTheme.cardDecoration(
        border: color.withValues(alpha: 0.22),
        context: context,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            card.title,
            style: t.labelLarge?.copyWith(
              color: LocaDashboardTokens.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _fmtPctSigned(v),
            style: t.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'So với kỳ trước',
            style: t.bodySmall?.copyWith(color: LocaDashboardTokens.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
      children: [
        _skelBox(100),
        const SizedBox(height: 16),
        _skelBox(220),
        const SizedBox(height: 20),
        _skelBox(220),
        const SizedBox(height: 20),
        _skelBox(260),
        const SizedBox(height: 20),
        _skelBox(148),
      ],
    );
  }

  Widget _skelBox(double h) {
    return Container(
      height: h,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusLg),
        border: Border.all(color: LocaDashboardTokens.primaryBlue.withValues(alpha: 0.06)),
      ),
    );
  }
}

String _fmtPctSigned(double v) {
  final sign = v > 0 ? '+' : '';
  return '$sign${v.toStringAsFixed(1)}%';
}
