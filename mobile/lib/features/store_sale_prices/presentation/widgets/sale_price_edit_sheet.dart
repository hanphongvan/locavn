import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/models/store_fuel_product_lookup.dart';
import '../../data/models/store_sale_price_detail.dart';
import '../../data/models/store_sale_price_upsert_request.dart';
import '../../data/sale_price_json_parsing.dart';
import '../../data/store_sale_prices_exceptions.dart';
import '../../data/store_sale_prices_repository.dart';
import '../store_sale_prices_providers.dart' show storeSalePriceFormLookupsProvider, StoreSalePriceFormLookups;
import '../vn_price_input.dart';

/// Bottom sheet: single-line update (`PUT /api/admin/store-prices/{id}`) — Angular `/:id/edit`.
class SalePriceEditSheet extends ConsumerStatefulWidget {
  const SalePriceEditSheet({
    super.key,
    required this.detail,
    required this.sessionDonViId,
  });

  final StoreSalePriceDetail detail;
  final int sessionDonViId;

  @override
  ConsumerState<SalePriceEditSheet> createState() => _SalePriceEditSheetState();
}

class _SalePriceEditSheetState extends ConsumerState<SalePriceEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _effectiveAt;
  late bool _isCurrent;
  final _price = TextEditingController();
  final _note = TextEditingController();
  StoreFuelProductLookup? _product;
  int? _unitId;
  var _dirty = false;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.detail;
    _effectiveAt = d.effectiveDate.toLocal();
    _isCurrent = d.isCurrent;
    _price.text = formatVnPriceDisplay(d.price);
    _note.text = d.note ?? '';
    _unitId = d.unitId;
  }

  @override
  void dispose() {
    _price.dispose();
    _note.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _pickProduct() async {
    final lookups = ref.read(storeSalePriceFormLookupsProvider).valueOrNull;
    if (lookups == null) return;
    final chosen = await showModalBottomSheet<StoreFuelProductLookup>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ProductPickerSheetEdit(products: lookups.products),
    );
    if (chosen != null && mounted) {
      setState(() {
        _product = chosen;
        _unitId = chosen.unitId ?? _unitId;
        _dirty = true;
      });
    }
  }

  Future<void> _pickEffective() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _effectiveAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_effectiveAt),
    );
    if (t == null || !mounted) return;
    setState(() {
      _effectiveAt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
      _dirty = true;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final p = _product;
    if (p == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn mặt hàng.')),
      );
      return;
    }
    final priceVal = parseVnDecimalInput(_price.text);
    if (priceVal == null || priceVal < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giá không hợp lệ.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(storeSalePricesRepositoryProvider);
      await repo.updateSingle(
        widget.detail.id,
        StoreSalePriceUpsertRequest(
          donViId: widget.sessionDonViId,
          productId: p.id,
          price: SalePriceJsonParsing.roundPriceForApi(priceVal),
          unitId: _unitId,
          effectiveDate: _effectiveAt,
          isCurrent: _isCurrent,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on StoreSalePricesAccessException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _confirmDiscard() async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bỏ thay đổi?'),
        content: const Text('Bạn có thay đổi chưa lưu. Thoát và hủy các thay đổi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ở lại')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Thoát')),
        ],
      ),
    );
    return r == true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lookups = ref.watch(storeSalePriceFormLookupsProvider);
    _product ??= _productFromLookups(lookups.valueOrNull, widget.detail.productId);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Sửa giá bán',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        if (!_dirty) {
                          Navigator.pop(context);
                          return;
                        }
                        if (await _confirmDiscard() && context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Mặt hàng'),
                        subtitle: Text(
                          _product == null
                              ? 'Đang tải…'
                              : '${_product!.code} — ${_product!.name}',
                          maxLines: 2,
                        ),
                        trailing: const Icon(Icons.edit_outlined),
                        onTap: _saving ? null : _pickProduct,
                      ),
                      TextFormField(
                        controller: _price,
                        enabled: !_saving,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Giá',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => _markDirty(),
                        validator: (s) {
                          final v = parseVnDecimalInput(s ?? '');
                          if (v == null) return 'Nhập giá hợp lệ';
                          if (v < 0) return 'Giá phải ≥ 0';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int?>(
                        value: _unitId,
                        decoration: const InputDecoration(
                          labelText: 'Đơn vị tính',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('— (không chọn) —'),
                          ),
                          if (lookups.valueOrNull != null)
                            ...lookups.valueOrNull!.uniqueUnitsById.map(
                              (u) => DropdownMenuItem<int?>(
                                value: u.id,
                                child: Text(
                                  '${u.ma ?? ''} — ${u.ten ?? ''}'.trim().isEmpty
                                      ? '${u.id}'
                                      : '${u.ma ?? ''} — ${u.ten ?? ''}'.trim(),
                                ),
                              ),
                            ),
                        ],
                        onChanged: _saving || lookups.valueOrNull == null
                            ? null
                            : (v) => setState(() {
                                  _unitId = v;
                                  _dirty = true;
                                }),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Ngày hiệu lực'),
                        subtitle: Text(
                          '${MaterialLocalizations.of(context).formatFullDate(_effectiveAt)} '
                          '${TimeOfDay.fromDateTime(_effectiveAt).format(context)}',
                        ),
                        trailing: const Icon(Icons.event),
                        onTap: _saving ? null : _pickEffective,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Hiện hành (IsCurrent)'),
                        value: _isCurrent,
                        onChanged: _saving
                            ? null
                            : (v) => setState(() {
                                  _isCurrent = v;
                                  _dirty = true;
                                }),
                      ),
                      TextFormField(
                        controller: _note,
                        enabled: !_saving,
                        maxLength: 500,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Ghi chú',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => _markDirty(),
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () async {
                                  if (!_dirty) {
                                    Navigator.pop(context);
                                    return;
                                  }
                                  if (await _confirmDiscard() && context.mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                          child: const Text('Hủy'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: _saving ? null : _submit,
                          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                          child: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Lưu thay đổi'),
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

StoreFuelProductLookup? _productFromLookups(StoreSalePriceFormLookups? lookups, int productId) {
  if (lookups == null) return null;
  try {
    return lookups.products.firstWhere((e) => e.id == productId);
  } on Object catch (_) {
    return null;
  }
}

class _ProductPickerSheetEdit extends StatefulWidget {
  const _ProductPickerSheetEdit({required this.products});

  final List<StoreFuelProductLookup> products;

  @override
  State<_ProductPickerSheetEdit> createState() => _ProductPickerSheetEditState();
}

class _ProductPickerSheetEditState extends State<_ProductPickerSheetEdit> {
  final _search = TextEditingController();
  var _filtered = <StoreFuelProductLookup>[];

  @override
  void initState() {
    super.initState();
    _filtered = List.of(widget.products);
    _search.addListener(_apply);
  }

  void _apply() {
    final q = _search.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List.of(widget.products);
      } else {
        _filtered = widget.products
            .where(
              (p) =>
                  p.code.toLowerCase().contains(q) ||
                  p.name.toLowerCase().contains(q) ||
                  p.id.toString().contains(q),
            )
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _search.removeListener(_apply);
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height * 0.85;
    final n = _filtered.length < 100 ? _filtered.length : 100;
    return SizedBox(
      height: h,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Mã, tên hoặc Id…',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: n,
              itemBuilder: (ctx, i) {
                final p = _filtered[i];
                return ListTile(
                  title: Text('${p.code} — ${p.name}', maxLines: 2, overflow: TextOverflow.ellipsis),
                  onTap: () => Navigator.pop(context, p),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
