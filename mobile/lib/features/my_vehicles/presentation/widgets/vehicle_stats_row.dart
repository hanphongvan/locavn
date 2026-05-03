import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../my_vehicles_palette.dart';

/// Three-column stats: bình xăng %, km, năm.
class VehicleStatsRow extends StatelessWidget {
  const VehicleStatsRow({
    super.key,
    required this.fuelLevel,
    required this.totalKm,
    required this.year,
    this.compact = false,
  });

  final int? fuelLevel;
  final int? totalKm;
  final int? year;
  final bool compact;

  static const double _iconCircleHero = 42;
  static const double _iconCircleCompact = 36;

  Color _fuelValueColor(int? level) {
    if (level == null) return MyVehiclesPalette.muted;
    if (level >= 30) return MyVehiclesPalette.accentGreen;
    return const Color(0xFFFF9F43);
  }

  @override
  Widget build(BuildContext context) {
    final fuelLabel = fuelLevel != null ? '$fuelLevel%' : '—';
    final kmLabel = totalKm != null ? NumberFormat.decimalPattern('vi').format(totalKm) : '—';
    final yearLabel = year?.toString() ?? '—';
    final fuelColor = _fuelValueColor(fuelLevel);
    final iconSize = compact ? _iconCircleCompact : _iconCircleHero;
    final iconInner = compact ? 17.0 : 19.0;

    Widget statBlock({
      required IconData icon,
      required String title,
      required String value,
      required Color valueColor,
    }) {
      return Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: MyVehiclesPalette.accentBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: iconInner, color: MyVehiclesPalette.accentBlue),
            ),
            SizedBox(height: compact ? 6 : 10),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 10 : 11,
                height: 1.2,
                color: MyVehiclesPalette.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: compact ? 2 : 4),
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 13 : 16,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
          ],
        ),
      );
    }

    final row = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          statBlock(
            icon: Icons.opacity_rounded,
            title: 'Bình xăng',
            value: fuelLabel,
            valueColor: fuelColor,
          ),
          if (compact) ...[
            VerticalDivider(
              width: 1,
              thickness: 1,
              indent: 8,
              endIndent: 8,
              color: MyVehiclesPalette.borderSoft.withValues(alpha: 0.75),
            ),
          ],
          statBlock(
            icon: Icons.speed_rounded,
            title: 'Số km đã đi',
            value: kmLabel,
            valueColor: MyVehiclesPalette.navy,
          ),
          if (compact) ...[
            VerticalDivider(
              width: 1,
              thickness: 1,
              indent: 8,
              endIndent: 8,
              color: MyVehiclesPalette.borderSoft.withValues(alpha: 0.75),
            ),
          ],
          statBlock(
            icon: Icons.calendar_month_rounded,
            title: 'Năm sản xuất',
            value: yearLabel,
            valueColor: MyVehiclesPalette.navy,
          ),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 6 : 10),
      child: row,
    );
  }
}
