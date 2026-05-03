import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/async_value_body.dart';
import '../../reports/data/models/reports_overview_dto.dart';
import '../../reports/data/models/station_count_by_province.dart';
import '../../reports/presentation/dashboard/dashboard_background.dart';
import '../../reports/presentation/dashboard/loca_dashboard_tokens.dart';
import '../../reports/presentation/reports_providers.dart';
import '../data/leader_home_dashboard_providers.dart';
import '../data/leader_fuel_filter.dart';
import '../data/leader_home_portal_models.dart';
import '../data/leader_overview_metrics.dart';
import '../data/leader_overview_stabilization_fund_provider.dart';
import '../data/stabilization_fund_models.dart';
import 'leader_theme.dart';
import 'stabilization_fund_money_format.dart';
import 'widgets/leader_inventory_detail_bottom_sheet.dart';
import 'widgets/leader_sparkline.dart';

/// Trạng thái dự trữ (KPI nền: xanh / vàng / đỏ).
enum LeaderExecStockStatus { safe, warning, critical }

LeaderExecStockStatus _execStatusFromDays(double days) {
  if (days.isNaN) return LeaderExecStockStatus.warning;
  if (days < 5) return LeaderExecStockStatus.critical;
  if (days <= 10) return LeaderExecStockStatus.warning;
  return LeaderExecStockStatus.safe;
}

String _execStatusLabel(LeaderExecStockStatus s) {
  return switch (s) {
    LeaderExecStockStatus.safe => 'An toàn',
    LeaderExecStockStatus.warning => 'Cảnh báo',
    LeaderExecStockStatus.critical => 'Nguy cơ',
  };
}

Color _execStatusSurface(LeaderExecStockStatus s) {
  return switch (s) {
    LeaderExecStockStatus.safe => const Color(0xFFE8F5E9),
    LeaderExecStockStatus.warning => LocaDashboardTokens.warningBg,
    LeaderExecStockStatus.critical => const Color(0xFFFFEBEE),
  };
}

Color _execStatusOnSurface(LeaderExecStockStatus s) {
  return switch (s) {
    LeaderExecStockStatus.safe => LeaderTheme.coverageOk,
    LeaderExecStockStatus.warning => const Color(0xFFE65100),
    LeaderExecStockStatus.critical => LeaderTheme.alert,
  };
}

/// Mũi tên xu hướng từ chuỗi sparkline.
({IconData icon, Color color, String label}) _sparkTrendMeta(List<double> spark) {
  if (spark.length < 2) {
    return (icon: Icons.trending_flat_rounded, color: LeaderTheme.muted, label: 'Ổn định');
  }
  final a = spark.first;
  final b = spark.last;
  if (a <= 0) {
    return (icon: Icons.trending_flat_rounded, color: LeaderTheme.muted, label: 'Ổn định');
  }
  final chg = (b - a) / a * 100;
  if (chg > 1.5) {
    return (icon: Icons.trending_up_rounded, color: LeaderTheme.coverageOk, label: 'Tăng ${chg.abs().toStringAsFixed(1)}%');
  }
  if (chg < -1.5) {
    return (icon: Icons.trending_down_rounded, color: LeaderTheme.alert, label: 'Giảm ${chg.abs().toStringAsFixed(1)}%');
  }
  return (icon: Icons.trending_flat_rounded, color: LeaderTheme.muted, label: 'Đi ngang');
}

String _alertSummaryLine(double daysX, double daysD) {
  final sx = _execStatusFromDays(daysX);
  final sd = _execStatusFromDays(daysD);
  if (sx == LeaderExecStockStatus.critical || sd == LeaderExecStockStatus.critical) {
    return 'Ưu tiên: có nhóm nhiên liệu ở mức nguy cơ (dự trữ < 5 ngày).';
  }
  if (sx == LeaderExecStockStatus.warning || sd == LeaderExecStockStatus.warning) {
    return 'Theo dõi: ít nhất một nhóm đang ở vùng cảnh báo (5–10 ngày).';
  }
  return 'Tổng thể: xăng và dầu đang trong ngưỡng an toàn.';
}

/// Tab **Tổng quan** — giám sát xăng/dầu toàn quốc, chỉ xem.
class LeaderOverviewPage extends ConsumerStatefulWidget {
  const LeaderOverviewPage({super.key});

  @override
  ConsumerState<LeaderOverviewPage> createState() => _LeaderOverviewPageState();
}

class _LeaderOverviewPageState extends ConsumerState<LeaderOverviewPage> {
  DateTime _lastRefresh = DateTime.now();

  static final NumberFormat _qty = NumberFormat.decimalPattern('vi');
  static final DateFormat _clock = DateFormat('HH:mm | dd/MM/yyyy', 'vi');

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(reportsOverviewProvider);
    final fundAsync = ref.watch(leaderOverviewStabilizationFundSummaryProvider);
    ref.watch(leaderHomeInventoryProvider);
    ref.listen<AsyncValue<ReportsOverviewDto>>(reportsOverviewProvider, (prev, next) {
      next.whenData((_) {
        if (mounted) setState(() => _lastRefresh = DateTime.now());
      });
    });

    final textTheme = Theme.of(context).textTheme;

    return DashboardBackground(
      child: SafeArea(
        bottom: false,
        child: AsyncValueBody<ReportsOverviewDto>(
          value: async,
          errorLogLabel: 'Leader overview (reportsOverviewProvider)',
          loadingLabel: 'Đang tải tổng quan',
          onRetry: () => ref.invalidate(reportsOverviewProvider),
          dataBuilder: (overview) {
          final inv = LeaderFuelFilter.withoutKhi(overview.systemInventory);
          final xangLines = LeaderFuelFilter.xangLines(inv);
          final dauLines = LeaderFuelFilter.dauLines(inv);
          final sumXFallback = xangLines.fold<double>(0, (a, b) => a + b.currentQuantity);
          final sumDFallback = dauLines.fold<double>(0, (a, b) => a + b.currentQuantity);
          final open = overview.openStations;
          final periodDays = leaderReportingPeriodDays(overview);

          final hData = ref.watch(leaderHomeInventoryProvider).asData?.value;
          final useHome = hData != null && hData.fromStoredProcedure && hData.tongTonKho.isNotEmpty;
          LeaderHomeTongTonKhoRow? tonX;
          LeaderHomeTongTonKhoRow? tonD;
          LeaderHomeNhapXuatRow? nxX;
          LeaderHomeNhapXuatRow? nxD;
          LeaderHomeCanDoiRow? cX;
          LeaderHomeCanDoiRow? cD;
          if (useHome) {
            final hd = hData;
            bool isX(String t) => t.toLowerCase() == 'xang';
            bool isD(String t) => t.toLowerCase() == 'dau';
            for (final r in hd.tongTonKho) {
              if (isX(r.type)) tonX = r;
              if (isD(r.type)) tonD = r;
            }
            for (final r in hd.nhapXuat) {
              if (isX(r.type)) nxX = r;
              if (isD(r.type)) nxD = r;
            }
            for (final r in hd.canDoi) {
              if (isX(r.type)) cX = r;
              if (isD(r.type)) cD = r;
            }
          }

          final sumX = useHome && tonX != null ? tonX.giaTri : sumXFallback;
          final sumD = useHome && tonD != null ? tonD.giaTri : sumDFallback;
          final daysX = useHome && tonX != null
              ? tonX.soNgay.toDouble()
              : leaderDaysOfCover(totalStock: sumX, openStations: open, isGasoline: true);
          final daysD = useHome && tonD != null
              ? tonD.soNgay.toDouble()
              : leaderDaysOfCover(totalStock: sumD, openStations: open, isGasoline: false);
          final sparkX = useHome && tonX != null && tonX.trend.isNotEmpty
              ? tonX.trend
              : leaderSparkSeries(sumX, sumX.round() ^ 31);
          final sparkD = useHome && tonD != null && tonD.trend.isNotEmpty
              ? tonD.trend
              : leaderSparkSeries(sumD, sumD.round() ^ 17);
          final flowX = nxX != null
              ? LeaderFlowEstimate(
                  nhap: nxX.nhap,
                  xuat: nxX.xuat,
                  pctVsKyTruoc: nxX.pctNhap,
                  pctXuatVsKy: nxX.pctXuat,
                )
              : leaderFlowPlaceholder(stockTonOrM3: sumX, periodDays: periodDays, salt: sumX.round() + 1);
          final flowD = nxD != null
              ? LeaderFlowEstimate(
                  nhap: nxD.nhap,
                  xuat: nxD.xuat,
                  pctVsKyTruoc: nxD.pctNhap,
                  pctXuatVsKy: nxD.pctXuat,
                )
              : leaderFlowPlaceholder(stockTonOrM3: sumD, periodDays: periodDays, salt: sumD.round() + 3);
          final balX = cX?.giaTri ?? (flowX.nhap - flowX.xuat);
          final balD = cD?.giaTri ?? (flowD.nhap - flowD.xuat);
          final topProv = leaderTopProvincesByStations(overview);

          final sx = _execStatusFromDays(daysX);
          final sd = _execStatusFromDays(daysD);

          return RefreshIndicator(
            color: LocaDashboardTokens.primaryBlue,
            onRefresh: () async {
              ref.invalidate(reportsOverviewProvider);
              ref.invalidate(leaderHomeInventoryProvider);
              ref.invalidate(leaderOverviewStabilizationFundSummaryProvider);
              await ref.read(reportsOverviewProvider.future);
              await ref.read(leaderHomeInventoryProvider.future);
              await ref.read(leaderOverviewStabilizationFundSummaryProvider.future);
              if (mounted) setState(() => _lastRefresh = DateTime.now());
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _ExecutiveHeroHeader(
                  textTheme: textTheme,
                  capNhatLuc: _clock.format(_lastRefresh),
                  alertSummary: _alertSummaryLine(daysX, daysD),
                ),
                const SizedBox(height: 16),
                _LeaderQuyBinhOnDashboardStrip(
                  textTheme: textTheme,
                  fundAsync: fundAsync,
                  onRetry: () => ref.invalidate(leaderOverviewStabilizationFundSummaryProvider),
                  onOpenDetail: () => context.go(AppRoute.leaderStabilizationFund),
                ),
                const SizedBox(height: 20),
                _ExecutiveSectionHeader(
                  icon: Icons.speed_rounded,
                  title: 'Chỉ số tồn kho quốc gia',
                  subtitle: 'Xăng · Dầu — theo ngày dự trữ ước tính',
                ),
                const SizedBox(height: 14),
                _ExecutiveKpiFuelCard(
                  title: 'Xăng',
                  icon: Icons.local_gas_station_rounded,
                  accent: LeaderTheme.xang,
                  stockValue: sumX > 0 ? _qty.format(sumX) : '—',
                  unit: 'm³',
                  days: daysX,
                  status: sx,
                  spark: sparkX,
                  onTap: () {
                    final p = ref.read(leaderHomeDashboardRequestProvider);
                    showLeaderInventoryDetailSheet(
                      context,
                      fuelType: 'gasoline',
                      title: 'Chi tiết tồn kho Xăng',
                      month: p.month,
                      year: p.year,
                    );
                  },
                ),
                const SizedBox(height: 16),
                _ExecutiveKpiFuelCard(
                  title: 'Dầu',
                  icon: Icons.oil_barrel_rounded,
                  accent: LeaderTheme.dau,
                  stockValue: sumD > 0 ? _qty.format(sumD) : '—',
                  unit: 'tấn',
                  days: daysD,
                  status: sd,
                  spark: sparkD,
                  onTap: () {
                    final p = ref.read(leaderHomeDashboardRequestProvider);
                    showLeaderInventoryDetailSheet(
                      context,
                      fuelType: 'oil',
                      title: 'Chi tiết tồn kho Dầu',
                      month: p.month,
                      year: p.year,
                    );
                  },
                ),
                const SizedBox(height: 28),
                _ExecutiveSectionHeader(
                  icon: Icons.swap_vert_rounded,
                  title: 'Nhập – Xuất trong kỳ',
                  subtitle: 'Tỷ trọng và biến động so kỳ trước',
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ExecutiveNhapXuatCard(
                        title: 'Xăng',
                        color: LeaderTheme.xang,
                        flow: flowX,
                        qtyFormat: _qty,
                      ),
                      const SizedBox(height: 16),
                      _ExecutiveNhapXuatCard(
                        title: 'Dầu',
                        color: LeaderTheme.dau,
                        flow: flowD,
                        qtyFormat: _qty,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _ExecutiveSectionHeader(
                  icon: Icons.balance_rounded,
                  title: 'Cân đối nhập – xuất',
                  subtitle: 'Dư / thiếu trong kỳ',
                ),
                const SizedBox(height: 14),
                _ExecutiveBalanceStatusCard(title: 'Xăng', accent: LeaderTheme.xang, balance: balX),
                const SizedBox(height: 16),
                _ExecutiveBalanceStatusCard(title: 'Dầu', accent: LeaderTheme.dau, balance: balD),
                const SizedBox(height: 28),
                _ExecutiveSectionHeader(
                  icon: Icons.insights_rounded,
                  title: 'Nhận định nhanh',
                  subtitle: 'Tổng hợp tự động từ chỉ số hiển thị',
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 6, 0, 0),
                  child: _QuickInsightCard(
                    xuHuong: _insightTrend(daysX, daysD),
                    ruiRo: _insightRisk(daysX, daysD),
                    khuVuc: _insightAreas(topProv),
                    khuyenNghi: _insightRecommend(daysX, daysD),
                  ),
                ),
                if (overview.notes != null && overview.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _NotesCard(notes: overview.notes!),
                  ),
                ],
              ],
            ),
          );
        },
        ),
      ),
    );
  }

}

String _fmtPctSigned(double p) {
  final sign = p >= 0 ? '+' : '';
  return '$sign${p.toStringAsFixed(1)}%';
}

String _fmtBalanceSigned(double b) {
  final nf = NumberFormat.decimalPattern('vi');
  final sign = b >= 0 ? '' : '−';
  return '$sign${nf.format(b.abs())}';
}

String _insightTrend(double daysX, double daysD) {
  if (daysX > 12 && daysD > 12) {
    return 'Dự trữ xăng và dầu đang ở mức tương đối sâu so với ước tính tiêu thụ nội bộ.';
  }
  if (daysX < 5 || daysD < 5) {
    return 'Ít nhất một nhóm nhiên liệu đang ở vùng dự trữ ngắn; cần theo dõi sát biến động tuần tới.';
  }
  return 'Xu hướng trung tính: tồn đủ dùng trong khoảng trung bình theo mô hình ước tính hiện tại.';
}

String _insightRisk(double daysX, double daysD) {
  if (daysX < 5 || daysD < 5) {
    return 'Rủi ro gián đoạn cục bộ tăng nếu cầu tăng đột biến hoặc chậm bổ sung nhập.';
  }
  return 'Rủi ro hệ thống thấp theo các chỉ báo tồn tổng hợp trên màn hình này.';
}

String _insightAreas(List<StationCountByProvince> topProv) {
  if (topProv.isEmpty) {
    return 'Chưa có phân bổ trạm theo tỉnh để ưu tiên khu vực.';
  }
  final names = topProv
      .map((e) => (e.provinceName ?? e.provinceCode ?? '').trim())
      .where((s) => s.isNotEmpty)
      .join(', ');
  if (names.isEmpty) {
    return 'Dữ liệu tỉnh đang rỗng; bổ sung liên kết địa lý để gợi ý khu vực.';
  }
  return 'Mật độ trạm cao: $names — nên ưu tiên giám sát biến động tồn và vận tải.';
}

String _insightRecommend(double daysX, double daysD) {
  if (daysX < 5) {
    return 'Đối chiếu kế hoạch nhập xăng với phân phối miền; xem xét điều phối liên vùng.';
  }
  if (daysD < 5) {
    return 'Tăng cường giám sát tồn dầu tại các hành lang logistics và cảng tiếp nhận.';
  }
  return 'Duy trì nhịp cập nhật kỳ; đồng bộ với số liệu hải quan và kho trung chuyển khi có.';
}

/// Dải quỹ bình ổn (parity với DMPPortal `home.component` — `fuel-fund-inline`).
class _LeaderQuyBinhOnDashboardStrip extends StatelessWidget {
  const _LeaderQuyBinhOnDashboardStrip({
    required this.textTheme,
    required this.fundAsync,
    required this.onRetry,
    required this.onOpenDetail,
  });

  final TextTheme textTheme;
  final AsyncValue<StabilizationFundSummaryDto> fundAsync;
  final VoidCallback onRetry;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return fundAsync.when(
      loading: () => _shell(
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: kStabilizationFundPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Đang tải quỹ bình ổn…',
                style: textTheme.bodyMedium?.copyWith(color: LeaderTheme.muted, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
      error: (_, _) => _shell(
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: LeaderTheme.alert),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Không tải được quỹ bình ổn',
                style: textTheme.bodySmall?.copyWith(color: LeaderTheme.muted),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
      data: (s) {
        final period = s.reportMonth > 0 && s.reportYear > 0
            ? '${s.reportMonth.toString().padLeft(2, '0')}/${s.reportYear}'
            : '—';
        final amount = formatStabilizationFundMoney(s.totalBalance);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onOpenDetail,
            borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusLg),
            child: _shell(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_rounded, color: kStabilizationFundPrimary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quỹ bình ổn',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: kStabilizationFundPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tổng tồn quỹ ($period)',
                          style: textTheme.bodySmall?.copyWith(color: LeaderTheme.muted, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        amount,
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: LeaderTheme.navy),
                      ),
                     
                    ],
                  ),
                  Icon(Icons.chevron_right_rounded, color: LeaderTheme.muted),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _shell({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: LocaDashboardTokens.cardWhite,
        borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusLg),
        border: Border.all(color: kStabilizationFundPrimary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }
}

class _ExecutiveHeroHeader extends StatelessWidget {
  const _ExecutiveHeroHeader({
    required this.textTheme,
    required this.capNhatLuc,
    required this.alertSummary,
  });

  final TextTheme textTheme;
  final String capNhatLuc;
  final String alertSummary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroMetaRow(
          icon: Icons.update_rounded,
          text: 'Cập nhật lúc: $capNhatLuc',
          textTheme: textTheme,
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: LocaDashboardTokens.warningBg.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusLg),
            border: Border.all(color: LocaDashboardTokens.primaryBlue.withValues(alpha: 0.12)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_moon_rounded, color: LocaDashboardTokens.primaryBlue, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  alertSummary,
                  style: textTheme.bodyMedium?.copyWith(
                    color: LocaDashboardTokens.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroMetaRow extends StatelessWidget {
  const _HeroMetaRow({
    required this.icon,
    required this.text,
    required this.textTheme,
  });

  final IconData icon;
  final String text;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: LocaDashboardTokens.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodyLarge?.copyWith(
              color: LocaDashboardTokens.textSecondary,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _ExecutiveSectionHeader extends StatelessWidget {
  const _ExecutiveSectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: LocaDashboardTokens.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: LocaDashboardTokens.primaryBlue, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: t.titleLarge?.copyWith(
                  color: LocaDashboardTokens.textPrimary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: t.bodyMedium?.copyWith(color: LeaderTheme.muted, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExecutiveKpiFuelCard extends StatelessWidget {
  const _ExecutiveKpiFuelCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.stockValue,
    required this.unit,
    required this.days,
    required this.status,
    required this.spark,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final String stockValue;
  final String unit;
  final double days;
  final LeaderExecStockStatus status;
  final List<double> spark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final stFill = _execStatusSurface(status);
    final stInk = _execStatusOnSurface(status);
    final daysText = days > 0 ? days.toStringAsFixed(1) : '—';
    final trend = _sparkTrendMeta(spark);

    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(stFill, Colors.white, 0.35)!,
            Colors.white,
          ],
        ),
        border: Border.all(color: stInk.withValues(alpha: 0.35), width: 1.5),
        boxShadow: LeaderTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: accent, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: t.headlineSmall?.copyWith(color: LeaderTheme.navy, fontWeight: FontWeight.w900),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: stFill,
                  borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusPill),
                  border: Border.all(color: stInk.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      status == LeaderExecStockStatus.safe
                          ? Icons.verified_rounded
                          : status == LeaderExecStockStatus.warning
                              ? Icons.warning_amber_rounded
                              : Icons.crisis_alert_rounded,
                      size: 18,
                      color: stInk,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _execStatusLabel(status),
                      style: t.labelLarge?.copyWith(color: stInk, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Tổng tồn kho',
            style: t.labelLarge?.copyWith(color: LeaderTheme.muted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  stockValue,
                  style: t.displaySmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    height: 1.05,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                unit,
                style: t.titleMedium?.copyWith(color: LeaderTheme.muted, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.calendar_month_rounded, size: 22, color: stInk),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dự trữ cho: ',
                  style: t.titleSmall?.copyWith(color: LeaderTheme.navy, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '$daysText ngày',
                style: t.titleLarge?.copyWith(color: stInk, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(trend.icon, color: trend.color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trend.label,
                  style: t.bodyMedium?.copyWith(color: LeaderTheme.navy, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LeaderSparkline(values: spark, color: accent, height: 52),
        ],
      ),
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusLg),
        onTap: onTap,
        child: Semantics(
          button: true,
          label: '$title — xem chi tiết tồn kho theo đầu mối',
          child: card,
        ),
      ),
    );
  }
}

class _ExecutiveNhapXuatCard extends StatelessWidget {
  const _ExecutiveNhapXuatCard({
    required this.title,
    required this.color,
    required this.flow,
    required this.qtyFormat,
  });

  final String title;
  final Color color;
  final LeaderFlowEstimate flow;
  final NumberFormat qtyFormat;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final total = flow.nhap + flow.xuat;
    final nhapP = (total > 0 ? (flow.nhap / total).clamp(0.0, 1.0) : 0.5).toDouble();
    final xuatP = (total > 0 ? (flow.xuat / total).clamp(0.0, 1.0) : 0.5).toDouble();
    final pctIn = flow.pctVsKyTruoc;
    final pctOut = flow.pctXuatEffective;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      decoration: BoxDecoration(
        color: LocaDashboardTokens.cardWhite,
        borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: LeaderTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping_rounded, color: color, size: 26),
              const SizedBox(width: 10),
              Text(title, style: t.titleLarge?.copyWith(color: LeaderTheme.navy, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 18),
          _NxQtyRow(icon: Icons.south_west_rounded, label: 'Nhập', value: qtyFormat.format(flow.nhap), color: color),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: nhapP.toDouble(),
              minHeight: 10,
              backgroundColor: color.withValues(alpha: 0.08),
              color: color,
            ),
          ),
          const SizedBox(height: 14),
          _NxQtyRow(icon: Icons.north_east_rounded, label: 'Xuất', value: qtyFormat.format(flow.xuat), color: color),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: xuatP.toDouble(),
              minHeight: 10,
              backgroundColor: color.withValues(alpha: 0.08),
              color: color.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _PctPill(
                  label: 'Nhập vs kỳ trước',
                  pct: pctIn,
                  positiveGood: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PctPill(
                  label: 'Xuất vs kỳ trước',
                  pct: pctOut,
                  positiveGood: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NxQtyRow extends StatelessWidget {
  const _NxQtyRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: color.withValues(alpha: 0.9)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w700, color: LeaderTheme.navy))),
        Text(value, style: t.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _PctPill extends StatelessWidget {
  const _PctPill({
    required this.label,
    required this.pct,
    required this.positiveGood,
  });

  final String label;
  final double pct;
  final bool positiveGood;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final up = pct >= 0;
    final good = positiveGood ? up : !up;
    final bg = good ? LeaderTheme.coverageOk.withValues(alpha: 0.12) : LeaderTheme.alert.withValues(alpha: 0.12);
    final fg = good ? LeaderTheme.coverageOk : LeaderTheme.alert;
    final icon = up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: t.labelSmall?.copyWith(color: LeaderTheme.muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 4),
              Text(
                _fmtPctSigned(pct),
                style: t.titleMedium?.copyWith(color: fg, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExecutiveBalanceStatusCard extends StatelessWidget {
  const _ExecutiveBalanceStatusCard({
    required this.title,
    required this.accent,
    required this.balance,
  });

  final String title;
  final Color accent;
  final double balance;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final du = balance >= 0;
    final status = du ? LeaderExecStockStatus.safe : LeaderExecStockStatus.critical;
    final label = du ? 'Dư' : 'Thiếu';
    final stFill = _execStatusSurface(status);
    final stInk = _execStatusOnSurface(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusLg),
        color: Color.lerp(stFill, Colors.white, 0.25),
        border: Border.all(color: stInk.withValues(alpha: 0.35), width: 1.5),
        boxShadow: LeaderTheme.cardShadow(context),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 56,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              du ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              color: stInk,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.titleMedium?.copyWith(color: LeaderTheme.navy, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(
                  'Cân đối nhập − xuất',
                  style: t.bodySmall?.copyWith(color: LeaderTheme.muted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: stFill,
                        borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusPill),
                      ),
                      child: Text(
                        label,
                        style: t.titleSmall?.copyWith(color: stInk, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmtBalanceSigned(balance),
                style: t.headlineSmall?.copyWith(
                  color: stInk,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                du ? 'Lệch dư' : 'Lệch thiếu',
                style: t.labelMedium?.copyWith(color: LeaderTheme.muted, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickInsightCard extends StatelessWidget {
  const _QuickInsightCard({
    required this.xuHuong,
    required this.ruiRo,
    required this.khuVuc,
    required this.khuyenNghi,
  });

  final String xuHuong;
  final String ruiRo;
  final String khuVuc;
  final String khuyenNghi;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: LocaDashboardTokens.cardWhite,
        borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusLg),
        border: Border.all(color: LocaDashboardTokens.primaryBlue.withValues(alpha: 0.14)),
        boxShadow: LeaderTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: LeaderTheme.navyLight, size: 22),
              const SizedBox(width: 8),
              Text(
                'Tổng hợp tự động',
                style: t.labelLarge?.copyWith(color: LeaderTheme.muted, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InsightLine(icon: Icons.show_chart_rounded, label: 'Xu hướng', body: xuHuong),
          const SizedBox(height: 12),
          _InsightLine(icon: Icons.shield_moon_outlined, label: 'Rủi ro', body: ruiRo),
          const SizedBox(height: 12),
          _InsightLine(icon: Icons.place_outlined, label: 'Khu vực cần chú ý', body: khuVuc),
          const SizedBox(height: 12),
          _InsightLine(icon: Icons.lightbulb_outline_rounded, label: 'Khuyến nghị', body: khuyenNghi),
        ],
      ),
    );
  }
}

class _InsightLine extends StatelessWidget {
  const _InsightLine({
    required this.icon,
    required this.label,
    required this.body,
  });

  final IconData icon;
  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: LeaderTheme.navy),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: t.labelLarge?.copyWith(color: LeaderTheme.navy, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: t.bodyMedium?.copyWith(color: LeaderTheme.muted, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.notes});

  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LeaderTheme.navy.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusLg),
        border: Border.all(color: LeaderTheme.navy.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 20, color: LeaderTheme.navy),
              const SizedBox(width: 8),
              Text('Ghi chú hệ thống', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          ...notes.map(
            (n) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(n, style: t.bodySmall?.copyWith(color: LeaderTheme.muted, height: 1.35)),
            ),
          ),
        ],
      ),
    );
  }
}
