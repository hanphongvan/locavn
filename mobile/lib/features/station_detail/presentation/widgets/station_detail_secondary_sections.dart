import 'package:flutter/material.dart';

import '../../../reporting/data/models/fuel_stock_line.dart';
import '../../../reporting/data/models/station_reporting_stock.dart';
import '../../../stations/data/models/station_detail_dto.dart';
import '../../../store_services/presentation/store_service_icon.dart';
import '../station_detail_formatters.dart';
import '../station_detail_strings.dart';
import '../station_detail_shell_theme.dart';

class StationWeeklyCard extends StatelessWidget {
  const StationWeeklyCard({super.key, required this.slots});

  final List<StationOperatingSlot> slots;

  @override
  Widget build(BuildContext context) {
    final sorted = List<StationOperatingSlot>.from(slots)..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
    return _WhiteSection(
      title: StationDetailStrings.sectionWeekly,
      child: Column(
        children: [
          for (var i = 0; i < sorted.length; i++) ...[
            if (i > 0) Divider(height: 1, color: Colors.black.withValues(alpha: 0.06)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      _weekdayLabel(sorted[i].dayOfWeek),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: StationDetailShellTheme.textPrimary,
                          ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      sorted[i].isClosedAllDay
                          ? StationDetailStrings.weekdayClosedAllDay
                          : '${_slotTime(sorted[i].opensAt)} – ${_slotTime(sorted[i].closesAt)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: StationDetailShellTheme.textSecondary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class StationStockSection extends StatelessWidget {
  const StationStockSection({super.key, required this.stock, this.periodLine});

  final StationReportingStock stock;
  final String? periodLine;

  @override
  Widget build(BuildContext context) {
    return _WhiteSection(
      title: StationDetailStrings.sectionStock,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (periodLine != null && periodLine!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                periodLine!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: StationDetailShellTheme.textSecondary,
                    ),
              ),
            ),
          Text(
            '${stock.lineCount} dòng',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: StationDetailShellTheme.textPrimary,
                ),
          ),
          if (stock.lines.isNotEmpty) ...[
            const SizedBox(height: 10),
            StationStockLinesPreview(lines: stock.lines),
          ],
        ],
      ),
    );
  }
}

class StationStockLinesPreview extends StatelessWidget {
  const StationStockLinesPreview({super.key, required this.lines});

  final List<FuelStockLine> lines;

  @override
  Widget build(BuildContext context) {
    final preview = lines.take(8).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in preview) _stockLine(context, line),
        if (lines.length > preview.length)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '+${lines.length - preview.length}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: StationDetailShellTheme.textSecondary,
                  ),
            ),
          ),
      ],
    );
  }

  Widget _stockLine(BuildContext context, FuelStockLine line) {
    final label = line.tenThongKe ?? line.maSo ?? StationDetailStrings.emDash;
    final parts = <String>[];
    if (line.so01 != null) parts.add(formatSo(line.so01!));
    if (line.so02 != null) parts.add(formatSo(line.so02!));
    if (line.so03 != null) parts.add(formatSo(line.so03!));
    final nums = parts.isNotEmpty ? parts.join(' · ') : StationDetailStrings.emDash;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        '$label: $nums',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: StationDetailShellTheme.textSecondary,
              height: 1.3,
            ),
      ),
    );
  }

  String formatSo(double v) => v.toStringAsFixed(2);
}

class StationStoreServicesCard extends StatelessWidget {
  const StationStoreServicesCard({super.key, required this.services});

  final List<StationDetailStoreService> services;

  @override
  Widget build(BuildContext context) {
    final sorted = List<StationDetailStoreService>.from(services)
      ..sort((a, b) {
        final o = a.sortOrder.compareTo(b.sortOrder);
        if (o != 0) return o;
        return a.displayName.compareTo(b.displayName);
      });
    return _WhiteSection(
      title: StationDetailStrings.sectionStoreServices,
      child: Column(
        children: [
          for (var i = 0; i < sorted.length; i++) ...[
            if (i > 0) Divider(height: 1, color: Colors.black.withValues(alpha: 0.06)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    storeServiceIconData(sorted[i].iconKey),
                    size: 22,
                    color: sorted[i].isActive
                        ? StationDetailShellTheme.primary
                        : StationDetailShellTheme.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sorted[i].displayName,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: StationDetailShellTheme.textPrimary,
                              ),
                        ),
                        if (!sorted[i].isActive)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              StationDetailStrings.storeServiceInactive,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: StationDetailShellTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        if (sorted[i].price != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              stationDetailFormatRoundDong(sorted[i].price!),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: StationDetailShellTheme.textSecondary,
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class StationAreaCard extends StatelessWidget {
  const StationAreaCard({
    super.key,
    required this.province,
    required this.district,
    required this.ward,
  });

  final String province;
  final String district;
  final String ward;

  @override
  Widget build(BuildContext context) {
    return _WhiteSection(
      title: StationDetailStrings.sectionArea,
      child: Column(
        children: [
          _kvRow(context, StationDetailStrings.labelProvince, province),
          const SizedBox(height: 10),
          _kvRow(context, StationDetailStrings.labelDistrict, district),
          const SizedBox(height: 10),
          _kvRow(context, StationDetailStrings.labelWard, ward),
        ],
      ),
    );
  }
}

class StationContactCard extends StatelessWidget {
  const StationContactCard({super.key, required this.phone, required this.email});

  final String? phone;
  final String? email;

  @override
  Widget build(BuildContext context) {
    return _WhiteSection(
      title: StationDetailStrings.sectionContact,
      child: Column(
        children: [
          if (phone != null) ...[
            _kvRow(context, StationDetailStrings.labelPhone, phone!),
            if (email != null) const SizedBox(height: 10),
          ],
          if (email != null) _kvRow(context, StationDetailStrings.labelEmail, email!),
        ],
      ),
    );
  }
}

class _WhiteSection extends StatelessWidget {
  const _WhiteSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(StationDetailShellTheme.cardRadius),
        boxShadow: [
          BoxShadow(
            color: StationDetailShellTheme.cardShadow,
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: StationDetailShellTheme.primary,
                  ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

Widget _kvRow(BuildContext context, String label, String value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        flex: 4,
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: StationDetailShellTheme.textSecondary,
              ),
        ),
      ),
      Expanded(
        flex: 6,
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: StationDetailShellTheme.textPrimary,
              ),
        ),
      ),
    ],
  );
}

String _slotTime(String? t) {
  final s = t?.trim();
  if (s == null || s.isEmpty) return StationDetailStrings.emDash;
  return s;
}

String _weekdayLabel(int dayOfWeek) {
  return switch (dayOfWeek) {
    0 => 'CN',
    1 => 'T2',
    2 => 'T3',
    3 => 'T4',
    4 => 'T5',
    5 => 'T6',
    6 => 'T7',
    _ => '$dayOfWeek',
  };
}
