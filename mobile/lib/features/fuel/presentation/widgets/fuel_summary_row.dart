import 'package:flutter/material.dart';

import '../../../../core/formatting/vnd_currency_format.dart';
import '../../data/models/fuel_tracking_models.dart';
import 'fuel_summary_card.dart';

class FuelSummaryRow extends StatelessWidget {
  const FuelSummaryRow({super.key, required this.summary});

  final FuelSummaryUi summary;

  @override
  Widget build(BuildContext context) {
    final costFmt = formatVndCurrency(summary.totalCostDong.toDouble());
    final litersFmt = '${summary.totalLiters.toStringAsFixed(0)} Lít';
    final ckmFmt = '${formatVndCurrency(summary.costPerKmDong.toDouble())}/km';

    final cards = [
      FuelSummaryCard(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Tiền nhiên liệu',
        valueText: costFmt,
        changeText: '↑ ${summary.costChangePercent.toStringAsFixed(0)}% so với tháng trước',
        changeIsPositiveGood: false,
      ),
      FuelSummaryCard(
        icon: Icons.local_gas_station_outlined,
        label: 'Nhiên liệu',
        valueText: litersFmt,
        changeText: '↑ ${summary.literChangePercent.toStringAsFixed(0)}% so với tháng trước',
        changeIsPositiveGood: false,
      ),
      FuelSummaryCard(
        icon: Icons.speed_rounded,
        label: 'Chi phí / km',
        valueText: ckmFmt,
        changeText: '${summary.costPerKmChangePercent < 0 ? '↓' : '↑'} ${summary.costPerKmChangePercent.abs().toStringAsFixed(0)}% so với tháng trước',
        changeIsPositiveGood: summary.costPerKmChangePercent < 0,
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        const gap = 12.0;
        final wide = c.maxWidth >= 168 * 3 + gap * 2 + 8;
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: gap),
              Expanded(child: cards[1]),
              const SizedBox(width: gap),
              Expanded(child: cards[2]),
            ],
          );
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 168, child: cards[0]),
                const SizedBox(width: gap),
                SizedBox(width: 168, child: cards[1]),
                const SizedBox(width: gap),
                SizedBox(width: 168, child: cards[2]),
              ],
            ),
          ),
        );
      },
    );
  }
}
