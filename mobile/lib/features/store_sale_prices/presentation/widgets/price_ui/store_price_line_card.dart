import 'package:flutter/material.dart';

import '../../../data/models/store_sale_price_list_item.dart';
import '../../../data/vietnam_wall_time.dart';
import 'store_price_design_tokens.dart';

/// Card row for hub lists (Giá hiện hành / Lịch sử).
class StorePriceLineCard extends StatelessWidget {
  const StorePriceLineCard({
    super.key,
    required this.item,
    required this.productLabel,
    this.unitDescription,
    this.onTap,
    this.showHistoryColumns = false,
  });

  final StoreSalePriceListItem item;
  final String productLabel;
  /// Resolved label for [item.unitId], e.g. "Lít"; falls back to id in parent.
  final String? unitDescription;
  final VoidCallback? onTap;
  final bool showHistoryColumns;

  String _unitLine() {
    if (unitDescription != null && unitDescription!.trim().isNotEmpty) {
      return 'Đơn vị tính: ${unitDescription!.trim()}';
    }
    if (item.unitId != null) {
      return 'Đơn vị tính: #${item.unitId}';
    }
    return 'Đơn vị tính: —';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priceStr = VietnamWallTime.formatPriceAngular(item.price);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(StorePriceDesignTokens.cardRadius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(StorePriceDesignTokens.cardRadius),
            boxShadow: StorePriceDesignTokens.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      productLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (!showHistoryColumns && item.isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: StorePriceDesignTokens.badgeGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Đang áp dụng',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: StorePriceDesignTokens.badgeGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  if (showHistoryColumns)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (item.isCurrent
                                ? StorePriceDesignTokens.badgeGreen
                                : theme.colorScheme.outline)
                            .withValues(alpha: item.isCurrent ? 0.12 : 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.isCurrent ? 'Hiện hành' : 'Không',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: item.isCurrent
                              ? StorePriceDesignTokens.badgeGreen
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                priceStr,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: StorePriceDesignTokens.priceBlue,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _unitLine(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hiệu lực: ${VietnamWallTime.formatEffectiveLikeHub(item.effectiveDate)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ghi chú: ${(item.note != null && item.note!.trim().isNotEmpty) ? item.note! : '—'}',
                style: theme.textTheme.bodyMedium,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
