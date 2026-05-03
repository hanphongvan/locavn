import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/portal_loai.dart';
import '../../auth/presentation/widgets/login_screen_theme.dart';
import '../../store_sale_prices/data/store_sale_prices_role_guard.dart';
import '../../store_sale_prices/presentation/vn_price_input.dart';
import '../data/store_inventory_repository.dart';
import 'store_inventory_providers.dart';
import 'widgets/gradient_button.dart';
import 'widgets/inventory_header_section.dart';
import 'widgets/inventory_item_row.dart';

class _FormLine {
  _FormLine() : key = _nextKey++ ;
  static int _nextKey = 0;
  final int key;
  int? productId;
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  bool useProductDefaultUnit = true;
  int? unitId;

  void dispose() {
    quantityController.dispose();
    amountController.dispose();
    noteController.dispose();
  }
}

/// Create inventory voucher (POST existing API).
class InventoryFormScreen extends ConsumerStatefulWidget {
  const InventoryFormScreen({super.key});

  @override
  ConsumerState<InventoryFormScreen> createState() => _InventoryFormScreenState();
}

class _InventoryFormScreenState extends ConsumerState<InventoryFormScreen> {
  int _transactionType = 1;
  DateTime _transactionDate = DateTime.now();
  final _noteController = TextEditingController();
  final _lines = <_FormLine>[_FormLine()];
  bool _saving = false;

  @override
  void dispose() {
    _noteController.dispose();
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _transactionDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _transactionDate = picked);
    }
  }

  Set<int> _excludeForLine(_FormLine line) {
    final s = <int>{};
    for (final other in _lines) {
      if (identical(other, line)) continue;
      if (other.productId != null) s.add(other.productId!);
    }
    return s;
  }

  Future<void> _save() async {
    final scope = ref.read(portalSessionScopeProvider);
    if (scope?.loai != PortalLoai.store ||
        !StoreSalePricesRoleGuard.canUseStoreSalePricesDataLayer(scope)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chỉ tài khoản cửa hàng (Loai = 4) được tạo phiếu.')),
      );
      return;
    }
    final donViId = scope!.donViId;
    if (donViId == null || donViId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thiếu DonViId cửa hàng.')),
      );
      return;
    }

    final details = <Map<String, dynamic>>[];
    final seenProducts = <int>{};
    for (final line in _lines) {
      final pid = line.productId;
      if (pid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chọn sản phẩm cho mỗi dòng.')),
        );
        return;
      }
      if (seenProducts.contains(pid)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không được trùng sản phẩm trong cùng phiếu.')),
        );
        return;
      }
      seenProducts.add(pid);
      final qty = double.tryParse(line.quantityController.text.trim().replaceAll(',', '.'));
      if (qty == null || qty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Số lượng mỗi dòng phải > 0.')),
        );
        return;
      }
      if (!line.useProductDefaultUnit && (line.unitId == null || line.unitId! < 1)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chọn đơn vị tính hoặc bật ĐVT mặc định sản phẩm.')),
        );
        return;
      }
      final amtRaw = line.amountController.text.trim();
      double? amount;
      if (amtRaw.isNotEmpty) {
        amount = parseVnDecimalInput(amtRaw, maxFractionDigits: 2);
        if (amount == null || amount < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thành tiền không hợp lệ.')),
          );
          return;
        }
      }
      final note = line.noteController.text.trim();
      details.add({
        'productId': pid,
        'unitId': line.useProductDefaultUnit ? 0 : line.unitId,
        'useProductDefaultUnit': line.useProductDefaultUnit,
        'quantity': qty,
        'amount': amount,
        if (note.isNotEmpty) 'note': note,
      });
    }

    final body = <String, dynamic>{
      'donViId': donViId,
      'transactionType': _transactionType,
      'transactionDate': DateTime.utc(
        _transactionDate.year,
        _transactionDate.month,
        _transactionDate.day,
        12,
      ).toIso8601String(),
      if (_noteController.text.trim().isNotEmpty) 'note': _noteController.text.trim(),
      'details': details,
    };

    setState(() => _saving = true);
    try {
      await ref.read(storeInventoryRepositoryProvider).createVoucher(body);
      ref.invalidate(storeInventoryVouchersProvider);
      ref.invalidate(storeInventoryCurrentProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu phiếu.')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không lưu được: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = ref.watch(portalSessionScopeProvider);
    final allowed =
        scope?.loai == PortalLoai.store && StoreSalePricesRoleGuard.canUseStoreSalePricesDataLayer(scope);

    if (!allowed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tạo phiếu')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Chỉ tài khoản cửa hàng (Loai = 4) có DonViId mới dùng được tính năng này.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final productsAsync = ref.watch(storeInventoryProductsProvider);
    final unitsAsync = ref.watch(storeInventoryUnitsProvider);

    return Scaffold(
      backgroundColor: LoginScreenTheme.bgTop,
      appBar: AppBar(
        title: const Text('Tạo phiếu'),
        backgroundColor: Colors.white.withValues(alpha: 0.96),
        surfaceTintColor: Colors.transparent,
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Không tải sản phẩm: $e')),
        data: (products) => unitsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Không tải đơn vị: $e')),
          data: (units) => Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                  children: [
                    InventoryHeaderSection(
                      transactionType: _transactionType,
                      onTransactionTypeChanged: (v) => setState(() => _transactionType = v),
                      transactionDate: _transactionDate,
                      onPickDate: _pickDate,
                      noteController: _noteController,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Text(
                          'Chi tiết hàng',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => setState(() => _lines.add(_FormLine())),
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm dòng'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._lines.asMap().entries.map((e) {
                      final i = e.key;
                      final line = e.value;
                      return InventoryItemRow(
                        key: ValueKey(line.key),
                        index: i,
                        products: products,
                        units: units,
                        productId: line.productId,
                        onProductChanged: (v) => setState(() => line.productId = v),
                        quantityController: line.quantityController,
                        useProductDefaultUnit: line.useProductDefaultUnit,
                        onUseDefaultUnitChanged: (v) => setState(() {
                          line.useProductDefaultUnit = v;
                          if (v) line.unitId = null;
                        }),
                        unitId: line.unitId,
                        onUnitChanged: (v) => setState(() => line.unitId = v),
                        amountController: line.amountController,
                        noteController: line.noteController,
                        canDelete: _lines.length > 1,
                        onDelete: () {
                          setState(() {
                            line.dispose();
                            _lines.removeAt(i);
                          });
                        },
                        excludeProductIds: _excludeForLine(line),
                      );
                    }),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.97),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving ? null : () => context.pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Huỷ', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: GradientButton(
                          label: 'Lưu phiếu',
                          icon: Icons.save_outlined,
                          loading: _saving,
                          onPressed: _saving ? null : () => _save(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
