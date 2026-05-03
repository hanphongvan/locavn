import 'package:flutter/material.dart';

import '../../data/models/fuel_tracking_models.dart';
import '../fuel_palette.dart';
import 'fuel_transaction_item.dart';

class FuelTransactionHistoryCard extends StatelessWidget {
  const FuelTransactionHistoryCard({
    super.key,
    required this.transactions,
    required this.onSeeAll,
    this.onItemTap,
  });

  final List<FuelTransactionUi> transactions;
  final VoidCallback onSeeAll;
  final void Function(FuelTransactionUi tx)? onItemTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: FuelPalette.cardWhite,
        borderRadius: BorderRadius.circular(FuelPalette.radiusLg),
        border: Border.all(color: FuelPalette.border),
        boxShadow: FuelPalette.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Lịch sử đổ nhiên liệu',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: FuelPalette.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onSeeAll,
                  child: const Text(
                    'Xem tất cả',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: FuelPalette.primaryBlue,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: transactions.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chưa có lịch sử đổ nhiên liệu',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: FuelPalette.textPrimary,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Hãy ghi đổ nhiên liệu đầu tiên của bạn',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: FuelPalette.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < transactions.length; i++)
                        InkWell(
                          onTap: onItemTap == null ? null : () => onItemTap!(transactions[i]),
                          borderRadius: BorderRadius.circular(8),
                          child: FuelTransactionItem(
                            transaction: transactions[i],
                            showDividerBelow: i < transactions.length - 1,
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
