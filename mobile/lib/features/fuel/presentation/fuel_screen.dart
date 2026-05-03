import 'package:flutter/material.dart';

import '../data/models/fuel_tracking_models.dart';
import 'widgets/fuel_insight_card.dart';
import 'widgets/fuel_summary_row.dart';
import 'widgets/fuel_transaction_history_card.dart';
import 'widgets/vehicle_selector_card.dart';

/// Nội dung cuộn của màn **Nhiên liệu** (xe + tóm tắt + nhận xét + lịch sử).
class FuelScreen extends StatelessWidget {
  const FuelScreen({
    super.key,
    required this.summary,
    required this.insight,
    required this.transactions,
    required this.bottomInset,
    required this.onSeeInsightDetail,
    required this.onSeeAllHistory,
    required this.onTransactionTap,
  });

  final FuelSummaryUi summary;
  final FuelInsightUi insight;
  final List<FuelTransactionUi> transactions;
  final double bottomInset;
  final VoidCallback onSeeInsightDetail;
  final VoidCallback onSeeAllHistory;
  final void Function(FuelTransactionUi tx) onTransactionTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [
        const VehicleSelectorCard(),
        const SizedBox(height: 18),
        FuelSummaryRow(summary: summary),
        const SizedBox(height: 18),
        FuelInsightCard(
          insight: insight,
          onSeeDetail: onSeeInsightDetail,
        ),
        const SizedBox(height: 18),
        FuelTransactionHistoryCard(
          transactions: transactions,
          onSeeAll: onSeeAllHistory,
          onItemTap: onTransactionTap,
        ),
        SizedBox(height: 88 + bottomInset),
      ],
    );
  }
}
