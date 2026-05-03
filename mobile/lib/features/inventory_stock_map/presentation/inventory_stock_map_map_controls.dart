import 'package:flutter/material.dart';

import '../data/inventory_map_group_code.dart';

/// Floating filter + stock legend — compact, map-first chrome.
class InventoryStockMapMapControls extends StatelessWidget {
  const InventoryStockMapMapControls({
    super.key,
    required this.selectedGroup,
    required this.onGroupSelected,
  });

  final String selectedGroup;
  final ValueChanged<String> onGroupSelected;

  static const Color _legendOut = Color(0xFFC62828);
  static const Color _legendLow = Color(0xFFF9A825);
  static const Color _legendNormal = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onVar = scheme.onSurfaceVariant;

    return Material(
      elevation: 3,
      shadowColor: Colors.black26,
      color: scheme.surface.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 5, 6, 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(
                  value: InventoryMapGroupCode.xang,
                  label: Text('Xăng'),
                  icon: Icon(Icons.local_gas_station_outlined, size: 16),
                ),
                ButtonSegment<String>(
                  value: InventoryMapGroupCode.dau,
                  label: Text('Dầu'),
                  icon: Icon(Icons.oil_barrel_outlined, size: 16),
                ),
              ],
              emptySelectionAllowed: false,
              showSelectedIcon: false,
              selected: <String>{selectedGroup},
              onSelectionChanged: (next) => onGroupSelected(next.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                // a11y: giữ Material default tap target ≥ 48dp cho từng segment.
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 2),
              child: Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.45)),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _LegendChip(color: _legendOut, text: 'đỏ = hết hàng', onVar: onVar),
                _LegendChip(color: _legendLow, text: 'vàng = gần hết', onVar: onVar),
                _LegendChip(color: _legendNormal, text: 'xanh = bình thường', onVar: onVar),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.color,
    required this.text,
    required this.onVar,
  });

  final Color color;
  final String text;
  final Color onVar;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: onVar,
          height: 1.2,
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 2,
                offset: const Offset(0, 0.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Text(text, style: style),
      ],
    );
  }
}
