import 'package:flutter/material.dart';

import '../../../store_sale_prices/presentation/widgets/price_ui/store_price_design_tokens.dart';

final Object _clearPriceToken = Object();

/// Optional price: tap to edit in a lightweight dialog.
class ServicePriceInput extends StatelessWidget {
  const ServicePriceInput({
    required this.supportsPrice,
    required this.price,
    required this.onSave,
    super.key,
  });

  final bool supportsPrice;
  final double? price;
  final Future<void> Function(double? next) onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!supportsPrice) {
      return Text(
        '—',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final label = price == null ? 'Thêm giá' : _formatVnd(price!);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openEditor(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: StorePriceDesignTokens.borderGray),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.payments_outlined,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: price == null
                      ? StorePriceDesignTokens.focusBlue
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openEditor(BuildContext context) async {
    final controller = TextEditingController(
      text: price == null ? '' : _formatThousands(price!),
    );
    final outcome = await showDialog<Object?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Giá dịch vụ'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: StorePriceDesignTokens.inputDecoration(
              label: 'Số tiền (đồng)',
              hint: 'Để trống nếu không niêm yết',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                final raw = controller.text.trim();
                if (raw.isEmpty) {
                  Navigator.pop(ctx, _clearPriceToken);
                  return;
                }
                final parsed = double.tryParse(raw.replaceAll(',', '').replaceAll('.', ''));
                if (parsed == null || parsed < 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Giá không hợp lệ.')),
                  );
                  return;
                }
                Navigator.pop(ctx, parsed);
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );

    if (!context.mounted || outcome == null) return;
    final resolved = outcome == _clearPriceToken ? null : outcome as double;
    await onSave(resolved);
  }

  static String _formatVnd(double v) {
    final s = v.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write('.');
    }
    return '${buf.toString()} đ';
  }

  static String _formatThousands(double v) => v.round().toString();
}
