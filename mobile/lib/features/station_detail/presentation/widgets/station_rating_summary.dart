import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../stations/data/models/station_rating_summary_dto.dart';
import '../station_detail_providers.dart';
import '../station_detail_strings.dart';
import '../station_detail_shell_theme.dart';

/// Stars + average + review count (compact).
class StationRatingSummary extends ConsumerWidget {
  const StationRatingSummary({super.key, required this.stationId});

  final int stationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(stationRatingSummaryProvider(stationId));
    final theme = Theme.of(context);

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              StationDetailStrings.sectionRating,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: StationDetailShellTheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            async.when(
              data: (s) => _SummaryBody(summary: s),
              loading: () => Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: StationDetailShellTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    StationDetailStrings.ratingLoading,
                    style: theme.textTheme.bodyMedium?.copyWith(color: StationDetailShellTheme.textSecondary),
                  ),
                ],
              ),
              error: (error, stackTrace) => Row(
                children: [
                  Expanded(
                    child: Text(
                      StationDetailStrings.ratingLoadError,
                      style: theme.textTheme.bodyMedium?.copyWith(color: StationDetailShellTheme.textSecondary),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(stationRatingSummaryProvider(stationId)),
                    child: const Text(StationDetailStrings.ratingRetry),
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

class _SummaryBody extends StatelessWidget {
  const _SummaryBody({required this.summary});

  final StationRatingSummaryDto summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (summary.reviewCount <= 0) {
      return Text(
        StationDetailStrings.ratingNone,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: StationDetailShellTheme.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      );
    }
    final avg = summary.averageRating ?? 0;
    final filled = avg.clamp(0, 5).round().clamp(0, 5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ...List.generate(5, (i) {
              final on = i < filled;
              return Icon(
                on ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 28,
                color: on
                    ? StationDetailShellTheme.star
                    : StationDetailShellTheme.textSecondary.withValues(alpha: 0.35),
              );
            }),
            const SizedBox(width: 12),
            Text(
              summary.averageRating != null ? summary.averageRating!.toStringAsFixed(1) : StationDetailStrings.emDash,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: StationDetailShellTheme.textPrimary,
                height: 1,
              ),
            ),
            Text(
              StationDetailStrings.ratingOutOf,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: StationDetailShellTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          StationDetailStrings.ratingReviewCountLabel(summary.reviewCount),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: StationDetailShellTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
