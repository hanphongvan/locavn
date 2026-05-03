import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../station_detail/presentation/station_detail_providers.dart';
import '../../../station_detail/presentation/station_detail_shell_theme.dart';
import 'station_map_preview_strings.dart';

/// One-line rating from `stationRatingSummaryProvider`.
class StationPreviewRatingMini extends ConsumerWidget {
  const StationPreviewRatingMini({super.key, required this.stationId});

  final int stationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(stationRatingSummaryProvider(stationId));
    final theme = Theme.of(context);

    return async.when(
      data: (s) {
        if (s.reviewCount <= 0) {
          return Text(
            '—',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: StationDetailShellTheme.textSecondary,
            ),
          );
        }
        final avg = s.averageRating;
        final score = avg != null ? avg.toStringAsFixed(1) : StationMapPreviewStrings.emDash;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, size: 22, color: StationDetailShellTheme.star),
            const SizedBox(width: 4),
            Text(
              score,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: StationDetailShellTheme.textPrimary,
              ),
            ),
            Text(
              ' (${s.reviewCount})',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: StationDetailShellTheme.textSecondary,
              ),
            ),
          ],
        );
      },
      loading: () => Text(
        StationMapPreviewStrings.ratingLoading,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: StationDetailShellTheme.textSecondary,
        ),
      ),
      error: (error, stackTrace) => Text(
        StationMapPreviewStrings.emDash,
        style: theme.textTheme.titleSmall?.copyWith(color: StationDetailShellTheme.textSecondary),
      ),
    );
  }
}
