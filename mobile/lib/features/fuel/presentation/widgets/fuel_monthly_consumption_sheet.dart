import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../fuel_monthly_chart_providers.dart';
import '../fuel_palette.dart';
import '../fuel_tracking_providers.dart';

/// Bottom sheet: bar chart — tiêu thụ (lít) theo tháng, 6 tháng gần nhất tính từ tháng báo cáo trên dashboard.
Future<void> showFuelMonthlyConsumptionSheet({
  required BuildContext context,
  required WidgetRef ref,
  required int vehicleId,
  required String vehicleLabel,
}) async {
  if (vehicleId < 1) return;
  final period = ref.read(fuelReportPeriodProvider);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => FuelMonthlyConsumptionSheet(
      vehicleId: vehicleId,
      vehicleLabel: vehicleLabel,
      anchorYear: period.year,
      anchorMonth: period.month,
    ),
  );
}

class FuelMonthlyConsumptionSheet extends ConsumerWidget {
  const FuelMonthlyConsumptionSheet({
    super.key,
    required this.vehicleId,
    required this.vehicleLabel,
    required this.anchorYear,
    required this.anchorMonth,
  });

  final int vehicleId;
  final String vehicleLabel;
  final int anchorYear;
  final int anchorMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final args = FuelMonthlyChartArgs(
      vehicleId: vehicleId,
      anchorYear: anchorYear,
      anchorMonth: anchorMonth,
    );
    final async = ref.watch(fuelMonthlyLitersChartProvider(args));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.58,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: FuelPalette.cardWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(FuelPalette.radiusLg)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, -4)),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: FuelPalette.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tiêu thụ nhiên liệu theo tháng',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: FuelPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vehicleLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: FuelPalette.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '6 tháng gần nhất (tính đến $anchorMonth/$anchorYear)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: FuelPalette.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottom),
                  children: [
                    async.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: CircularProgressIndicator(color: FuelPalette.primaryBlue)),
                      ),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Không tải được dữ liệu: $e',
                          style: theme.textTheme.bodyMedium?.copyWith(color: FuelPalette.redChange),
                        ),
                      ),
                      data: (points) => _MonthlyBarChart(points: points),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Số liệu theo từng tháng từ API tóm tắt (tổng lít đã đổ trong tháng).',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: FuelPalette.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  const _MonthlyBarChart({required this.points});

  final List<MonthlyLiterPoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const chartHeight = 200.0;
    final maxL = points.fold<double>(0, (m, p) => p.liters > m ? p.liters : m);
    final scale = maxL > 0.0001 ? maxL : 1.0;
    final nf = NumberFormat.decimalPattern('vi_VN');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
      decoration: BoxDecoration(
        color: FuelPalette.background,
        borderRadius: BorderRadius.circular(FuelPalette.radiusMd),
        border: Border.all(color: FuelPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Đơn vị: lít',
            style: theme.textTheme.labelLarge?.copyWith(
              color: FuelPalette.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: chartHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final p in points)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _BarColumn(
                        liters: p.liters,
                        maxScale: scale,
                        chartHeight: chartHeight - 36,
                        monthLabel: DateFormat('M/yy').format(DateTime(p.year, p.month)),
                        valueText: nf.format(p.liters),
                      ),
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

class _BarColumn extends StatelessWidget {
  const _BarColumn({
    required this.liters,
    required this.maxScale,
    required this.chartHeight,
    required this.monthLabel,
    required this.valueText,
  });

  final double liters;
  final double maxScale;
  final double chartHeight;
  final String monthLabel;
  final String valueText;

  @override
  Widget build(BuildContext context) {
    final ratio = (liters / maxScale).clamp(0.0, 1.0);
    final barH = (chartHeight * ratio).clamp(4.0, chartHeight);
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          height: chartHeight,
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                height: barH,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      FuelPalette.primaryBlue.withValues(alpha: 0.88),
                      FuelPalette.accentGreen.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
              if (liters >= 0.01)
                Positioned(
                  bottom: barH + 2,
                  left: 0,
                  right: 0,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      valueText,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: FuelPalette.primaryBlue,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          monthLabel,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: FuelPalette.textSecondary,
          ),
        ),
      ],
    );
  }
}
