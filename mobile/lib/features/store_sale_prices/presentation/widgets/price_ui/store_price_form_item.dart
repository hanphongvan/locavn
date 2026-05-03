import 'package:flutter/material.dart';

import 'store_price_app_text_field.dart';
import 'store_price_design_tokens.dart';

/// One row in "Thêm giá" batch form — layout only; parent owns controllers & submit logic.
class StorePriceFormItem extends StatelessWidget {
  const StorePriceFormItem({
    super.key,
    required this.index,
    required this.productSubtitle,
    required this.onPickProduct,
    required this.priceController,
    required this.onPriceChanged,
    required this.priceValidator,
    required this.unitId,
    required this.unitMenuItems,
    required this.onUnitChanged,
    required this.noteController,
    required this.onNoteChanged,
    required this.enabled,
    required this.showRemove,
    required this.onRemove,
  });

  final int index;
  final String? productSubtitle;
  final VoidCallback onPickProduct;
  final TextEditingController priceController;
  final void Function(String) onPriceChanged;
  final String? Function(String?)? priceValidator;
  final int? unitId;
  final List<DropdownMenuItem<int?>> unitMenuItems;
  final void Function(int?) onUnitChanged;
  final TextEditingController noteController;
  final void Function(String) onNoteChanged;
  final bool enabled;
  final bool showRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StorePriceDesignTokens.borderGray),
        boxShadow: StorePriceDesignTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Dòng ${index + 1}',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (showRemove)
                IconButton(
                  tooltip: 'Xóa dòng',
                  onPressed: enabled ? onRemove : null,
                  icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Mặt hàng', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Material(
            color: Colors.white,
            child: InkWell(
              onTap: enabled ? onPickProduct : null,
              borderRadius: BorderRadius.circular(StorePriceDesignTokens.inputRadius),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(StorePriceDesignTokens.inputRadius),
                  border: Border.all(color: StorePriceDesignTokens.borderGray),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        productSubtitle == null || productSubtitle!.trim().isEmpty
                            ? 'Chọn mặt hàng'
                            : productSubtitle!,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: productSubtitle == null || productSubtitle!.trim().isEmpty
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.primary),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          StorePriceAppTextField(
            controller: priceController,
            label: 'Giá',
            enabled: enabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: onPriceChanged,
            validator: priceValidator,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<int?>(
            value: unitId,
            decoration: StorePriceDesignTokens.inputDecoration(label: 'Đơn vị tính'),
            items: unitMenuItems,
            onChanged: enabled
                ? (v) {
                    onUnitChanged(v);
                  }
                : null,
          ),
          const SizedBox(height: 14),
          StorePriceAppTextField(
            controller: noteController,
            label: 'Ghi chú',
            enabled: enabled,
            maxLines: 2,
            maxLength: 500,
            onChanged: onNoteChanged,
          ),
        ],
      ),
    );
  }
}
