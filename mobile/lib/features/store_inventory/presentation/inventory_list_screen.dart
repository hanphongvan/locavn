import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../auth/presentation/widgets/gradient_button.dart';
import '../../auth/presentation/widgets/login_screen_theme.dart';
import '../../store_sale_prices/presentation/widgets/price_ui/store_price_design_tokens.dart';
import '../data/models/inventory_current_line.dart';
import '../data/store_inventory_repository.dart';
import 'store_inventory_providers.dart';

/// Store inventory hub: KPIs, tabs (vouchers / current stock), voucher list, primary action (same gradient as Giá bán).
class InventoryListScreen extends ConsumerStatefulWidget {
  const InventoryListScreen({super.key});

  @override
  ConsumerState<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends ConsumerState<InventoryListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const double _lowStockThreshold = 500;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentAsync = ref.watch(storeInventoryCurrentProvider);
    final vouchersAsync = ref.watch(storeInventoryVouchersProvider);
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                LoginScreenTheme.bgTop,
                LoginScreenTheme.bgMid,
                LoginScreenTheme.bgBottom,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                child: currentAsync.when(
                  data: (lines) => _KpiRow(
                    lines: lines,
                    lowThreshold: _lowStockThreshold,
                  ),
                  loading: () => const _KpiLoading(),
                  error: (_, _) => const _KpiLoading(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  elevation: 0,
                  shadowColor: Colors.black12,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: StorePriceDesignTokens.focusBlue,
                    unselectedLabelColor: Colors.grey.shade600,
                    indicatorColor: StorePriceDesignTokens.focusBlue,
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(text: 'Phiếu'),
                      Tab(text: 'Tồn hiện tại'),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      RefreshIndicator(
                        color: StorePriceDesignTokens.focusBlue,
                        onRefresh: () async {
                          ref.invalidate(storeInventoryVouchersProvider);
                          await ref.read(storeInventoryVouchersProvider.future);
                        },
                        child: vouchersAsync.when(
                          data: (rows) => _VoucherList(rows: rows),
                          loading: () => ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(top: 120),
                            children: const [
                              Center(child: CircularProgressIndicator()),
                            ],
                          ),
                          error: (e, _) => ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [_ErrorText('Không tải được phiếu: $e')],
                          ),
                        ),
                      ),
                      RefreshIndicator(
                        color: StorePriceDesignTokens.focusBlue,
                        onRefresh: () async {
                          ref.invalidate(storeInventoryCurrentProvider);
                          await ref.read(storeInventoryCurrentProvider.future);
                        },
                        child: currentAsync.when(
                          data: (lines) => _CurrentStockList(lines: lines),
                          loading: () => ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(top: 120),
                            children: const [
                              Center(child: CircularProgressIndicator()),
                            ],
                          ),
                          error: (e, _) => ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [_ErrorText('Không tải được tồn hiện tại: $e')],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 72 + bottomSafe),
            ],
          ),
        ),
        Positioned(
          left: 18,
          right: 18,
          bottom: 12 + bottomSafe,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: GradientButton(
                label: 'Tạo phiếu',
                trailingIcon: Icons.add_rounded,
                gradientColors: StorePriceDesignTokens.primaryGradient,
                onPressed: () => context.push(AppRoute.storeInventoryCreate),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _KpiLoading extends StatelessWidget {
  const _KpiLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 104,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({
    required this.lines,
    required this.lowThreshold,
  });

  final List<InventoryCurrentLine> lines;
  final double lowThreshold;

  @override
  Widget build(BuildContext context) {
    final total = lines.fold<double>(0, (s, e) => s + e.currentQuantity);
    final low = lines.where((e) => e.currentQuantity > 0 && e.currentQuantity < lowThreshold).length;
    final out = lines.where((e) => e.currentQuantity <= 0).length;
    final nf = NumberFormat.decimalPattern('vi_VN');

    return Row(
      children: [
        Expanded(child: _KpiCard(title: 'Tổng tồn', value: nf.format(total), color: const Color(0xFF1D4ED8))),
        const SizedBox(width: 10),
        Expanded(child: _KpiCard(title: 'Sắp hết', value: '$low', color: const Color(0xFFF59E0B))),
        const SizedBox(width: 10),
        Expanded(child: _KpiCard(title: 'Hết hàng', value: '$out', color: const Color(0xFFDC2626))),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: StorePriceDesignTokens.borderGray),
        boxShadow: StorePriceDesignTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _VoucherList extends StatelessWidget {
  const _VoucherList({required this.rows});

  final List<InventoryTransactionHeaderVm> rows;

  static String _code(int id) => 'PH${id.toString().padLeft(6, '0')}';

  static String _money(double v) {
    if (v <= 0) return '—';
    final f = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    return f.format(v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat('dd/MM/yyyy HH:mm');
    if (rows.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'Chưa có phiếu nhập/xuất.',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final vm = rows[i];
        final h = vm.header;
        final import = h.isImport;
        final badgeColor = import ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => context.push(AppRoute.storeInventoryVoucherDetail(h.id)),
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: StorePriceDesignTokens.borderGray),
                boxShadow: StorePriceDesignTokens.cardShadow,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      import ? 'Nhập' : 'Xuất',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: badgeColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _code(h.id),
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                df.format(h.transactionDate.toLocal()),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.format_list_numbered, size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    '${h.lineCount} mặt hàng',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    _money(vm.totalAmount),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: StorePriceDesignTokens.priceBlue,
                    ),
                  ),
                ],
              ),
              if ((h.note ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  h.note!.trim(),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CurrentStockList extends StatelessWidget {
  const _CurrentStockList({required this.lines});

  final List<InventoryCurrentLine> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nf = NumberFormat.decimalPattern('vi_VN');
    if (lines.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'Chưa có dữ liệu tồn theo sổ.',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: lines.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final l = lines[i];
        final unit = (l.unitTen ?? l.unitMa ?? '').trim();
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: StorePriceDesignTokens.borderGray),
            boxShadow: StorePriceDesignTokens.cardShadow,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.productName,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.productCode,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    nf.format(l.currentQuantity),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  if (unit.isNotEmpty)
                    Text(
                      unit,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.red.shade800),
      ),
    );
  }
}
