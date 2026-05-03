import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/widgets/gradient_button.dart';
import '../../../auth/presentation/widgets/login_screen_theme.dart';
import '../../data/models/store_fuel_product_lookup.dart';
import '../../data/models/store_sale_price_batch_models.dart';
import '../../data/sale_price_json_parsing.dart';
import '../../data/store_sale_prices_exceptions.dart';
import '../../data/store_sale_prices_repository.dart';
import '../../data/vietnam_wall_time.dart';
import '../store_sale_prices_providers.dart';
import '../vn_price_input.dart';
import 'price_ui/store_price_design_tokens.dart';
import 'price_ui/store_price_form_item.dart';

class _RowEditors {
  _RowEditors()
      : price = TextEditingController(),
        note = TextEditingController();

  StoreFuelProductLookup? product;
  final TextEditingController price;
  int? unitId;
  final TextEditingController note;

  void dispose() {
    price.dispose();
    note.dispose();
  }
}

/// Bottom sheet: **multi-row** batch create (`POST /api/admin/store-prices/batch`),
/// same contract as Angular `StorePriceFormPageComponent` batch mode (`submitBatch`):
/// one request with `donViId`, `effectiveDate`, `isCurrent`, and `rows[]` (1–50 unique products).
class SalePriceBatchEntrySheet extends ConsumerStatefulWidget {
  const SalePriceBatchEntrySheet({
    super.key,
    required this.sessionDonViId,
  });

  final int sessionDonViId;

  @override
  ConsumerState<SalePriceBatchEntrySheet> createState() => _SalePriceBatchEntrySheetState();
}

/// Demo OCR-style extraction (fixed values) sau khi chụp ảnh.
const _kDemoPriceBoardExtract = <String, int>{
  'RON95': 19280,
  'E5RON92': 18240,
  'DIESEL': 15160,
};

class _SalePriceBatchEntrySheetState extends ConsumerState<SalePriceBatchEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _effectiveAt;
  var _isCurrent = false;
  var _dirty = false;
  var _saving = false;
  var _validationAttempted = false;
  final _rows = <_RowEditors>[_RowEditors()];
  Uint8List? _lastCapturedPhotoBytes;

  @override
  void initState() {
    super.initState();
    _effectiveAt = VietnamWallTime.batchDefaultEffectiveWallNow();
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
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

  Future<void> _pickProduct(_RowEditors row) async {
    final lookupsAsync = ref.read(storeSalePriceFormLookupsProvider);
    final lookups = lookupsAsync.valueOrNull;
    if (lookups == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang tải danh mục mặt hàng…')),
        );
      }
      return;
    }
    final chosen = await showModalBottomSheet<StoreFuelProductLookup>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return _ProductPickerSheet(products: lookups.products);
      },
    );
    if (chosen != null && mounted) {
      setState(() {
        row.product = chosen;
        row.unitId = chosen.unitId;
        _dirty = true;
      });
    }
  }

  void _addRow() {
    if (_rows.length >= 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tối đa 50 dòng mỗi lần lưu (giới hạn backend).')),
      );
      return;
    }
    setState(() {
      _rows.add(_RowEditors());
      _dirty = true;
    });
  }

  void _removeRow(int i) {
    if (_rows.length <= 1) return;
    setState(() {
      _rows[i].dispose();
      _rows.removeAt(i);
      _dirty = true;
    });
  }

  Future<void> _loadDefaults() async {
    try {
      final repo = ref.read(storeSalePricesRepositoryProvider);
      final defs = await repo.loadProductLookups(defaultsOnly: true, take: 30);
      if (!mounted) return;
      setState(() {
        for (final r in _rows) {
          r.dispose();
        }
        _rows
          ..clear()
          ..addAll(
            defs.isEmpty
                ? [_RowEditors()]
                : defs.map((p) {
                    final row = _RowEditors();
                    row.product = p;
                    row.unitId = p.unitId;
                    return row;
                  }),
          );
        _dirty = true;
      });
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : '$e')),
      );
    }
  }

  Future<void> _copyLatest() async {
    try {
      final repo = ref.read(storeSalePricesRepositoryProvider);
      final rows = await repo.loadLatestSubmissionForSessionStore();
      if (!mounted) return;
      if (rows.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chưa có bản ghi giá trước đó cho cửa hàng này.')),
        );
        return;
      }
      final lookups = ref.read(storeSalePriceFormLookupsProvider).valueOrNull;
      setState(() {
        for (final r in _rows) {
          r.dispose();
        }
        _rows.clear();
        for (final sub in rows) {
          StoreFuelProductLookup? p;
          if (lookups != null) {
            try {
              p = lookups.products.firstWhere((e) => e.id == sub.productId);
            } on Object catch (_) {
              p = StoreFuelProductLookup(
                id: sub.productId,
                code: '#${sub.productId}',
                name: '',
                unitId: sub.unitId,
                sortOrder: null,
              );
            }
          } else {
            p = StoreFuelProductLookup(
              id: sub.productId,
              code: '#${sub.productId}',
              name: '',
              unitId: sub.unitId,
              sortOrder: null,
            );
          }
          final ed = _RowEditors();
          ed.product = p;
          ed.unitId = sub.unitId;
          ed.price.text = formatVnPriceDisplay(sub.price);
          if (sub.note != null) ed.note.text = sub.note!;
          _rows.add(ed);
        }
        _effectiveAt = rows.first.effectiveDate.toLocal();
        _isCurrent = rows.any((x) => x.isCurrent);
        _dirty = true;
      });
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : '$e')),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _validationAttempted = true);
      return;
    }
    final pids = <int>{};
    final batchRows = <StoreSalePriceBatchRowRequest>[];
    for (final r in _rows) {
      final p = r.product;
      if (p == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chọn đủ mặt hàng cho mỗi dòng.')),
        );
        return;
      }
      if (!pids.add(p.id)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không được trùng mặt hàng trong cùng một lần lưu.')),
        );
        return;
      }
      final priceVal = parseVnDecimalInput(r.price.text);
      if (priceVal == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Giá không hợp lệ cho ${p.code}')),
        );
        return;
      }
      final rounded = SalePriceJsonParsing.roundPriceForApi(priceVal);
      batchRows.add(
        StoreSalePriceBatchRowRequest(
          productId: p.id,
          price: rounded,
          unitId: r.unitId,
          note: r.note.text.trim().isEmpty ? null : r.note.text.trim(),
        ),
      );
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(storeSalePricesRepositoryProvider);
      await repo.createBatch(
        StoreSalePriceBatchCreateRequest(
          donViId: widget.sessionDonViId,
          effectiveDate: _effectiveAt,
          isCurrent: _isCurrent,
          rows: batchRows,
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

  StoreFuelProductLookup? _findProductForDemoCode(
    List<StoreFuelProductLookup> products,
    String demoCode,
  ) {
    final want = demoCode.toUpperCase();
    for (final p in products) {
      if (p.code.toUpperCase() == want) return p;
    }
    final wantNorm = want.replaceAll(RegExp(r'[\s_-]'), '');
    for (final p in products) {
      final c = p.code.toUpperCase().replaceAll(RegExp(r'[\s_-]'), '');
      if (c == wantNorm) return p;
    }
    for (final p in products) {
      if (p.code.toUpperCase().contains(want) || p.name.toUpperCase().contains(want)) {
        return p;
      }
    }
    return null;
  }

  void _applyDemoExtractedRows() {
    final lookups = ref.read(storeSalePriceFormLookupsProvider).valueOrNull;
    if (lookups == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có danh mục mặt hàng để áp dụng.')),
      );
      return;
    }
    final newRows = <_RowEditors>[];
    for (final e in _kDemoPriceBoardExtract.entries) {
      final p = _findProductForDemoCode(lookups.products, e.key);
      if (p == null) continue;
      final ed = _RowEditors();
      ed.product = p;
      ed.unitId = p.unitId;
      ed.price.text = formatVnPriceDisplay(e.value.toDouble());
      newRows.add(ed);
    }
    if (newRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không khớp mã mặt hàng trong danh mục (RON95 / E5RON92 / DIESEL).'),
        ),
      );
      return;
    }
    setState(() {
      for (final r in _rows) {
        r.dispose();
      }
      _rows
        ..clear()
        ..addAll(newRows);
      _dirty = true;
    });
  }

  Future<void> _capturePriceBoardPhoto() async {
    if (_saving) return;
    if (kIsWeb) {
      if (!mounted) return;
      setState(() => _lastCapturedPhotoBytes = null);
      await _showPhotoDemoResultDialog();
      return;
    }
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (!mounted) return;
      if (x == null) return;
      final bytes = await x.readAsBytes();
      setState(() => _lastCapturedPhotoBytes = bytes);
      await _showPhotoDemoResultDialog();
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Future<void> _showPhotoDemoResultDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          title: const Text('Kết quả nhận dạng (demo)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_lastCapturedPhotoBytes != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _lastCapturedPhotoBytes!,
                      height: 140,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text('Chi tiết mặt hàng', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                SelectableText(
                  '{\n'
                  '  "RON95": 19280,\n'
                  '  "E5RON92": 18240,\n'
                  '  "DIESEL": 15160\n'
                  '}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Đóng'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _applyDemoExtractedRows();
              },
              child: const Text('Áp dụng vào phiếu'),
            ),
          ],
        );
      },
    );
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

  List<DropdownMenuItem<int?>> _unitDropdownItems(StoreSalePriceFormLookups? lu) {
    if (lu == null) {
      return const [DropdownMenuItem<int?>(value: null, child: Text('—'))];
    }
    return [
      const DropdownMenuItem<int?>(value: null, child: Text('—')),
      ...lu.uniqueUnitsById.map(
        (u) => DropdownMenuItem<int?>(
          value: u.id,
          child: Text(
            '${u.ma ?? ''} ${u.ten ?? ''}'.trim().isEmpty
                ? '${u.id}'
                : '${u.ma ?? ''} — ${u.ten ?? ''}'.trim(),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lookups = ref.watch(storeSalePriceFormLookupsProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: DecoratedBox(
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
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Form(
            key: _formKey,
            autovalidateMode:
                _validationAttempted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thêm giá',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: LoginScreenTheme.titleBlue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Cập nhật bảng giá mới',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Đóng',
                        onPressed: () async {
                          if (!_dirty) {
                            Navigator.pop(context);
                            return;
                          }
                          if (await _confirmDiscard() && context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(StorePriceDesignTokens.sheetCardRadius),
                        boxShadow: StorePriceDesignTokens.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Ngày hiệu lực',
                            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Material(
                            color: Colors.white,
                            child: InkWell(
                              onTap: _saving ? null : _pickEffective,
                              borderRadius: BorderRadius.circular(StorePriceDesignTokens.inputRadius),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(StorePriceDesignTokens.inputRadius),
                                  border: Border.all(color: StorePriceDesignTokens.borderGray),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        VietnamWallTime.formatBatchEffectivePickerDisplay(_effectiveAt),
                                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Icon(Icons.event_rounded, color: theme.colorScheme.primary),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Bảng giá đang áp dụng',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            value: _isCurrent,
                            onChanged: _saving
                                ? null
                                : (v) {
                                    setState(() {
                                      _isCurrent = v;
                                      _dirty = true;
                                    });
                                  },
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              IconButton.filledTonal(
                                tooltip: 'Mặt hàng mặc định',
                                onPressed: _saving ? null : _loadDefaults,
                                icon: const Icon(Icons.playlist_add_check_outlined),
                              ),
                              IconButton.filledTonal(
                                tooltip: 'Sao chép gần nhất',
                                onPressed: _saving ? null : _copyLatest,
                                icon: const Icon(Icons.copy_all_outlined),
                              ),
                              IconButton.filledTonal(
                                tooltip: 'Chụp hình',
                                onPressed: _saving ? null : _capturePriceBoardPhoto,
                                icon: const Icon(Icons.photo_camera_outlined),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Chi tiết theo mặt hàng',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(_rows.length, (i) {
                            final row = _rows[i];
                            final p = row.product;
                            return StorePriceFormItem(
                              key: ObjectKey(row),
                              index: i,
                              productSubtitle: p == null ? null : '${p.code} — ${p.name}',
                              onPickProduct: () => _pickProduct(row),
                              priceController: row.price,
                              onPriceChanged: (_) => _markDirty(),
                              priceValidator: (s) {
                                final v = parseVnDecimalInput(s ?? '');
                                if (v == null) return 'Nhập giá hợp lệ';
                                if (v < 0) return 'Giá phải ≥ 0';
                                return null;
                              },
                              unitId: row.unitId,
                              unitMenuItems: _unitDropdownItems(lookups.valueOrNull),
                              onUnitChanged: (v) {
                                setState(() {
                                  row.unitId = v;
                                  _dirty = true;
                                });
                              },
                              noteController: row.note,
                              onNoteChanged: (_) => _markDirty(),
                              enabled: !_saving,
                              showRemove: _rows.length > 1,
                              onRemove: () => _removeRow(i),
                            );
                          }),
                          const SizedBox(height: 8),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _saving ? null : _addRow,
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: StorePriceDesignTokens.borderGray),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_circle_outline_rounded, color: theme.colorScheme.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Thêm dòng',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (lookups.isLoading)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          if (lookups.hasError)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Không tải được danh mục: ${lookups.error}',
                                style: TextStyle(color: theme.colorScheme.error),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              side: const BorderSide(color: StorePriceDesignTokens.borderGray),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              foregroundColor: theme.colorScheme.onSurface,
                            ),
                            child: const Text('Hủy', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: GradientButton(
                            label: 'Lưu tất cả',
                            loading: _saving,
                            loadingMessage: 'Đang lưu…',
                            trailingIcon: Icons.check_rounded,
                            gradientColors: StorePriceDesignTokens.primaryGradient,
                            onPressed: _saving ? null : _submit,
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
      ),
    );
  }
}

class _ProductPickerSheet extends StatefulWidget {
  const _ProductPickerSheet({required this.products});

  final List<StoreFuelProductLookup> products;

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
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
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
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
