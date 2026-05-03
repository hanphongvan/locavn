import 'package:flutter/material.dart';

import 'map_screen_palette.dart';

class FilterChipOption<T> {
  const FilterChipOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// Nhóm chip chọn một giá trị — bo tròn, selected / unselected theo spec bộ lọc bản đồ.
class FilterChipGroup<T> extends StatelessWidget {
  const FilterChipGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<FilterChipOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final isOn = o.value == selected;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onSelected(o.value),
            borderRadius: BorderRadius.circular(22),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isOn ? MapScreenPalette.filterChipSelectedBg : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isOn ? MapScreenPalette.filterChipSelectedBorder : MapScreenPalette.filterChipBorder,
                  width: isOn ? 1.5 : 1,
                ),
              ),
              child: Text(
                o.label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isOn ? MapScreenPalette.filterChipSelectedText : MapScreenPalette.filterTextPrimary,
                    ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
