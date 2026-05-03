import 'package:flutter/material.dart';

import '../../../stations/domain/station_availability.dart';
import '../../../station_detail/presentation/station_detail_shell_theme.dart';
import 'station_map_preview_strings.dart';

/// Compact open / closed / unknown badge for the map preview sheet.
class StationPreviewOpenBadge extends StatelessWidget {
  const StationPreviewOpenBadge({super.key, required this.availability});

  final StationAvailability availability;

  (String, Color bg, Color fg) _style() {
    switch (availability.tone) {
      case StationOpenTone.open:
        return (
          StationMapPreviewStrings.statusOpenShort,
          StationDetailShellTheme.badgeOpenBg,
          StationDetailShellTheme.badgeOpenFg,
        );
      case StationOpenTone.closed:
        return (
          StationMapPreviewStrings.statusClosedShort,
          StationDetailShellTheme.badgeClosedBg,
          StationDetailShellTheme.badgeClosedFg,
        );
      case StationOpenTone.unknown:
        return (
          StationMapPreviewStrings.statusUnknownShort,
          StationDetailShellTheme.badgePausedBg,
          StationDetailShellTheme.badgePausedFg,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (text, bg, fg) = _style();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: fg,
              ),
        ),
      ),
    );
  }
}
