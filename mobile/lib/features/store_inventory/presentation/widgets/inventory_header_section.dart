import 'package:flutter/material.dart';

import '../../../store_sale_prices/presentation/widgets/price_ui/store_price_design_tokens.dart';
import 'app_text_field.dart';

/// Voucher header: type (Nhập/Xuất), date, note.
class InventoryHeaderSection extends StatelessWidget {
  const InventoryHeaderSection({
    super.key,
    required this.transactionType,
    required this.onTransactionTypeChanged,
    required this.transactionDate,
    required this.onPickDate,
    required this.noteController,
  });

  final int transactionType;
  final ValueChanged<int> onTransactionTypeChanged;
  final DateTime transactionDate;
  final VoidCallback onPickDate;
  final TextEditingController noteController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(StorePriceDesignTokens.sheetCardRadius),
        border: Border.all(color: StorePriceDesignTokens.borderGray),
        boxShadow: StorePriceDesignTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin phiếu',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Text(
            'Loại phiếu',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Nhập'),
                avatar: const Icon(Icons.south_west, size: 18),
                selected: transactionType == 1,
                onSelected: (_) => onTransactionTypeChanged(1),
              ),
              ChoiceChip(
                label: const Text('Xuất'),
                avatar: const Icon(Icons.north_east, size: 18),
                selected: transactionType == -1,
                onSelected: (_) => onTransactionTypeChanged(-1),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Ngày chứng từ',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(StorePriceDesignTokens.inputRadius),
              onTap: onPickDate,
              child: Ink(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(StorePriceDesignTokens.inputRadius),
                  border: Border.all(color: StorePriceDesignTokens.borderGray),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_outlined,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _formatDate(transactionDate),
                          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Icon(Icons.expand_more),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: noteController,
            label: 'Ghi chú',
            hint: 'Tuỳ chọn',
            maxLines: 2,
            maxLength: 500,
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$day/$m/$y';
  }
}
