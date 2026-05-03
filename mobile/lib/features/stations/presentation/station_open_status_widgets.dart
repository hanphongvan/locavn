import 'package:flutter/material.dart';

import '../domain/station_availability.dart';

/// Compact pill: color + icon + primary label (lists, map chrome, chips).
class StationOpenStatusPill extends StatelessWidget {
  const StationOpenStatusPill({
    super.key,
    required this.availability,
    this.dense = false,
    this.showIcon = true,
    this.showSecondary = false,
  });

  final StationAvailability availability;
  final bool dense;

  /// When false, only text + colors (e.g. very tight toolbars).
  final bool showIcon;

  /// When true and [StationAvailability.secondaryLabel] is set, shows a second line under the title.
  final bool showSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = _PillStyle.fromTone(availability.tone, theme);
    final icon = _iconFor(availability.tone, availability.usedSchedule);
    final pad = dense
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
        : const EdgeInsets.symmetric(horizontal: 14, vertical: 8);
    final secondary = availability.secondaryLabel;

    return Material(
      color: style.background,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: pad,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showIcon) ...[
              Icon(icon, size: dense ? 16 : 18, color: style.foreground),
              SizedBox(width: dense ? 6 : 8),
            ],
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    availability.primaryLabel,
                    style: (dense ? theme.textTheme.labelMedium : theme.textTheme.labelLarge)?.copyWith(
                      color: style.foreground,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.15,
                    ),
                  ),
                  if (showSecondary && secondary != null) ...[
                    SizedBox(height: dense ? 2 : 4),
                    Text(
                      secondary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: style.foreground.withValues(alpha: 0.9),
                        height: 1.25,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width banner: primary + optional secondary (bottom sheet, station detail).
class StationOpenStatusBanner extends StatelessWidget {
  const StationOpenStatusBanner({
    super.key,
    required this.availability,
    this.showIcon = true,
    this.compact = false,
  });

  final StationAvailability availability;

  final bool showIcon;

  /// Tighter padding (e.g. nested in a dense card).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = _PillStyle.fromTone(availability.tone, theme);
    final icon = _iconFor(availability.tone, availability.usedSchedule);
    final hPad = compact ? 14.0 : 16.0;
    final vPad = compact ? 10.0 : 14.0;

    return Material(
      color: style.background,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showIcon) ...[
              Icon(icon, size: compact ? 22 : 26, color: style.foreground),
              SizedBox(width: compact ? 10 : 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    availability.primaryLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: style.foreground,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      fontSize: compact ? 14.5 : null,
                    ),
                  ),
                  if (availability.secondaryLabel != null) ...[
                    SizedBox(height: compact ? 4 : 6),
                    Text(
                      availability.secondaryLabel!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: style.foreground.withValues(alpha: 0.92),
                        height: 1.35,
                        fontSize: compact ? 12.5 : null,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _iconFor(StationOpenTone tone, bool usedSchedule) {
  return switch (tone) {
    StationOpenTone.open =>
      usedSchedule ? Icons.schedule_rounded : Icons.check_circle_rounded,
    StationOpenTone.closed => Icons.do_not_disturb_on_rounded,
    StationOpenTone.unknown => Icons.help_outline_rounded,
  };
}

class _PillStyle {
  const _PillStyle({required this.background, required this.foreground});

  final Color background;
  final Color foreground;

  factory _PillStyle.fromTone(StationOpenTone tone, ThemeData theme) {
    return switch (tone) {
      StationOpenTone.open => const _PillStyle(
          background: Color(0xFFE8F5E9),
          foreground: Color(0xFF1B5E20),
        ),
      StationOpenTone.closed => const _PillStyle(
          background: Color(0xFFFFEBEE),
          foreground: Color(0xFFB71C1C),
        ),
      StationOpenTone.unknown => _PillStyle(
          background: theme.colorScheme.surfaceContainerHighest,
          foreground: theme.colorScheme.onSurfaceVariant,
        ),
    };
  }
}
