import 'package:flutter/material.dart';

import '../../data/models/store_service_catalog_item.dart';
import '../../data/models/store_service_row.dart';
import '../store_service_icon.dart';
import '../../../store_sale_prices/presentation/widgets/price_ui/store_price_design_tokens.dart';
import 'service_price_input.dart';
import 'service_toggle.dart';

/// One configured service: icon, name, toggle, optional price.
class ServiceListItem extends StatelessWidget {
  const ServiceListItem({
    required this.row,
    required this.catalogLookup,
    required this.onToggle,
    required this.onPriceSave,
    super.key,
  });

  final StoreServiceRow row;
  final StoreServiceCatalogItem? catalogLookup;
  final ValueChanged<bool> onToggle;
  final Future<void> Function(double? next) onPriceSave;

  bool get _supportsPrice => catalogLookup?.supportsOptionalPrice ?? true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(StorePriceDesignTokens.cardRadius),
        border: Border.all(color: StorePriceDesignTokens.borderGray),
        boxShadow: StorePriceDesignTokens.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                storeServiceIconForCode(row.serviceCode, row.iconKey ?? catalogLookup?.iconKey),
                color: StorePriceDesignTokens.focusBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.displayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    row.isActive ? 'Hiển thị cho người dùng' : 'Đang ẩn',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: row.isActive
                          ? const Color(0xFF15803D)
                          : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            ServicePriceInput(
              supportsPrice: _supportsPrice,
              price: row.price,
              onSave: onPriceSave,
            ),
            const SizedBox(width: 4),
            ServiceToggle(
              value: row.isActive,
              onChanged: onToggle,
            ),
          ],
        ),
      ),
    );
  }
}
