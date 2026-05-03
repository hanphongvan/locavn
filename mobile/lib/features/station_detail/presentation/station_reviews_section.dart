import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../stations/data/models/station_rating_summary_dto.dart';
import '../../stations/data/models/station_review_dto.dart';
import '../../more/presentation/account/account_activity_providers.dart';
import '../../my_reviews/presentation/my_station_reviews_providers.dart';
import '../../stations/data/stations_api.dart';
import '../../stations/presentation/station_review_compose_sheet.dart';
import 'station_detail_providers.dart';
import 'station_detail_strings.dart';
import 'station_detail_shell_theme.dart';

/// Public reviews block: rating summary, compose entry, paged list from `GET /api/stations/{id}/reviews`.
class StationReviewsSection extends ConsumerStatefulWidget {
  const StationReviewsSection({
    super.key,
    required this.stationId,
    required this.stationName,
    this.stationAddress,
    this.listOnly = false,
  });

  final int stationId;
  final String stationName;
  final String? stationAddress;

  /// When true (station detail layout): only the paged review list — no duplicate rating / CTA.
  final bool listOnly;

  @override
  ConsumerState<StationReviewsSection> createState() => _StationReviewsSectionState();
}

class _StationReviewsSectionState extends ConsumerState<StationReviewsSection> {
  static const _pageSize = 15;

  List<StationReviewDto> _items = [];
  int? _totalCount;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  bool _initialLoaded = false;
  int _loadEpoch = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
  }

  Future<void> _loadInitial() async {
    final epoch = ++_loadEpoch;
    final wipeList = !_initialLoaded || _error != null;
    setState(() {
      _loading = true;
      _error = null;
      if (wipeList) {
        _items = [];
        _totalCount = null;
      }
    });
    try {
      final page = await ref.read(stationsApiProvider).listStationReviews(
            widget.stationId,
            skip: 0,
            take: _pageSize,
          );
      if (!mounted || epoch != _loadEpoch) return;
      setState(() {
        _items = List.from(page.items);
        _totalCount = page.totalCount;
        _loading = false;
        _initialLoaded = true;
      });
    } catch (e) {
      if (!mounted || epoch != _loadEpoch) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _initialLoaded = true;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _totalCount == null || _items.length >= _totalCount!) return;
    final epoch = _loadEpoch;
    setState(() => _loadingMore = true);
    try {
      final page = await ref.read(stationsApiProvider).listStationReviews(
            widget.stationId,
            skip: _items.length,
            take: _pageSize,
          );
      if (!mounted || epoch != _loadEpoch) return;
      setState(() {
        _items.addAll(page.items);
        _totalCount = page.totalCount;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted || epoch != _loadEpoch) return;
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải thêm đánh giá: $e')),
      );
    }
  }

  void _openReviewSheet() {
    showStationReviewComposeSheet(
      context: context,
      stationId: widget.stationId,
      stationName: widget.stationName,
      stationAddress: widget.stationAddress,
      onSubmitted: () {
        ref.invalidate(stationRatingSummaryProvider(widget.stationId));
        ref.invalidate(accountActivitySummaryProvider);
        ref.invalidate(myStationReviewsFirstPageProvider);
        ref.read(stationReviewListBumpProvider(widget.stationId).notifier).state++;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(stationReviewListBumpProvider(widget.stationId), (prev, next) {
      // [prev] có thể null lần đầu sau khi bump (Riverpod); đừng bỏ qua vì sẽ không reload danh sách.
      if (prev == next) return;
      _loadInitial();
    });

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (widget.listOnly) {
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
                StationDetailStrings.sectionReviewsNotes,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: StationDetailShellTheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              ..._buildReviewList(theme, scheme),
            ],
          ),
        ),
      );
    }

    final ratingAsync = ref.watch(stationRatingSummaryProvider(widget.stationId));

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: scheme.primaryContainer.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.32)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.groups_outlined, size: 24, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đánh giá công khai',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Chip(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  label: Text(
                    'Công khai',
                    style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  backgroundColor: scheme.primary.withValues(alpha: 0.12),
                  side: BorderSide.none,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 30, top: 2),
              child: Text(
                'Mọi người đều xem được · khác với “Báo cáo vi phạm”.',
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.3),
              ),
            ),
            const SizedBox(height: 12),
            ratingAsync.when(
              data: (s) => _RatingSummaryBlock(summary: s),
              loading: () => Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Đang tải tóm tắt đánh giá…',
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
              error: (_, _) => Row(
                children: [
                  Expanded(
                    child: Text(
                      'Không tải được tóm tắt đánh giá.',
                      style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(stationRatingSummaryProvider(widget.stationId)),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                ),
                onPressed: _openReviewSheet,
                icon: const Icon(Icons.star_border_rounded, size: 22),
                label: const Text('Viết đánh giá'),
              ),
            ),
            const SizedBox(height: 16),
            ..._buildReviewList(theme, scheme),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildReviewList(ThemeData theme, ColorScheme scheme) {
    if (_loading && _items.isEmpty && _error == null) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_error != null) {
      return [
        _ReviewsErrorBanner(
          title: StationDetailStrings.reviewsLoadErrorTitle,
          message: _error!,
          onRetry: _loadInitial,
        ),
      ];
    }
    if (_items.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            StationDetailStrings.reviewsEmpty,
            style: theme.textTheme.bodyMedium?.copyWith(color: StationDetailShellTheme.textSecondary),
          ),
        ),
      ];
    }
    return [
      if (_loading && _items.isNotEmpty)
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: LinearProgressIndicator(minHeight: 2),
        ),
      for (var i = 0; i < _items.length; i++) ...[
        Padding(
          padding: EdgeInsets.only(bottom: i < _items.length - 1 ? 10 : 0),
          child: _CompactReviewCard(review: _items[i]),
        ),
      ],
      if (_totalCount != null && _items.length < _totalCount!) ...[
        const SizedBox(height: 8),
        Center(
          child: _loadingMore
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
                  onPressed: _loadMore,
                  child: const Text(StationDetailStrings.reviewsLoadMore),
                ),
        ),
      ],
    ];
  }
}

class _RatingSummaryBlock extends StatelessWidget {
  const _RatingSummaryBlock({required this.summary});

  final StationRatingSummaryDto summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (summary.reviewCount <= 0) {
      return Text(
        'Chưa có đánh giá — điểm số sẽ hiện khi có người gửi đánh giá.',
        style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      );
    }
    final avg = summary.averageRating;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          avg != null ? avg.toStringAsFixed(1) : '—',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        const SizedBox(width: 10),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Icon(Icons.star_rounded, color: scheme.tertiary, size: 32),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${summary.reviewCount} đánh giá công khai',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewsErrorBanner extends StatelessWidget {
  const _ReviewsErrorBanner({
    this.title = StationDetailStrings.reviewsListLoadErrorTitle,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

class _CompactReviewCard extends StatelessWidget {
  const _CompactReviewCard({required this.review});

  final StationReviewDto review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final comment = review.comment?.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.38)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (comment != null && comment.isNotEmpty) ...[
              Text(
                comment,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                ...List.generate(5, (i) {
                  final on = i < review.rating;
                  return Icon(
                    on ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 20,
                    color: on ? StationDetailShellTheme.star : scheme.outline.withValues(alpha: 0.45),
                  );
                }),
                const Spacer(),
                Text(
                  _formatReviewTimestamp(review.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
            if (review.images.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final img in review.images)
                    _ReviewThumbnail(url: img.imageUrl),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewThumbnail extends StatelessWidget {
  const _ReviewThumbnail({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showImagePreview(context, url),
        child: SizedBox(
          width: 64,
          height: 64,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Center(
              child: Icon(Icons.broken_image_outlined, size: 28, color: scheme.outline),
            ),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

void _showImagePreview(BuildContext context, String url) {
      showDialog<void>(
    context: context,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      final maxH = MediaQuery.sizeOf(ctx).height * 0.72;
      return Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.maxFinite,
          height: maxH,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.close),
                ),
              ),
              Expanded(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4,
                  child: Center(
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Padding(
                        padding: const EdgeInsets.all(24),
                        child: Icon(Icons.broken_image_outlined, size: 48, color: scheme.outline),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Cùng ngày (theo giờ máy): [HH:mm]. Khác ngày: [dd/MM/yy].
String _formatReviewTimestamp(DateTime createdAt) {
  final local = createdAt.toLocal();
  final now = DateTime.now();
  final sameDay =
      local.year == now.year && local.month == now.month && local.day == now.day;
  if (sameDay) {
    return DateFormat('HH:mm').format(local);
  }
  return DateFormat('dd/MM/yy').format(local);
}
