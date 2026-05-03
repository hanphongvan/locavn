import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../data/fuel_api.dart';
import '../data/models/fuel_tracking_models.dart';
import 'fuel_palette.dart';
import 'fuel_tracking_providers.dart';
import 'widgets/fuel_transaction_item.dart';

/// Toàn bộ lịch sử đổ xăng (phân trang) — sửa / xóa từng dòng.
class FuelAllTransactionsPage extends ConsumerStatefulWidget {
  const FuelAllTransactionsPage({super.key, required this.vehicleId});

  final int vehicleId;

  @override
  ConsumerState<FuelAllTransactionsPage> createState() => _FuelAllTransactionsPageState();
}

class _FuelAllTransactionsPageState extends ConsumerState<FuelAllTransactionsPage> {
  static const _pageSize = 25;

  final _scroll = ScrollController();
  final _items = <FuelTransactionUi>[];
  var _pageIndex = 0;
  int? _totalCount;
  var _loading = false;
  var _loadingMore = false;
  String? _loadError;
  var _dirty = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _refresh(reset: true);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients || _loadingMore || _loading) return;
    final max = _scroll.position.maxScrollExtent;
    if (max <= 0) return;
    if (_scroll.position.pixels > max - 280) {
      _loadMore();
    }
  }

  Future<void> _refresh({bool reset = false}) async {
    if (widget.vehicleId < 1) return;
    if (reset) {
      setState(() {
        _loadError = null;
        _loading = true;
        _pageIndex = 0;
        _items.clear();
        _totalCount = null;
      });
    }
    try {
      final api = ref.read(fuelApiProvider);
      final page = await api.getFuelTransactions(widget.vehicleId, pageIndex: 1, pageSize: _pageSize);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(fuelTransactionsToUi(page.items));
        _totalCount = page.totalCount;
        _pageIndex = 1;
        _loading = false;
        _loadError = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Lỗi: $e';
      });
    }
  }

  Future<void> _loadMore() async {
    final total = _totalCount ?? 0;
    if (_items.length >= total || _loadingMore || _loading) return;
    setState(() => _loadingMore = true);
    try {
      final next = _pageIndex + 1;
      final api = ref.read(fuelApiProvider);
      final page = await api.getFuelTransactions(widget.vehicleId, pageIndex: next, pageSize: _pageSize);
      if (!mounted) return;
      setState(() {
        _items.addAll(fuelTransactionsToUi(page.items));
        _pageIndex = next;
        _totalCount = page.totalCount;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _openEdit(FuelTransactionUi tx) async {
    final id = int.parse(tx.id);
    final prefill = FuelTransactionEditPrefill(
      transactionId: id,
      amountDong: tx.amountDong,
      odometerKm: tx.odometerKm,
      note: tx.note,
      transactionDate: tx.transactionDate,
    );
    final ok = await context.push<bool>(
      '${AppRoute.addFuelTransaction.path}?vehicleId=${widget.vehicleId}&editId=$id',
      extra: prefill,
    );
    if (ok == true && mounted) {
      setState(() => _dirty = true);
      await _refresh(reset: true);
    }
  }

  Future<void> _confirmDelete(FuelTransactionUi tx) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa giao dịch?'),
        content: const Text('Giao dịch sẽ bị xóa khỏi lịch sử. Thao tác này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB91C1C)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final api = ref.read(fuelApiProvider);
      final id = int.parse(tx.id);
      final res = await api.deleteFuelTransaction(id, vehicleId: widget.vehicleId);
      if (!mounted) return;
      if (res.success) {
        setState(() {
          _dirty = true;
          _items.removeWhere((e) => e.id == tx.id);
          final newTotal = (_totalCount ?? 1) - 1;
          _totalCount = newTotal < 0 ? 0 : newTotal;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message.isEmpty ? 'Đã xóa.' : res.message)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message.isEmpty ? 'Không xóa được.' : res.message)));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  void _popWithResult() {
    if (context.mounted) {
      context.pop(_dirty);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.vehicleId < 1) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lịch sử đổ nhiên liệu'),
          backgroundColor: FuelPalette.cardWhite,
          foregroundColor: FuelPalette.textPrimary,
          surfaceTintColor: Colors.transparent,
        ),
        body: const Center(child: Text('Thiếu thông tin xe.')),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _popWithResult();
        }
      },
      child: Scaffold(
        backgroundColor: FuelPalette.background,
        appBar: AppBar(
          title: const Text('Lịch sử đổ nhiên liệu'),
          backgroundColor: FuelPalette.cardWhite,
          foregroundColor: FuelPalette.textPrimary,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _popWithResult,
          ),
        ),
        body: RefreshIndicator(
          color: FuelPalette.primaryBlue,
          onRefresh: () => _refresh(reset: true),
          child: _loading && _items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    Center(child: CircularProgressIndicator(color: FuelPalette.primaryBlue)),
                  ],
                )
              : _loadError != null && _items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: [
                        Text(_loadError!, style: const TextStyle(color: FuelPalette.textPrimary)),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => _refresh(reset: true),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    )
                  : _items.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(24),
                          children: const [
                            SizedBox(height: 80),
                            Text(
                              'Chưa có lần đổ nhiên liệu nào.',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: FuelPalette.textPrimary),
                            ),
                          ],
                        )
                      : ListView.builder(
                          controller: _scroll,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: 1 + _items.length + (_loadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              final total = _totalCount ?? _items.length;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  '$total lần đổ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: FuelPalette.textSecondary.withValues(alpha: 0.95),
                                  ),
                                ),
                              );
                            }
                            if (index <= _items.length) {
                              final tx = _items[index - 1];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Material(
                                  color: FuelPalette.cardWhite,
                                  borderRadius: BorderRadius.circular(FuelPalette.radiusMd),
                                  clipBehavior: Clip.antiAlias,
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _openEdit(tx),
                                    child: FuelTransactionItem(
                                      transaction: tx,
                                      showDividerBelow: false,
                                      showChevron: false,
                                      trailing: PopupMenuButton<int>(
                                        icon: const Icon(Icons.more_vert_rounded, color: FuelPalette.textSecondary),
                                        padding: EdgeInsets.zero,
                                        onSelected: (v) {
                                          if (v == 0) {
                                            _openEdit(tx);
                                          } else if (v == 1) {
                                            _confirmDelete(tx);
                                          }
                                        },
                                        itemBuilder: (ctx) => const [
                                          PopupMenuItem(value: 0, child: Text('Sửa')),
                                          PopupMenuItem(
                                            value: 1,
                                            child: Text(
                                              'Xóa',
                                              style: TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator(color: FuelPalette.primaryBlue)),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}
