import 'package:flutter/material.dart';

import '../../../store_sale_prices/data/models/store_don_vi_tinh_lookup.dart';
import '../../../store_sale_prices/data/models/store_fuel_product_lookup.dart';
import '../../../store_sale_prices/presentation/widgets/price_ui/store_price_design_tokens.dart';
import 'app_text_field.dart';
import 'vn_grouped_number_input_formatter.dart';

/// One detail line: product, quantity, unit, amount, note, delete.
class InventoryItemRow extends StatelessWidget {
  const InventoryItemRow({
    super.key,
    required this.index,
    required this.products,
    required this.units,
    required this.productId,
    required this.onProductChanged,
    required this.quantityController,
    required this.useProductDefaultUnit,
    required this.onUseDefaultUnitChanged,
    required this.unitId,
    required this.onUnitChanged,
    required this.amountController,
    required this.noteController,
    required this.onDelete,
    required this.canDelete,
    required this.excludeProductIds,
  });

  final int index;
  final List<StoreFuelProductLookup> products;
  final List<StoreDonViTinhLookup> units;
  final int? productId;
  final ValueChanged<int?> onProductChanged;
  final TextEditingController quantityController;
  final bool useProductDefaultUnit;
  final ValueChanged<bool> onUseDefaultUnitChanged;
  final int? unitId;
  final ValueChanged<int?> onUnitChanged;
  final TextEditingController amountController;
  final TextEditingController noteController;
  final VoidCallback onDelete;
  final bool canDelete;
  final Set<int> excludeProductIds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availableProducts =
        products.where((p) => p.id == productId || !excludeProductIds.contains(p.id)).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(StorePriceDesignTokens.sheetCardRadius),
        border: Border.all(color: StorePriceDesignTokens.borderGray),
        boxShadow: StorePriceDesignTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Dòng ${index + 1}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: StorePriceDesignTokens.focusBlue,
                  ),
                ),
              ),
              const Spacer(),
              IconButton.filledTonal(
                onPressed: canDelete ? onDelete : null,
                icon: const Icon(Icons.delete_outline),
                tooltip: canDelete ? 'Xóa dòng' : 'Cần ít nhất một dòng',
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            value: productId, // ignore: deprecated_member_use
            decoration: StorePriceDesignTokens.inputDecoration(label: 'Sản phẩm'),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('— Chọn —'),
              ),
              ...availableProducts.map(
                (p) => DropdownMenuItem<int?>(
                  value: p.id,
                  child: Text('${p.code} — ${p.name}', overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: onProductChanged,
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Đơn vị tính mặc định của sản phẩm',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            value: useProductDefaultUnit,
            onChanged: onUseDefaultUnitChanged,
          ),
          if (!useProductDefaultUnit) ...[
            const SizedBox(height: 4),
            DropdownButtonFormField<int?>(
              value: unitId != null && unitId! > 0 ? unitId : null, // ignore: deprecated_member_use
              decoration: StorePriceDesignTokens.inputDecoration(label: 'Đơn vị tính'),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('— Chọn —'),
                ),
                ...units.map(
                  (u) => DropdownMenuItem<int?>(
                    value: u.id,
                    child: Text(
                      (u.ten != null && u.ten!.trim().isNotEmpty)
                          ? u.ten!.trim()
                          : (u.ma ?? '').trim(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: onUnitChanged,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: quantityController,
                  label: 'Số lượng',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    VnGroupedNumberInputFormatter(maxFractionDigits: 6),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  controller: amountController,
                  label: 'Thành tiền',
                  hint: 'Tuỳ chọn',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    VnGroupedNumberInputFormatter(maxFractionDigits: 2),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: noteController,
            label: 'Ghi chú dòng',
            hint: 'Tuỳ chọn',
            maxLines: 2,
            maxLength: 500,
          ),
        ],
      ),
    );
  }
}
