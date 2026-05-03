import 'package:flutter/material.dart';

import '../fuel_palette.dart';

class FuelSummaryCard extends StatelessWidget {
  const FuelSummaryCard({
    super.key,
    required this.icon,
    required this.label,
    required this.valueText,
    required this.changeText,
    required this.changeIsPositiveGood,
  });

  final IconData icon;
  final String label;
  final String valueText;
  final String changeText;

  /// `true` = giảm chi phí / km → màu xanh; `false` = tăng → đỏ (so với tháng trước).
  final bool changeIsPositiveGood;

  @override
  Widget build(BuildContext context) {
    final changeColor = changeIsPositiveGood ? FuelPalette.greenChange : FuelPalette.redChange;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: FuelPalette.cardWhite,
        borderRadius: BorderRadius.circular(FuelPalette.radiusMd),
        border: Border.all(color: FuelPalette.border),
        boxShadow: FuelPalette.cardShadow(context),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: FuelPalette.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: FuelPalette.primaryBlue, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: FuelPalette.textSecondary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      changeText,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: changeColor,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              valueText,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: FuelPalette.textPrimary,
                letterSpacing: -0.3,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
