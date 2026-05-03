import 'package:flutter/material.dart';

import '../../../stations/domain/station_availability.dart';
import '../station_detail_strings.dart';
import '../station_detail_shell_theme.dart';

/// Top “unit info” panel: title, name, address, opening hours, open-status badge.
class StationHeaderCard extends StatelessWidget {
  const StationHeaderCard({
    super.key,
    required this.stationName,
    required this.addressLines,
    required this.availability,
    required this.openingDisplay,
    required this.closingDisplay,
  });

  final String stationName;
  final List<String> addressLines;
  final StationAvailability availability;
  final String openingDisplay;
  final String closingDisplay;

  @override
  Widget build(BuildContext context) {
    final address = addressLines.where((e) => e.trim().isNotEmpty).join('\n');

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(StationDetailShellTheme.cardRadius),
        boxShadow: [
          BoxShadow(
            color: StationDetailShellTheme.cardShadow,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              StationDetailStrings.sectionUnitInfo,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: StationDetailShellTheme.primary,
                    letterSpacing: 0.2,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              stationName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: StationDetailShellTheme.textPrimary,
                  ),
            ),
            if (address.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                address,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: StationDetailShellTheme.textSecondary,
                      height: 1.35,
                    ),
              ),
            ],
            const SizedBox(height: 14),
            _HoursRow(
              label: StationDetailStrings.labelOpen,
              value: openingDisplay,
            ),
            const SizedBox(height: 8),
            _HoursRow(
              label: StationDetailStrings.labelClose,
              value: closingDisplay,
            ),
            const SizedBox(height: 14),
            _StatusBadge(availability: availability),
          ],
        ),
      ),
    );
  }
}

class _HoursRow extends StatelessWidget {
  const _HoursRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
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
              fontWeight: FontWeight.w700,
              color: StationDetailShellTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.availability});

  final StationAvailability availability;

  (String, Color bg, Color fg) _style() {
    switch (availability.tone) {
      case StationOpenTone.open:
        return (StationDetailStrings.statusOpen, StationDetailShellTheme.badgeOpenBg, StationDetailShellTheme.badgeOpenFg);
      case StationOpenTone.closed:
        return (StationDetailStrings.statusClosed, StationDetailShellTheme.badgeClosedBg, StationDetailShellTheme.badgeClosedFg);
      case StationOpenTone.unknown:
        return (StationDetailStrings.statusPaused, StationDetailShellTheme.badgePausedBg, StationDetailShellTheme.badgePausedFg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (text, bg, fg) = _style();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: fg,
              ),
        ),
      ),
    );
  }
}
