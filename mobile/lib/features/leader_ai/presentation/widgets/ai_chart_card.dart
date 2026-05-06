import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/leader_ai_models.dart';
import 'leader_ai_palette.dart';

/// Card biểu đồ — Phase 2B chỉ render `bar` và `line` (Section 5 yêu cầu).
/// `pie` / `area` để Phase 3 (cần wrap thêm widget pie chart).
///
/// Height cố định 220px theo Section 7. Title từ `chart.title`.
class AiChartCard extends StatelessWidget {
  const AiChartCard({super.key, required this.chart});

  final AiChartData chart;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LeaderAiPalette.cardRadius),
        side: const BorderSide(color: LeaderAiPalette.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (chart.title.isNotEmpty)
              Text(
                chart.title,
                style: textTheme.titleSmall?.copyWith(
                  color: LeaderAiPalette.primaryNavy,
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: _buildChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    if (chart.series.isEmpty || chart.categories.isEmpty) {
      return Center(
        child: Text(
          'Không có dữ liệu',
          style: TextStyle(color: LeaderAiPalette.textMuted),
        ),
      );
    }

    final type = chart.type.toLowerCase();
    if (type == 'line' || type == 'area') {
      return _LineChartView(chart: chart);
    }
    // Default: bar (Phase 2B fallback). pie sẽ thêm Phase 3.
    return _BarChartView(chart: chart);
  }
}

class _BarChartView extends StatelessWidget {
  const _BarChartView({required this.chart});

  final AiChartData chart;

  @override
  Widget build(BuildContext context) {
    // Phase 2B: chỉ render series đầu tiên — multi-series sẽ thêm Phase 3 với legend riêng.
    final values = chart.series.first.values;
    final maxY = values.fold<double>(0, (m, v) => v > m ? v : m);
    final niceMax = maxY <= 0 ? 1 : maxY * 1.15;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: niceMax.toDouble(),
        barTouchData: BarTouchData(enabled: true),
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: niceMax / 4),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (v, _) => Text(
                _shortNumber(v),
                style: const TextStyle(fontSize: 10, color: LeaderAiPalette.textMuted),
              ),
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= chart.categories.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    chart.categories[i],
                    style: const TextStyle(fontSize: 10, color: LeaderAiPalette.textMuted),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < values.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i],
                  color: LeaderAiPalette.primaryNavy,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LineChartView extends StatelessWidget {
  const _LineChartView({required this.chart});

  final AiChartData chart;

  @override
  Widget build(BuildContext context) {
    final values = chart.series.first.values;
    if (values.isEmpty) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) * 0.15;

    return LineChart(
      LineChartData(
        minY: (minY - pad).clamp(0, double.infinity),
        maxY: maxY + pad,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (v, _) => Text(
                _shortNumber(v),
                style: const TextStyle(fontSize: 10, color: LeaderAiPalette.textMuted),
              ),
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= chart.categories.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    chart.categories[i],
                    style: const TextStyle(fontSize: 10, color: LeaderAiPalette.textMuted),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
            ],
            isCurved: true,
            color: LeaderAiPalette.primaryNavy,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: LeaderAiPalette.primaryNavy.withValues(alpha: 0.10),
            ),
          ),
        ],
      ),
    );
  }
}

/// 24500.0 → "24.5K", 1500000 → "1.5M" — vừa nhãn trục Y bé.
String _shortNumber(double v) {
  if (v.abs() >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
  if (v.abs() >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
  if (v.abs() >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
  return v.toStringAsFixed(0);
}
