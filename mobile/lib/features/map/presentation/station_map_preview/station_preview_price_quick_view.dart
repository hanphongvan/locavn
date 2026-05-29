import 'package:flutter/material.dart';

import '../../../../core/formatting/vnd_currency_format.dart';
import '../../../station_detail/presentation/station_detail_shell_theme.dart';
import 'station_map_preview_strings.dart';

/// 2–3 compact fuel price rows for the collapsed sheet.
class StationPreviewPriceQuickView extends StatelessWidget {
  const StationPreviewPriceQuickView({
    super.key,
    required this.ron95,
    required this.diesel,
    this.e5Price,
    this.selectedFuelLabel,
    this.selectedFuelPrice,
  });

  final double? ron95;
  final double? diesel;
  final double? e5Price;

  /// Khi non-null, chỉ hiển thị 1 dòng cho fuel mobile đang lọc (đồng bộ chip "Loại nhiên liệu").
  final String? selectedFuelLabel;
  final double? selectedFuelPrice;

  @override
  Widget build(BuildContext context) {
    final rows = selectedFuelLabel != null
        ? <({String label, double? v})>[
            (label: selectedFuelLabel!, v: selectedFuelPrice),
          ]
        : <({String label, double? v})>[
            (label: StationMapPreviewStrings.labelRon95, v: ron95),
            if (e5Price != null) (label: StationMapPreviewStrings.labelE5, v: e5Price),
            (label: StationMapPreviewStrings.labelDo, v: diesel),
          ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: StationDetailShellTheme.textSecondary.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) Divider(height: 1, color: Colors.black.withValues(alpha: 0.06)),
              Padding(
                padding: EdgeInsets.only(top: i > 0 ? 8 : 0),
                child: _QuickRow(label: rows[i].label, value: rows[i].v),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickRow extends StatelessWidget {
  const _QuickRow({required this.label, required this.value});

  final String label;
  final double? value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: StationDetailShellTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Text(
          formatVndCurrency(value),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: StationDetailShellTheme.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
        ),
      ],
    );
  }
}
