import 'package:flutter/material.dart';

import '../../../../core/formatting/vnd_currency_format.dart' show formatVndCurrency, formatVndIntegerDigits;
import '../../data/models/fuel_tracking_models.dart';
import '../fuel_palette.dart';

String _fuelDateLabel(DateTime d) {
  const months = ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12'];
  return '${d.day} Th${months[d.month - 1]}';
}

String _odometerLine(double? km) {
  if (km == null) return 'Số km công tơ —';
  return 'Số km công tơ ${formatVndIntegerDigits(km)} km';
}

Widget _fuelMetricRow({
  required IconData icon,
  required String text,
  required TextStyle style,
  double gapAfter = 6,
}) {
  return Padding(
    padding: EdgeInsets.only(bottom: gapAfter),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: FuelPalette.primaryBlue.withValues(alpha: 0.85)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: style),
        ),
      ],
    ),
  );
}

class FuelTransactionItem extends StatelessWidget {
  const FuelTransactionItem({
    super.key,
    required this.transaction,
    this.showDividerBelow = true,
    this.showChevron = true,
    this.trailing,
  });

  final FuelTransactionUi transaction;
  final bool showDividerBelow;
  final bool showChevron;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final amount = formatVndCurrency(transaction.amountDong.toDouble());
    final liters = transaction.liters.toStringAsFixed(2).replaceAll('.', ',');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                child: Text(
                  _fuelDateLabel(transaction.transactionDate),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: FuelPalette.textPrimary,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fuelMetricRow(
                      icon: Icons.payments_rounded,
                      text: amount,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: FuelPalette.textPrimary,
                        height: 1.25,
                      ),
                      gapAfter: 8,
                    ),
                    _fuelMetricRow(
                      icon: Icons.opacity_rounded,
                      text: '$liters lít',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: FuelPalette.textSecondary,
                        height: 1.35,
                      ),
                      gapAfter: 6,
                    ),
                    _fuelMetricRow(
                      icon: Icons.speed_rounded,
                      text: _odometerLine(transaction.odometerKm),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: FuelPalette.textSecondary,
                        height: 1.35,
                      ),
                      gapAfter: 0,
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (showChevron)
                const Icon(Icons.chevron_right_rounded, color: FuelPalette.textSecondary, size: 26),
            ],
          ),
        ),
        if (showDividerBelow) const Divider(height: 1, color: FuelPalette.border),
      ],
    );
  }
}
