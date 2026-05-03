import 'package:flutter/material.dart';

import '../data/map_filters.dart';
import 'map_screen_palette.dart';

/// Slider khoảng giá (đồng/lít) + dòng chữ “Từ … – …”.
class MapFilterPriceRangeSlider extends StatelessWidget {
  const MapFilterPriceRangeSlider({
    super.key,
    required this.minDong,
    required this.maxDong,
    required this.onChanged,
  });

  final int minDong;
  final int maxDong;
  final void Function(int min, int max) onChanged;

  @override
  Widget build(BuildContext context) {
    final lo = MapFilters.priceSliderMinDong.toDouble();
    final hi = MapFilters.priceSliderMaxDong.toDouble();
    final start = minDong.toDouble().clamp(lo, hi);
    final end = maxDong.toDouble().clamp(lo, hi);
    final safeStart = start <= end ? start : end;
    final safeEnd = end >= start ? end : start;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RangeSlider(
          min: lo,
          max: hi,
          divisions: 39,
          values: RangeValues(safeStart, safeEnd),
          activeColor: MapScreenPalette.filterPrimary,
          inactiveColor: MapScreenPalette.filterChipBorder,
          onChanged: (rv) {
            onChanged(rv.start.round(), rv.end.round());
          },
        ),
        const SizedBox(height: 4),
        Text(
          'Từ ${MapFilters.formatDongVnd(minDong)} – ${MapFilters.formatDongVnd(maxDong)}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: MapScreenPalette.filterTextSecondary,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
