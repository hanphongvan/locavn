import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/widgets/gradient_button.dart';
import '../../auth/presentation/widgets/login_screen_theme.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/portal_session_scope.dart';
import '../../../core/network/api_exception.dart';
import '../data/models/store_admin_fuel_product_list_item.dart';
import '../data/models/store_sale_price_list_item.dart';
import '../data/store_sale_prices_repository.dart';
import '../data/vietnam_wall_time.dart';
import 'store_sale_prices_providers.dart';
import 'widgets/price_ui/store_price_design_tokens.dart';
import 'widgets/price_ui/store_price_line_card.dart';
import 'widgets/sale_price_batch_entry_sheet.dart';
import 'widgets/sale_price_edit_sheet.dart';

/// Hub: tab Giá hiện hành / Lịch sử + FAB Thêm giá (UI đồng bộ login/dashboard).
class StoreSalePricesHubPage extends ConsumerStatefulWidget {
  const StoreSalePricesHubPage({super.key});

  @override
  ConsumerState<StoreSalePricesHubPage> createState() => _StoreSalePricesHubPageState();
}

class _StoreSalePricesHubPageState extends ConsumerState<StoreSalePricesHubPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  int? _historyFocusProductId;

  StoreSalePricesHubQuery get _hubQuery => StoreSalePricesHubQuery(
        historyFocusProductId: _historyFocusProductId,
      );

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _onCurrentTableRowTap(StoreSalePriceListItem item) {
    setState(() => _historyFocusProductId = item.productId);
    ref.invalidate(storeSalePricesHubProvider(_hubQuery));
    if (_tabs.index != 1) {
      _tabs.animateTo(1);
    }
  }

  void _clearHistoryProductFilter() {
    setState(() => _historyFocusProductId = null);
    ref.invalidate(storeSalePricesHubProvider(_hubQuery));
  }

  Future<void> _openAddSheet(int donViId) async {
    ref.invalidate(storeSalePriceFormLookupsProvider);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.92,
        child: SalePriceBatchEntrySheet(sessionDonViId: donViId),
      ),
    );
    if (ok == true && mounted) {
      ref.invalidate(storeSalePricesHubProvider(_hubQuery));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu giá bán.')),
      );
    }
  }

  Future<void> _openEditSheet(StoreSalePriceListItem item, int donViId, PortalSessionScope scope) async {
    if (!StoreSalePricesRepository.canEditSalePriceListItem(item: item, scope: scope)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không được phép sửa bản ghi này.')),
      );
      return;
    }
    if (!mounted) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final repo = ref.read(storeSalePricesRepositoryProvider);
      final detail = await repo.loadDetailForSessionStore(item.id);
      if (!mounted) {
        if (navigator.canPop()) navigator.pop();
        return;
      }
      if (navigator.canPop()) navigator.pop();
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final ok = await showModalBottomSheet<bool>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (ctx) => FractionallySizedBox(
          heightFactor: 0.92,
          child: SalePriceEditSheet(detail: detail, sessionDonViId: donViId),
        ),
      );
      if (ok == true && mounted) {
        ref.invalidate(storeSalePricesHubProvider(_hubQuery));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật giá bán.')),
        );
      }
    } on Object catch (e) {
      if (navigator.canPop()) navigator.pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is ApiException ? e.message : '$e')),
        );
      }
    }
  }

  Map<int, String> _productLabelMap(List<StoreAdminFuelProductListItem> products) {
    final m = <int, String>{};
    for (final p in products) {
      m[p.id] = VietnamWallTime.hubProductLabel(p.name);
    }
    return m;
  }

  String _productLabel(Map<int, String> labels, StoreSalePriceListItem item) {
    final s = labels[item.productId];
    if (s != null && s.trim().isNotEmpty) {
      return s;
    }
    return 'Mặt hàng #${item.productId}';
  }

  Map<int, String> _unitLabelMap() {
    final lu = ref.watch(storeSalePriceFormLookupsProvider).valueOrNull;
    if (lu == null) return {};
    return {
      for (final u in lu.uniqueUnitsById)
        u.id: '${u.ma ?? ''} — ${u.ten ?? ''}'.trim().isEmpty ? 'Id ${u.id}' : '${u.ma ?? ''} — ${u.ten ?? ''}'.trim(),
    };
  }

  String? _unitDescription(Map<int, String> unitLabels, StoreSalePriceListItem item) {
    if (item.unitId == null) return null;
    return unitLabels[item.unitId];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // `donViId` cùng giá trị với `session.donViId`; lấy qua `scope` để tránh
    // watch toàn bộ AuthSessionController.
    final scope = ref.watch(portalSessionScopeProvider);
    final donViId = scope?.donViId;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    final catalog = ref.watch(storeSalePricesHubCatalogProvider);
    final labels = catalog.maybeWhen(
      data: (StoreSalePricesHubCatalog c) => _productLabelMap(c.products),
      orElse: () => <int, String>{},
    );
    final unitLabels = _unitLabelMap();

    final hub = ref.watch(storeSalePricesHubProvider(_hubQuery));

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            LoginScreenTheme.bgTop,
            LoginScreenTheme.bgMid,
            LoginScreenTheme.bgBottom,
          ],
        ),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Material(
                  color: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.black.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: StorePriceDesignTokens.cardShadow,
                    ),
                    child: TabBar(
                      controller: _tabs,
                      dividerColor: Colors.transparent,
                      labelColor: StorePriceDesignTokens.focusBlue,
                      unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                      labelStyle: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      unselectedLabelStyle: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: const Color(0xFFEFF6FF),
                      ),
                      tabs: const [
                        Tab(text: 'Giá hiện hành'),
                        Tab(text: 'Lịch sử'),
                      ],
                    ),
                  ),
                ),
              ),
              if (_historyFocusProductId != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Đang lọc mặt hàng #$_historyFocusProductId.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _clearHistoryProductFilter,
                            child: const Text('Bỏ lọc mặt hàng'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: hub.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        e is ApiException ? e.message : '$e',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  data: (data) {
                    return TabBarView(
                      controller: _tabs,
                      children: [
                        _PriceListPanel(
                          items: data.current,
                          emptyMessage: 'Không có dòng giá hiện hành.',
                          productLabel: (item) => _productLabel(labels, item),
                          unitDescription: (item) => _unitDescription(unitLabels, item),
                          showHistoryColumns: false,
                          onRefresh: () async {
                            ref.invalidate(storeSalePricesHubCatalogProvider);
                            ref.invalidate(storeSalePricesHubProvider(_hubQuery));
                            await ref.read(storeSalePricesHubProvider(_hubQuery).future);
                          },
                          onRowTap: _onCurrentTableRowTap,
                        ),
                        _PriceListPanel(
                          items: data.history,
                          emptyMessage: 'Không có lịch sử.',
                          productLabel: (item) => _productLabel(labels, item),
                          unitDescription: (item) => _unitDescription(unitLabels, item),
                          showHistoryColumns: true,
                          onRefresh: () async {
                            ref.invalidate(storeSalePricesHubCatalogProvider);
                            ref.invalidate(storeSalePricesHubProvider(_hubQuery));
                            await ref.read(storeSalePricesHubProvider(_hubQuery).future);
                          },
                          onRowTap: donViId != null && scope != null
                              ? (item) => _openEditSheet(item, donViId, scope)
                              : null,
                        ),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(height: 72 + bottomSafe),
            ],
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 12 + bottomSafe,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: GradientButton(
                  label: 'Thêm giá',
                  trailingIcon: Icons.add_rounded,
                  gradientColors: StorePriceDesignTokens.primaryGradient,
                  onPressed: donViId == null ? null : () => _openAddSheet(donViId),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceListPanel extends StatelessWidget {
  const _PriceListPanel({
    required this.items,
    required this.emptyMessage,
    required this.productLabel,
    required this.unitDescription,
    required this.onRefresh,
    required this.showHistoryColumns,
    this.onRowTap,
  });

  final List<StoreSalePriceListItem> items;
  final String emptyMessage;
  final String Function(StoreSalePriceListItem) productLabel;
  final String? Function(StoreSalePriceListItem) unitDescription;
  final Future<void> Function() onRefresh;
  final bool showHistoryColumns;
  final void Function(StoreSalePriceListItem)? onRowTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.5,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  emptyMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          final item = items[i];
          return StorePriceLineCard(
            item: item,
            productLabel: productLabel(item),
            unitDescription: unitDescription(item),
            onTap: onRowTap == null ? null : () => onRowTap!(item),
            showHistoryColumns: showHistoryColumns,
          );
        },
      ),
    );
  }
}
