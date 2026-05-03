import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/widgets/gradient_button.dart';
import '../../store_sale_prices/presentation/widgets/price_ui/store_price_design_tokens.dart';
import '../data/models/store_service_catalog_item.dart';
import '../data/models/store_service_row.dart';
import '../data/store_services_repository.dart';
import 'store_service_picker_sheet.dart';
import 'store_services_providers.dart';
import 'widgets/service_list_item.dart';

class StoreServicesContent extends ConsumerWidget {
  const StoreServicesContent({super.key});

  Map<String, StoreServiceCatalogItem> _catalogMap(List<StoreServiceCatalogItem> catalog) {
    return {
      for (final c in catalog) c.serviceCode.toUpperCase(): c,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(storeServicesListProvider);
    final catalogAsync = ref.watch(storeServicesCatalogProvider);

    return listAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Không tải được danh sách dịch vụ.\n$e',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ),
      data: (rows) => catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Không tải được danh mục dịch vụ.\n$e',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (catalog) {
          final map = _catalogMap(catalog);
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  color: StorePriceDesignTokens.focusBlue,
                  onRefresh: () async {
                    ref.invalidate(storeServicesListProvider);
                    ref.invalidate(storeServicesCatalogProvider);
                    await ref.read(storeServicesListProvider.future);
                  },
                  child: rows.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(18, 24, 18, 96 + MediaQuery.paddingOf(context).bottom),
                          children: [
                            Text(
                              'Chưa có dịch vụ nào. Nhấn «Thêm dịch vụ» để chọn từ danh mục.',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    height: 1.35,
                                  ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(18, 8, 18, 96 + MediaQuery.paddingOf(context).bottom),
                          itemCount: rows.length,
                          itemBuilder: (context, i) {
                            final row = rows[i];
                            return ServiceListItem(
                              row: row,
                              catalogLookup: map[row.serviceCode.toUpperCase()],
                              onToggle: (v) => _onToggle(context, ref, row, v),
                              onPriceSave: (next) => _onPriceSave(context, ref, row, next),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _onToggle(
    BuildContext context,
    WidgetRef ref,
    StoreServiceRow row,
    bool next,
  ) async {
    try {
      await ref.read(storeServicesRepositoryProvider).updateRow(row.copyWith(isActive: next));
      ref.invalidate(storeServicesListProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không cập nhật được: $e')),
        );
      }
    }
  }

  Future<void> _onPriceSave(
    BuildContext context,
    WidgetRef ref,
    StoreServiceRow row,
    double? next,
  ) async {
    try {
      await ref.read(storeServicesRepositoryProvider).updateRow(row.copyWith(price: next));
      ref.invalidate(storeServicesListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật giá.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không lưu được giá: $e')),
        );
      }
    }
  }
}

/// Bottom bar with primary action (outside [RefreshIndicator] scroll).
class StoreServicesAddBar extends ConsumerWidget {
  const StoreServicesAddBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(storeServicesListProvider);
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    return listAsync.maybeWhen(
      data: (rows) {
        return Padding(
          padding: EdgeInsets.fromLTRB(18, 8, 18, 12 + bottomSafe),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: GradientButton(
                label: 'Thêm dịch vụ',
                trailingIcon: Icons.add_rounded,
                gradientColors: StorePriceDesignTokens.primaryGradient,
                onPressed: () => showStoreServicePickerSheet(
                  context: context,
                  ref: ref,
                  current: rows,
                ),
              ),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
