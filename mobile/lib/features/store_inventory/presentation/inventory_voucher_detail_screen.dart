import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/portal_loai.dart';
import '../../auth/presentation/widgets/login_screen_theme.dart';
import '../../store_sale_prices/data/models/store_fuel_product_lookup.dart';
import '../../store_sale_prices/data/store_sale_prices_role_guard.dart';
import '../../store_sale_prices/presentation/widgets/price_ui/store_price_design_tokens.dart';
import '../../../core/network/api_exception.dart';
import '../data/models/inventory_transaction_bundle.dart';
import '../data/models/inventory_transaction_line.dart';
import '../data/store_inventory_api.dart';
import 'store_inventory_providers.dart';

/// Chi tiết phiếu nhập/xuất: header + từng dòng (sản phẩm, SL, tiền, ĐVT, ghi chú).
class InventoryVoucherDetailScreen extends ConsumerWidget {
  const InventoryVoucherDetailScreen({super.key, required this.headerId});

  final int headerId;

  static String _phCode(int id) => 'PH${id.toString().padLeft(6, '0')}';

  static StoreFuelProductLookup? _product(List<StoreFuelProductLookup> list, int productId) {
    for (final p in list) {
      if (p.id == productId) return p;
    }
    return null;
  }

  static String _qty(InventoryTransactionLine line) {
    return NumberFormat('#,##0.##########', 'vi_VN').format(line.quantity);
  }

  static String _money(double? v) {
    if (v == null) return '—';
    return NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0).format(v);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scope = ref.watch(portalSessionScopeProvider);
    final allowed = scope?.loai == PortalLoai.store &&
        StoreSalePricesRoleGuard.canUseStoreSalePricesDataLayer(scope);

    if (headerId < 1) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết phiếu')),
        body: const Center(child: Text('Phiếu không hợp lệ.')),
      );
    }

    if (!allowed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết phiếu')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Chỉ tài khoản cửa hàng (Loai = 4) có DonViId mới xem được chi tiết.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final bundleAsync = ref.watch(inventoryTransactionBundleProvider(headerId));
    final productsAsync = ref.watch(storeInventoryProductsProvider);

    return Scaffold(
      backgroundColor: LoginScreenTheme.bgTop,
      appBar: AppBar(
        title: Text(_phCode(headerId)),
        backgroundColor: Colors.white.withValues(alpha: 0.96),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: bundleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Không tải được chi tiết phiếu.\n$e',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.error),
            ),
          ),
        ),
        data: (bundle) => productsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _DetailBody(headerId: headerId, bundle: bundle, products: const []),
          data: (products) => _DetailBody(headerId: headerId, bundle: bundle, products: products),
        ),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({
    required this.headerId,
    required this.bundle,
    required this.products,
  });

  final int headerId;
  final InventoryTransactionBundle bundle;
  final List<StoreFuelProductLookup> products;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final df = DateFormat('dd/MM/yyyy HH:mm');
    final import = bundle.transactionType == 1;
    final badgeColor = import ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: StorePriceDesignTokens.borderGray),
            boxShadow: StorePriceDesignTokens.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      import ? 'Phiếu nhập' : 'Phiếu xuất',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: badgeColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    InventoryVoucherDetailScreen._phCode(bundle.id),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _kv(theme, 'Ngày chứng từ', df.format(bundle.transactionDate.toLocal())),
              _kv(theme, 'Tổng thành tiền', InventoryVoucherDetailScreen._money(bundle.totalAmount)),
              _kv(theme, 'Số dòng', '${bundle.details.length}'),
              if ((bundle.note ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Ghi chú',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(bundle.note!.trim(), style: theme.textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Chi tiết mặt hàng',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        ...bundle.details.map((line) => _LineCard(line: line, products: products)),
        const SizedBox(height: 16),
        Text(
          'Cập nhật: ${df.format(bundle.modified.toLocal())}',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        _DeleteVoucherSection(
          headerId: headerId,
          voucherCode: InventoryVoucherDetailScreen._phCode(bundle.id),
        ),
      ],
    );
  }

  static Widget _kv(ThemeData theme, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              k,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteVoucherSection extends ConsumerStatefulWidget {
  const _DeleteVoucherSection({
    required this.headerId,
    required this.voucherCode,
  });

  final int headerId;
  final String voucherCode;

  @override
  ConsumerState<_DeleteVoucherSection> createState() => _DeleteVoucherSectionState();
}

class _DeleteVoucherSectionState extends ConsumerState<_DeleteVoucherSection> {
  bool _busy = false;

  Future<void> _onDeletePressed(BuildContext context) async {
    final theme = Theme.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa phiếu?'),
        content: Text(
          'Phiếu ${widget.voucherCode} sẽ bị xóa vĩnh viễn. Tồn kho trên sổ sẽ được tính lại theo các phiếu còn lại.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(storeInventoryApiProvider).deleteTransaction(widget.headerId);
      ref.invalidate(storeInventoryVouchersProvider);
      ref.invalidate(storeInventoryCurrentProvider);
      ref.invalidate(inventoryTransactionBundleProvider(widget.headerId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa phiếu.')));
      context.pop();
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: theme.colorScheme.error),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: theme.colorScheme.error),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _busy ? null : () => _onDeletePressed(context),
        icon: _busy
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.error),
              )
            : Icon(Icons.delete_outline, color: theme.colorScheme.error),
        label: Text(_busy ? 'Đang xóa…' : 'Xóa phiếu', style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w800)),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.error,
          side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.6)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _LineCard extends StatelessWidget {
  const _LineCard({
    required this.line,
    required this.products,
  });

  final InventoryTransactionLine line;
  final List<StoreFuelProductLookup> products;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = InventoryVoucherDetailScreen._product(products, line.productId);
    final title = p != null ? p.name : 'Mặt hàng #${line.productId}';
    final subtitle = p != null && p.code.isNotEmpty ? 'Mã: ${p.code}' : 'Mã sản phẩm: ${line.productId}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Divider(height: 20),
          _row(theme, 'Số lượng', InventoryVoucherDetailScreen._qty(line)),
          _row(
            theme,
            'Đơn vị tính',
            (line.unitName != null && line.unitName!.trim().isNotEmpty)
                ? line.unitName!.trim()
                : 'ID ${line.unitId}',
          ),
          _row(theme, 'Thành tiền', InventoryVoucherDetailScreen._money(line.amount)),
          if ((line.note ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Ghi chú dòng',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text((line.note ?? '').trim(), style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }

  static Widget _row(ThemeData theme, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              k,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
