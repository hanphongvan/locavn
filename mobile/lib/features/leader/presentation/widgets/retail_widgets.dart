import 'package:flutter/material.dart';

import '../../../reports/presentation/dashboard/loca_dashboard_tokens.dart';
import '../../data/leader_retail_service.dart';

/// KPI card đơn lẻ — 4 ô trên + ô tỷ lệ hoạt động riêng (full-width).
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

/// Filter bar — chip horizontal cho Vùng / Tỉnh / Loại NL / Trạng thái.
class RetailFilterBar extends StatelessWidget {
  const RetailFilterBar({
    super.key,
    required this.filter,
    required this.regions,
    required this.provinces,
    required this.onChanged,
  });

  final RetailFilter filter;
  final List<String> regions;
  final List<String> provinces;
  final ValueChanged<RetailFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _DropdownChip<String>(
            label: 'Vùng',
            value: filter.region,
            items: regions,
            display: (s) => s,
            onSelected: (v) => onChanged(filter.copyWith(region: v)),
          ),
          const SizedBox(width: 8),
          _DropdownChip<String>(
            label: 'Tỉnh',
            value: filter.province,
            items: provinces,
            display: (s) => s,
            onSelected: (v) => onChanged(filter.copyWith(province: v)),
          ),
          const SizedBox(width: 8),
          _DropdownChip<RetailFuelType>(
            label: 'Loại NL',
            value: filter.fuelType == RetailFuelType.all
                ? null
                : filter.fuelType,
            items: RetailFuelType.values
                .where((e) => e != RetailFuelType.all)
                .toList(),
            display: (e) => e.label,
            onSelected: (v) => onChanged(
              filter.copyWith(fuelType: v ?? RetailFuelType.all),
            ),
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
          if (_hasAnyFilter)
            ActionChip(
              avatar: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Xoá lọc'),
              onPressed: () => onChanged(const RetailFilter()),
            ),
        ],
      ),
    );
  }

  bool get _hasAnyFilter =>
      filter.region != null ||
      filter.province != null ||
      filter.fuelType != RetailFuelType.all ||
      filter.status != null;
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

    return PopupMenuButton<T?>(
      tooltip: label,
      position: PopupMenuPosition.under,
      onSelected: onSelected,
      itemBuilder: (ctx) {
        return [
          PopupMenuItem<T?>(value: null, child: Text('Tất cả $label')),
          const PopupMenuDivider(),
          for (final item in items)
            PopupMenuItem<T?>(value: item, child: Text(display(item))),
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
        backgroundColor: selected
            ? LocaDashboardTokens.primaryBlue
            : Colors.white,
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
                Icon(
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
                    stat.province,
                    style: t.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: LocaDashboardTokens.textPrimary,
                    ),
                  ),
                  Text(
                    stat.region,
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

/// Card cảnh báo điều hành.
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
