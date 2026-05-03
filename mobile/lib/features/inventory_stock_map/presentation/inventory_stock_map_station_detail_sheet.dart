import 'package:flutter/material.dart';

import '../domain/stock_map_stock_status.dart';
import '../map/stock_map_station_pin.dart';

/// Compact bottom sheet: station + stock fields from [StockMapStationPin] (API-backed).
Future<void> showInventoryMapStationDetailSheet(
  BuildContext context,
  StockMapStationPin pin,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final scheme = theme.colorScheme;
      final bottom = MediaQuery.viewPaddingOf(ctx).bottom;
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 6, 20, 20 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Chi tiết trạm',
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.storefront_outlined, size: 22, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    pin.stationName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _StockStatusBadge(status: pin.status),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            Text(
              'Địa chỉ',
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              pin.address?.trim().isNotEmpty == true ? pin.address!.trim() : '—',
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.35),
            ),
            const SizedBox(height: 16),
            Text(
              'Tồn kho hiện tại',
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _formatQuantity(pin.currentQuantity),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.6,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Trạng thái (máy chủ)',
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            SelectableText(
              pin.stockStatusRaw,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.3),
            ),
          ],
        ),
      );
    },
  );
}

String _formatQuantity(double q) {
  if (q.isNaN) return '—';
  if (q == q.roundToDouble()) {
    return q.toInt().toString();
  }
  return q.toStringAsFixed(2);
}

class _StockStatusBadge extends StatelessWidget {
  const _StockStatusBadge({required this.status});

  final StockMapStockStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (String label, Color bg, Color fg) = switch (status) {
      StockMapStockStatus.out => (
          'Hết hàng',
          scheme.errorContainer,
          scheme.onErrorContainer,
        ),
      StockMapStockStatus.low => (
          'Gần hết',
          const Color(0xFFFFF8E1),
          const Color(0xFFF57F17),
        ),
      StockMapStockStatus.normal => (
          'Bình thường',
          const Color(0xFFE8F5E9),
          const Color(0xFF1B5E20),
        ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}
