import 'package:flutter/material.dart';

import '../../../reports/presentation/dashboard/loca_dashboard_tokens.dart';
import '../../data/leader_retail_models.dart';

/// KPI card đơn lẻ — 3 ô tổng + 1 ô tỷ lệ hoạt động riêng (full-width).
class RetailKpiCard extends StatelessWidget {
  const RetailKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.trailing,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LocaDashboardTokens.cardWhite,
        borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusMd),
        boxShadow: LocaDashboardTokens.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const Spacer(),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: t.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: LocaDashboardTokens.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: t.labelMedium?.copyWith(
              color: LocaDashboardTokens.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter bar — 3 chip: Tỉnh / Trạng thái / Đơn vị quản lý + Xoá lọc.
class RetailFilterBar extends StatelessWidget {
  const RetailFilterBar({
    super.key,
    required this.filter,
    required this.provinces,
    required this.managingUnits,
    required this.onChanged,
  });

  final RetailFilter filter;
  final List<RetailProvinceFilterOption> provinces;
  final List<RetailManagingUnit> managingUnits;
  final ValueChanged<RetailFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedProvince = filter.provinceId == null
        ? null
        : provinces.firstWhere(
            (p) => p.id == filter.provinceId,
            orElse: () => RetailProvinceFilterOption(id: filter.provinceId!, storeCount: 0),
          );
    final selectedUnit = filter.managingUnitId == null
        ? null
        : managingUnits.firstWhere(
            (u) => u.id == filter.managingUnitId,
            orElse: () => RetailManagingUnit(id: filter.managingUnitId!, storeCount: 0),
          );

    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _DropdownChip<RetailProvinceFilterOption>(
            label: 'Tỉnh',
            value: selectedProvince,
            items: provinces,
            display: (p) => p.displayName,
            onSelected: (v) => onChanged(filter.copyWith(provinceId: v?.id)),
          ),
          const SizedBox(width: 8),
          _DropdownChip<RetailStoreStatus>(
            label: 'Trạng thái',
            value: filter.status,
            items: RetailStoreStatus.values,
            display: (e) => e.label,
            onSelected: (v) => onChanged(filter.copyWith(status: v)),
          ),
          const SizedBox(width: 8),
          _ManagingUnitChip(
            selected: selectedUnit,
            items: managingUnits,
            onSelected: (v) => onChanged(filter.copyWith(managingUnitId: v?.id)),
          ),
          const SizedBox(width: 8),
          if (filter.hasAny)
            ActionChip(
              avatar: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Xoá lọc'),
              onPressed: () => onChanged(const RetailFilter()),
            ),
        ],
      ),
    );
  }
}

/// Wrapper bắt buộc cho `PopupMenuButton<T>`: Flutter coi `T? newValue == null` là "user dismissed",
/// nên `PopupMenuItem(value: null)` không bao giờ trigger `onSelected`. Wrapper non-null tránh ambiguity.
class _PickValue<T> {
  const _PickValue(this.value);
  final T? value;
}

class _DropdownChip<T> extends StatelessWidget {
  const _DropdownChip({
    required this.label,
    required this.value,
    required this.items,
    required this.display,
    required this.onSelected,
  });

  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) display;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = value != null;
    final chipLabel = selected ? display(value as T) : label;

    return PopupMenuButton<_PickValue<T>>(
      tooltip: label,
      position: PopupMenuPosition.under,
      onSelected: (picked) => onSelected(picked.value),
      itemBuilder: (ctx) {
        return [
          PopupMenuItem<_PickValue<T>>(
            value: const _PickValue(null),
            child: Text('Tất cả $label'),
          ),
          const PopupMenuDivider(),
          for (final item in items)
            PopupMenuItem<_PickValue<T>>(
              value: _PickValue<T>(item),
              child: Text(display(item)),
            ),
        ];
      },
      child: Chip(
        avatar: Icon(
          selected ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
          size: 16,
          color: selected ? Colors.white : LocaDashboardTokens.primaryBlue,
        ),
        label: Text(chipLabel),
        labelStyle: TextStyle(
          color: selected ? Colors.white : LocaDashboardTokens.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
        backgroundColor: selected ? LocaDashboardTokens.primaryBlue : Colors.white,
        side: BorderSide(
          color: selected
              ? LocaDashboardTokens.primaryBlue
              : LocaDashboardTokens.primaryBlue.withValues(alpha: 0.25),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusPill),
        ),
      ),
    );
  }
}

/// Chip "Đơn vị quản lý" — danh sách có thể lên đến hàng nghìn → tap để mở
/// bottom sheet có search + `ListView.builder` (không materialize toàn bộ qua PopupMenuButton).
class _ManagingUnitChip extends StatelessWidget {
  const _ManagingUnitChip({
    required this.selected,
    required this.items,
    required this.onSelected,
  });

  final RetailManagingUnit? selected;
  final List<RetailManagingUnit> items;
  final ValueChanged<RetailManagingUnit?> onSelected;

  @override
  Widget build(BuildContext context) {
    final isSelected = selected != null;
    final chipLabel = isSelected ? selected!.displayName : 'Đơn vị quản lý';

    return InkWell(
      onTap: items.isEmpty ? null : () => _open(context),
      borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusPill),
      child: Chip(
        avatar: Icon(
          isSelected ? Icons.business_rounded : Icons.business_outlined,
          size: 16,
          color: isSelected ? Colors.white : LocaDashboardTokens.primaryBlue,
        ),
        label: Text(chipLabel),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : LocaDashboardTokens.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
        backgroundColor: isSelected ? LocaDashboardTokens.primaryBlue : Colors.white,
        side: BorderSide(
          color: isSelected
              ? LocaDashboardTokens.primaryBlue
              : LocaDashboardTokens.primaryBlue.withValues(alpha: 0.25),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusPill),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<_ManagingUnitPickResult?>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ManagingUnitPickerSheet(
        items: items,
        currentSelectedId: selected?.id,
      ),
    );
    if (picked == null) return; // cancel
    onSelected(picked.unit);
  }
}

/// Bottom sheet chọn đơn vị quản lý — search theo `name`/`code`, lazy `ListView.builder`.
class _ManagingUnitPickerSheet extends StatefulWidget {
  const _ManagingUnitPickerSheet({
    required this.items,
    required this.currentSelectedId,
  });

  final List<RetailManagingUnit> items;
  final int? currentSelectedId;

  @override
  State<_ManagingUnitPickerSheet> createState() => _ManagingUnitPickerSheetState();
}

class _ManagingUnitPickerSheetState extends State<_ManagingUnitPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<RetailManagingUnit> get _filtered {
    if (_query.isEmpty) return widget.items;
    final q = _query.toLowerCase();
    return widget.items.where((u) {
      final name = (u.name ?? '').toLowerCase();
      final code = (u.code ?? '').toLowerCase();
      return name.contains(q) || code.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final filtered = _filtered;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: LocaDashboardTokens.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: LocaDashboardTokens.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.business_rounded,
                      color: LocaDashboardTokens.primaryBlue,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Đơn vị quản lý',
                      style: t.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: LocaDashboardTokens.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${filtered.length}/${widget.items.length}',
                      style: t.labelMedium?.copyWith(
                        color: LocaDashboardTokens.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _searchCtrl,
                  textInputAction: TextInputAction.search,
                  onChanged: (v) => setState(() => _query = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên hoặc mã đơn vị',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          ),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusSm),
                      borderSide: BorderSide(
                        color: LocaDashboardTokens.primaryBlue.withValues(alpha: 0.2),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: filtered.length + 1, // +1 for "Tất cả đơn vị" row at top
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      final isAllSelected = widget.currentSelectedId == null;
                      return _UnitRow(
                        title: 'Tất cả đơn vị',
                        subtitle: '${widget.items.length} đơn vị',
                        selected: isAllSelected,
                        onTap: () =>
                            Navigator.of(context).pop(const _ManagingUnitPickResult(null)),
                      );
                    }
                    final unit = filtered[i - 1];
                    return _UnitRow(
                      title: unit.displayName,
                      subtitle: unit.code != null
                          ? '${unit.code} • ${unit.storeCount} cửa hàng'
                          : '${unit.storeCount} cửa hàng',
                      selected: unit.id == widget.currentSelectedId,
                      onTap: () =>
                          Navigator.of(context).pop(_ManagingUnitPickResult(unit)),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UnitRow extends StatelessWidget {
  const _UnitRow({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? LocaDashboardTokens.primaryBlue.withValues(alpha: 0.06)
              : Colors.transparent,
          border: const Border(
            bottom: BorderSide(color: Color(0xFFEEF2FA), width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected
                          ? LocaDashboardTokens.primaryBlue
                          : LocaDashboardTokens.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: t.labelSmall?.copyWith(
                      color: LocaDashboardTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: LocaDashboardTokens.primaryBlue,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

/// Wrapper để phân biệt "user cancelled" (sheet trả `null`) vs "user chose 'Tất cả đơn vị'"
/// (trả `_ManagingUnitPickResult(null)` — `unit` field null nhưng object non-null).
class _ManagingUnitPickResult {
  const _ManagingUnitPickResult(this.unit);
  final RetailManagingUnit? unit;
}

/// Ranking theo tỉnh — list rút gọn, tap để drill-down.
class RetailProvinceRanking extends StatelessWidget {
  const RetailProvinceRanking({
    super.key,
    required this.provinces,
    required this.onTap,
  });

  final List<RetailProvinceStat> provinces;
  final ValueChanged<RetailProvinceStat> onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: LocaDashboardTokens.cardWhite,
        borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusMd),
        boxShadow: LocaDashboardTokens.cardShadow(context),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.bar_chart_rounded,
                  size: 18,
                  color: LocaDashboardTokens.primaryBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  'Xếp hạng theo tỉnh',
                  style: t.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: LocaDashboardTokens.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${provinces.length} tỉnh',
                  style: t.labelSmall?.copyWith(
                    color: LocaDashboardTokens.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (provinces.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'Không có dữ liệu khớp bộ lọc.',
                style: t.bodyMedium?.copyWith(
                  color: LocaDashboardTokens.textSecondary,
                ),
              ),
            )
          else
            for (final p in provinces) ...[
              _ProvinceRow(stat: p, onTap: () => onTap(p)),
              if (p != provinces.last) const Divider(height: 1, indent: 14),
            ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _ProvinceRow extends StatelessWidget {
  const _ProvinceRow({required this.stat, required this.onTap});
  final RetailProvinceStat stat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final rate = stat.activeRate;
    final rateColor = rate >= 0.85
        ? LocaDashboardTokens.accentGreen
        : rate >= 0.7
            ? Colors.amber.shade700
            : Colors.redAccent;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat.displayName,
                    style: t.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: LocaDashboardTokens.textPrimary,
                    ),
                  ),
                  if (stat.lastUpdatedAt != null)
                    Text(
                      'Cập nhật: ${_fmtDate(stat.lastUpdatedAt!)}',
                      style: t.labelSmall?.copyWith(
                        color: LocaDashboardTokens.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            _Metric(label: 'Tổng', value: '${stat.totalStores}'),
            _Metric(
              label: 'Hoạt động',
              value: '${stat.activeStores}',
              valueColor: LocaDashboardTokens.accentGreen,
            ),
            _Metric(
              label: 'Tạm dừng',
              value: '${stat.pausedStores}',
              valueColor: Colors.amber.shade800,
            ),
            SizedBox(
              width: 56,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(rate * 100).toStringAsFixed(0)}%',
                    style: t.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: rateColor,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: LocaDashboardTokens.textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      flex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: t.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: valueColor ?? LocaDashboardTokens.textPrimary,
            ),
          ),
          Text(
            label,
            style: t.labelSmall?.copyWith(
              color: LocaDashboardTokens.textSecondary,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card cảnh báo điều hành (severity từ BE rule engine).
class RetailWarningCard extends StatelessWidget {
  const RetailWarningCard({super.key, required this.warning});
  final RetailWarning warning;

  Color get _accent {
    return switch (warning.severity) {
      RetailWarningSeverity.high => Colors.redAccent,
      RetailWarningSeverity.medium => Colors.amber.shade700,
      RetailWarningSeverity.low => LocaDashboardTokens.primaryBlue,
    };
  }

  IconData get _icon {
    return switch (warning.severity) {
      RetailWarningSeverity.high => Icons.error_outline_rounded,
      RetailWarningSeverity.medium => Icons.warning_amber_rounded,
      RetailWarningSeverity.low => Icons.info_outline_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(LocaDashboardTokens.radiusSm),
        border: Border.all(color: _accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, color: _accent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  warning.title,
                  style: t.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: LocaDashboardTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  warning.detail,
                  style: t.bodySmall?.copyWith(
                    color: LocaDashboardTokens.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
