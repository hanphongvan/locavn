import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../store_sale_prices/presentation/widgets/price_ui/store_price_design_tokens.dart';
import '../data/models/store_service_catalog_item.dart';
import '../data/models/store_service_row.dart';
import 'store_service_icon.dart';
import '../data/store_services_repository.dart';
import 'store_services_providers.dart';

Future<void> showStoreServicePickerSheet({
  required BuildContext context,
  required WidgetRef ref,
  required List<StoreServiceRow> current,
}) async {
  final picked = await showModalBottomSheet<String?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Consumer(
        builder: (context, ref2, _) {
          final catAsync = ref2.watch(storeServicesCatalogProvider);
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.55,
            minChildSize: 0.35,
            maxChildSize: 0.92,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text(
                        'Chọn dịch vụ',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    Expanded(
                      child: catAsync.when(
                        data: (catalog) {
                          final codes = current.map((e) => e.serviceCode.toUpperCase()).toSet();
                          final pickable = catalog
                              .where((c) => !codes.contains(c.serviceCode.toUpperCase()))
                              .toList();
                          if (pickable.isEmpty) {
                            return Center(
                              child: Text(
                                'Đã thêm hết các dịch vụ trong danh mục.',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: pickable.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final c = pickable[i];
                              return _PickerTile(
                                item: c,
                                onTap: () => Navigator.pop(ctx, c.serviceCode),
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Không tải được danh mục.\n$e',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );

  if (picked == null || picked.isEmpty || !context.mounted) return;
  try {
    await ref.read(storeServicesRepositoryProvider).addService(picked);
    ref.invalidate(storeServicesListProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thêm dịch vụ.')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thêm được: $e')),
      );
    }
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({required this.item, required this.onTap});

  final StoreServiceCatalogItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(StorePriceDesignTokens.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(StorePriceDesignTokens.cardRadius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(StorePriceDesignTokens.cardRadius),
            border: Border.all(color: StorePriceDesignTokens.borderGray),
          ),
          child: Row(
            children: [
              Icon(storeServiceIconForCode(item.serviceCode, item.iconKey), color: StorePriceDesignTokens.focusBlue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.defaultDisplayName,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
