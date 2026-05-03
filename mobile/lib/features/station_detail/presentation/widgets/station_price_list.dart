import 'package:flutter/material.dart';

import '../../../../core/formatting/vnd_currency_format.dart';
import '../../../stations/data/models/station_detail_dto.dart';
import '../station_detail_strings.dart';
import '../station_detail_formatters.dart';
import '../station_detail_shell_theme.dart';

class _PriceRow {
  const _PriceRow({required this.label, required this.valueVnd, this.when});
  final String label;
  final double? valueVnd;
  final DateTime? when;
}

/// Label left, bold price right; highlights lowest numeric price.
class StationPriceList extends StatelessWidget {
  const StationPriceList({super.key, required this.data});

  final StationDetailDto data;

  List<_PriceRow> _rows() {
    final p = data.latestReportingPrices;
    if (p != null && p.lines.isNotEmpty) {
      return p.lines.map((line) {
        final label = (line.tenThongKe ?? line.maSo ?? StationDetailStrings.priceRowFallback).trim();
        final v = line.so01 ?? line.so02 ?? line.so03;
        return _PriceRow(label: label, valueVnd: v, when: line.thoiDiemDinhGia);
      }).toList();
    }
    final out = <_PriceRow>[];
    if (data.priceRon95 != null) {
      out.add(_PriceRow(label: StationDetailStrings.labelRon95, valueVnd: data.priceRon95));
    }
    if (data.priceDiesel != null) {
      out.add(_PriceRow(label: StationDetailStrings.labelDo, valueVnd: data.priceDiesel));
    }
    return out;
  }

  double? _minValue(List<_PriceRow> rows) {
    final nums = rows.map((e) => e.valueVnd).whereType<double>().toList();
    if (nums.isEmpty) return null;
    return nums.reduce((a, b) => a < b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows();
    final theme = Theme.of(context);
    final minV = _minValue(rows);

    if (rows.isEmpty) {
      return _SectionShell(
        title: StationDetailStrings.sectionPrices,
        child: Text(
          StationDetailStrings.noPrices,
          style: theme.textTheme.bodyMedium?.copyWith(color: StationDetailShellTheme.textSecondary),
        ),
      );
    }

    return _SectionShell(
      title: StationDetailStrings.sectionPrices,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _PriceRowTile(
              row: rows[i],
              highlight: rows[i].valueVnd != null && rows[i].valueVnd == minV && minV != null,
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionShell extends StatelessWidget {
  const _SectionShell({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(StationDetailShellTheme.cardRadius),
        boxShadow: [
          BoxShadow(
            color: StationDetailShellTheme.cardShadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: StationDetailShellTheme.primary,
                  ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _PriceRowTile extends StatelessWidget {
  const _PriceRowTile({required this.row, required this.highlight});

  final _PriceRow row;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v = row.valueVnd;
    final priceText = formatVndCurrency(v);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: highlight ? StationDetailShellTheme.priceHighlightBg : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: StationDetailShellTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (row.when != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        stationDetailFormatDateTimeShort(row.when!),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: StationDetailShellTheme.textSecondary.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              priceText,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: highlight ? StationDetailShellTheme.accent : StationDetailShellTheme.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
