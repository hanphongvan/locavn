import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../reports/presentation/dashboard/loca_dashboard_tokens.dart';
import '../../data/leader_dashboard_service.dart';
import '../../data/leader_inventory_detail_models.dart';
import '../leader_theme.dart';

/// Tham số `statusGroup` trên API — lọc theo mã SQL (0/1/2), không suy từ app.
const _kStatusAll = 'all';
const _kStatusSafe = 'safe';
const _kStatusWarning = 'warning';
const _kStatusCritical = 'critical';

void showLeaderInventoryDetailSheet(
  BuildContext context, {
  required String fuelType,
  required String title,
  int? month,
  int? year,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (ctx) => LeaderInventoryDetailBottomSheet(
      fuelType: fuelType,
      title: title,
      month: month,
      year: year,
    ),
  );
}

class LeaderInventoryDetailBottomSheet extends ConsumerStatefulWidget {
  const LeaderInventoryDetailBottomSheet({
    super.key,
    required this.fuelType,
    required this.title,
    this.month,
    this.year,
  });

  final String fuelType;
  final String title;
  final int? month;
  final int? year;

  @override
  ConsumerState<LeaderInventoryDetailBottomSheet> createState() => _LeaderInventoryDetailBottomSheetState();
}

enum _SortKind { tonDesc, daysAsc }

class _LeaderInventoryDetailBottomSheetState extends ConsumerState<LeaderInventoryDetailBottomSheet> {
  Future<LeaderInventoryDetailResponse>? _future;
  final TextEditingController _search = TextEditingController();
  String _statusGroup = _kStatusAll;
  _SortKind _sort = _SortKind.tonDesc;
  var _bootstrapped = false;

  Future<LeaderInventoryDetailResponse> _loadDetail() {
    return ref.read(leaderDashboardServiceProvider).getInventoryDetail(
          widget.fuelType,
          month: widget.month,
          year: widget.year,
          statusGroup: _statusGroup == _kStatusAll ? null : _statusGroup,
        );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) {
      return;
    }
    _bootstrapped = true;
    _future = _loadDetail();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _future = _loadDetail();
    });
  }

  void _onStatusChip(String apiGroup) {
    if (apiGroup == _statusGroup) {
      return;
    }
    setState(() {
      _statusGroup = apiGroup;
      _future = _loadDetail();
    });
  }

  static List<LeaderInventoryDetailRow> _applySearchAndSort(
    List<LeaderInventoryDetailRow> raw,
    String q,
    _SortKind sort,
  ) {
    final needle = q.trim().toLowerCase();
    var list = raw.toList();
    if (needle.isNotEmpty) {
      list = list
          .where((r) {
            final name = r.distributorName.toLowerCase();
            final addr = (r.address ?? '').toLowerCase();
            return name.contains(needle) || addr.contains(needle);
          })
          .toList();
    }
    list.sort((a, b) {
      switch (sort) {
        case _SortKind.tonDesc:
          return b.inventoryQuantity.compareTo(a.inventoryQuantity);
        case _SortKind.daysAsc:
          return a.coverageDays.compareTo(b.coverageDays);
      }
    });
    return list;
  }

  String get _sortMenuLabel => switch (_sort) {
        _SortKind.tonDesc => 'Tồn kho giảm dần',
        _SortKind.daysAsc => 'Số ngày dự trữ tăng dần',
      };

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height * 0.9;
    final nf = NumberFormat.decimalPattern('vi');
    final t = Theme.of(context).textTheme;

    return SizedBox(
      height: h,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: t.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: LocaDashboardTokens.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Đóng',
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<LeaderInventoryDetailResponse>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  final msg = snap.error is ApiException
                      ? (snap.error! as ApiException).message
                      : snap.error.toString();
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_rounded, size: 48, color: LeaderTheme.alert),
                          const SizedBox(height: 12),
                          Text(
                            'Không tải được dữ liệu',
                            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            msg,
                            style: t.bodyMedium?.copyWith(color: LeaderTheme.muted),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final data = snap.data!;
                final period = data.reportPeriodLabel;
                final filtered = _applySearchAndSort(data.items, _search.text, _sort);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (period != null && period.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          period,
                          style: t.bodySmall?.copyWith(color: LeaderTheme.muted, fontWeight: FontWeight.w600),
                        ),
                      ),
                    if (!data.fromStoredProcedure && data.items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                        child: Text(
                          'Nguồn dữ liệu tạm thời không khả dụng (stored procedure).',
                          style: t.bodySmall?.copyWith(color: LeaderTheme.alert, fontWeight: FontWeight.w600),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: TextField(
                        controller: _search,
                        decoration: InputDecoration(
                          hintText: 'Tìm doanh nghiệp',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: LocaDashboardTokens.cardWhite,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusLg),
                            borderSide: BorderSide(color: LocaDashboardTokens.primaryBlue.withValues(alpha: 0.15)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusLg),
                            borderSide: BorderSide(color: LocaDashboardTokens.primaryBlue.withValues(alpha: 0.12)),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'Tất cả',
                            selected: _statusGroup == _kStatusAll,
                            onSelected: () => _onStatusChip(_kStatusAll),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'An toàn',
                            selected: _statusGroup == _kStatusSafe,
                            color: LeaderTheme.coverageOk,
                            onSelected: () => _onStatusChip(_kStatusSafe),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Cảnh báo',
                            selected: _statusGroup == _kStatusWarning,
                            color: const Color(0xFFE65100),
                            onSelected: () => _onStatusChip(_kStatusWarning),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Nguy cơ',
                            selected: _statusGroup == _kStatusCritical,
                            color: LeaderTheme.alert,
                            onSelected: () => _onStatusChip(_kStatusCritical),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: PopupMenuButton<_SortKind>(
                          tooltip: 'Sắp xếp',
                          onSelected: (v) => setState(() => _sort = v),
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: _SortKind.tonDesc,
                              child: ListTile(
                                dense: true,
                                leading: const Icon(Icons.south_rounded),
                                title: const Text('Tồn kho giảm dần'),
                                selected: _sort == _SortKind.tonDesc,
                              ),
                            ),
                            PopupMenuItem(
                              value: _SortKind.daysAsc,
                              child: ListTile(
                                dense: true,
                                leading: const Icon(Icons.north_rounded),
                                title: const Text('Số ngày dự trữ tăng dần'),
                                selected: _sort == _SortKind.daysAsc,
                              ),
                            ),
                          ],
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.sort_rounded, color: LocaDashboardTokens.primaryBlue, size: 26),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    _sortMenuLabel,
                                    style: t.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down_rounded),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                data.items.isEmpty ? 'Chưa có dữ liệu chi tiết cho kỳ này.' : 'Không có kết quả phù hợp.',
                                style: t.bodyLarge?.copyWith(color: LeaderTheme.muted, fontWeight: FontWeight.w600),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                              itemCount: filtered.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, i) {
                                final r = filtered[i];
                                return _DistributorInventoryCard(row: r, nf: nf);
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (bool value) {
        if (value) {
          onSelected();
        }
      },
      showCheckmark: false,
      selectedColor: (color ?? LocaDashboardTokens.primaryBlue).withValues(alpha: 0.18),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w800,
        color: selected ? (color ?? LocaDashboardTokens.primaryBlue) : LeaderTheme.muted,
      ),
      side: BorderSide(
        color: selected ? (color ?? LocaDashboardTokens.primaryBlue).withValues(alpha: 0.45) : Colors.black12,
      ),
    );
  }
}

class _DistributorInventoryCard extends StatelessWidget {
  const _DistributorInventoryCard({required this.row, required this.nf});

  final LeaderInventoryDetailRow row;
  final NumberFormat nf;

  Color _badgeBg() {
    switch (row.statusCode) {
      case 0:
        return const Color(0xFFE8F5E9);
      case 1:
        return LocaDashboardTokens.warningBg;
      case 2:
        return const Color(0xFFFFEBEE);
      default:
        return Colors.grey.shade200;
    }
  }

  Color _badgeFg() {
    switch (row.statusCode) {
      case 0:
        return LeaderTheme.coverageOk;
      case 1:
        return const Color(0xFFE65100);
      case 2:
        return LeaderTheme.alert;
      default:
        return LeaderTheme.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final bg = _badgeBg();
    final fg = _badgeFg();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: LocaDashboardTokens.cardWhite,
        borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusLg),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
        boxShadow: LeaderTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  row.distributorName,
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: LeaderTheme.navy),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusPill),
                  border: Border.all(color: fg.withValues(alpha: 0.28)),
                ),
                child: Text(
                  row.status,
                  style: t.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          if ((row.address ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.place_outlined, size: 18, color: LeaderTheme.muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    row.address!.trim(),
                    style: t.bodyMedium?.copyWith(color: LeaderTheme.muted, fontWeight: FontWeight.w600, height: 1.35),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tồn kho',
                  style: t.labelLarge?.copyWith(color: LeaderTheme.muted, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${nf.format(row.inventoryQuantity)} ${row.unit}',
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: LocaDashboardTokens.primaryBlue),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Số ngày dự trữ',
                  style: t.labelLarge?.copyWith(color: LeaderTheme.muted, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${nf.format(row.coverageDays)} ngày',
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: LeaderTheme.navy),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
