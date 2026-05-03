import 'package:flutter/material.dart';

import '../../data/models/fuel_tracking_models.dart';
import '../fuel_palette.dart';

class FuelInsightCard extends StatelessWidget {
  const FuelInsightCard({
    super.key,
    required this.insight,
    required this.onSeeDetail,
  });

  final FuelInsightUi insight;
  final VoidCallback onSeeDetail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FuelPalette.cardWhite,
            FuelPalette.primaryBlue.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(FuelPalette.radiusLg),
        border: Border.all(color: FuelPalette.border),
        boxShadow: FuelPalette.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: FuelPalette.accentGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.directions_car_rounded, color: FuelPalette.accentGreen, size: 26),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Nhận xét',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: FuelPalette.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: onSeeDetail,
                child: const Text(
                  'Xem chi tiết',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: FuelPalette.primaryBlue,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            insight.mainComment,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: FuelPalette.textPrimary,
              height: 1.45,
            ),
          ),
          if (insight.secondaryInsight.trim().isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, color: FuelPalette.border),
            ),
            Text(
              insight.secondaryInsight,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: FuelPalette.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
