import 'package:flutter/material.dart';

import '../../../stations/data/models/station_detail_dto.dart';
import '../station_detail_strings.dart';
import '../station_detail_formatters.dart';
import '../station_detail_shell_theme.dart';

/// License and station code (key–value rows).
class StationExtraInfo extends StatelessWidget {
  const StationExtraInfo({super.key, required this.data});

  final StationDetailDto data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final code = data.stationCode.trim().isNotEmpty ? data.stationCode.trim() : StationDetailStrings.emDash;
    final lic = stationDetailNonEmpty(data.licenseNumber) ?? StationDetailStrings.emDash;
    final issued = stationDetailFormatDateDdMmYyyy(data.licenseDate) ?? StationDetailStrings.emDash;
    final exp = stationDetailFormatDateDdMmYyyy(data.licenseExpiryDate) ?? StationDetailStrings.emDash;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(StationDetailShellTheme.cardRadius),
        boxShadow: [
          BoxShadow(
            color: StationDetailShellTheme.cardShadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              StationDetailStrings.sectionExtra,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: StationDetailShellTheme.primary,
              ),
            ),
            const SizedBox(height: 14),
            _kv(theme, StationDetailStrings.labelStationCode, code),
            const SizedBox(height: 10),
            _kv(theme, StationDetailStrings.labelLicense, lic),
            const SizedBox(height: 10),
            _kv(theme, StationDetailStrings.labelIssued, issued),
            const SizedBox(height: 10),
            _kv(theme, StationDetailStrings.labelExpiry, exp),
          ],
        ),
      ),
    );
  }

  Widget _kv(ThemeData theme, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: StationDetailShellTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: StationDetailShellTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
