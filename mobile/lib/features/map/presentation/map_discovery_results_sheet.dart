import 'package:flutter/material.dart';

import '../../../core/formatting/vnd_currency_format.dart';
import '../../stations/data/models/station_map_item.dart';
import '../../stations/domain/station_availability.dart';
import '../../stations/presentation/station_open_status_widgets.dart';
import '../../stations/station_open_status.dart';

/// One scannable row in map discovery results — [item] is always from real map/list APIs.
/// Optional fields come from spotlight payloads when applicable (never invented).
class MapStationListRow {
  const MapStationListRow({
    required this.item,
    this.spotlightAverageRating,
    this.spotlightReviewCount,
    this.distanceKm,
    /// `'ron95'` | `'diesel'` — highlights that price chip when set (e.g. cheapest spotlight).
    this.priceEmphasisFuel,
  });

  final StationMapItem item;
  final double? spotlightAverageRating;
  final int? spotlightReviewCount;
  final double? distanceKm;
  final String? priceEmphasisFuel;
}

/// Giao diện bottom sheet danh sách trạm — [standard] chỉ dùng khi cần fallback Material.
enum MapDiscoverySheetChrome {
  standard,
  /// Kết quả tìm kiếm từ khóa trên bản đồ — cùng hệ visual với modal Còn hàng / Gần nhất…
  keywordSearch,
  inStock,
  nearest,
  cheapest,
  topRated,
}

bool _chromeUsesUnifiedList(MapDiscoverySheetChrome c) =>
    c == MapDiscoverySheetChrome.keywordSearch ||
    c == MapDiscoverySheetChrome.inStock ||
    c == MapDiscoverySheetChrome.nearest ||
    c == MapDiscoverySheetChrome.cheapest ||
    c == MapDiscoverySheetChrome.topRated;

/// Đóng sheet rồi mới gọi [onChosen] sau frame — tránh rebuild/provider khi route modal còn đang dispose (lỗi `_dependents.isEmpty`).
void _popDiscoverySheetThenChoose(
  BuildContext sheetContext,
  Future<void> Function(MapStationListRow row) onChosen,
  MapStationListRow row,
) {
  Navigator.of(sheetContext).pop();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await onChosen(row);
  });
}

bool _hasRatingLine(MapStationListRow row) {
  if (row.spotlightAverageRating != null) return true;
  final c = row.spotlightReviewCount;
  return c != null && c > 0;
}

/// Highlight lần xuất hiện đầu (không phân biệt hoa thường) — an toàn khi không khớp.
Widget _discoveryHighlightedText(
  String text,
  String? highlightRaw,
  TextStyle style, {
  int maxLines = 2,
}) {
  final q = highlightRaw?.trim();
  if (q == null || q.isEmpty) {
    return Text(text, style: style, maxLines: maxLines, overflow: TextOverflow.ellipsis);
  }
  final lower = text.toLowerCase();
  final i = lower.indexOf(q.toLowerCase());
  if (i < 0) {
    return Text(text, style: style, maxLines: maxLines, overflow: TextOverflow.ellipsis);
  }
  final end = (i + q.length).clamp(0, text.length);
  final before = text.substring(0, i);
  final mid = text.substring(i, end);
  final after = end < text.length ? text.substring(end) : '';
  return Text.rich(
    TextSpan(
      style: style,
      children: [
        TextSpan(text: before),
        TextSpan(
          text: mid,
          style: style.copyWith(
            color: _InStockSheetColors.brandBlue,
            fontWeight: FontWeight.w900,
          ),
        ),
        TextSpan(text: after),
      ],
    ),
    maxLines: maxLines,
    overflow: TextOverflow.ellipsis,
  );
}

IconData _emptyStateIcon(MapDiscoverySheetChrome chrome) {
  return switch (chrome) {
    MapDiscoverySheetChrome.keywordSearch => Icons.search_rounded,
    MapDiscoverySheetChrome.nearest => Icons.near_me_outlined,
    MapDiscoverySheetChrome.cheapest => Icons.payments_outlined,
    MapDiscoverySheetChrome.topRated => Icons.star_outline_rounded,
    _ => Icons.local_gas_station_outlined,
  };
}

/// Google Maps–style draggable sheet of [MapStationListRow] entries.
Future<void> showMapDiscoveryResultsSheet({
  required BuildContext context,
  required List<MapStationListRow> rows,
  required String title,
  String? subtitle,
  String? emptyMessage,
  String? emptySubtitle,
  MapDiscoverySheetChrome chrome = MapDiscoverySheetChrome.standard,
  /// Gợi ý highlight từ khóa trong tên/địa chỉ (chỉ UI; an toàn khi null).
  String? keywordHighlight,
  double initialChildSize = 0.4,
  double minChildSize = 0.26,
  double maxChildSize = 0.9,
  required Future<void> Function(MapStationListRow row) onStationChosen,
}) {
  final topRadius = _chromeUsesUnifiedList(chrome) ? 24.0 : 20.0;
  final sheetBg =
      _chromeUsesUnifiedList(chrome) ? _InStockSheetColors.sheetBg : Theme.of(context).colorScheme.surface;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: sheetBg,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(topRadius)),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: initialChildSize.clamp(0.22, 0.92),
        minChildSize: minChildSize.clamp(0.18, 0.5),
        maxChildSize: maxChildSize.clamp(0.4, 1),
        builder: (context, scrollController) {
          if (rows.isEmpty) {
            if (_chromeUsesUnifiedList(chrome)) {
              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  _InStockEmptyState(
                    chrome: chrome,
                    title: title,
                    subtitle: subtitle,
                    message: emptyMessage ?? 'Chưa có dữ liệu',
                    subMessage: emptySubtitle ?? 'Vui lòng thử thay đổi bộ lọc hoặc khu vực tìm kiếm',
                  ),
                ],
              );
            }
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      emptyMessage ?? 'Không có kết quả.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            );
          }

          if (_chromeUsesUnifiedList(chrome)) {
            return ColoredBox(
              color: _InStockSheetColors.sheetBg,
              child: CustomScrollView(
                controller: scrollController,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    sliver: SliverToBoxAdapter(
                      child: _InStockSheetHeader(
                        chrome: chrome,
                        title: title,
                        subtitle: subtitle,
                        count: rows.length,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (listContext, i) {
                          final row = rows[i];
                          return Padding(
                            padding: EdgeInsets.only(bottom: i < rows.length - 1 ? 12 : 0),
                            child: MapStationDiscoveryTile(
                              row: row,
                              chrome: chrome,
                              highlightKeyword: keywordHighlight,
                              onTap: () => _popDiscoverySheetThenChoose(ctx, onStationChosen, row),
                            ),
                          );
                        },
                        childCount: rows.length,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.35,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (listContext, i) {
                      final row = rows[i];
                      return Padding(
                        padding: EdgeInsets.only(bottom: i < rows.length - 1 ? 4 : 0),
                        child: MapStationDiscoveryTile(
                          row: row,
                          onTap: () => _popDiscoverySheetThenChoose(ctx, onStationChosen, row),
                        ),
                      );
                    },
                    childCount: rows.length,
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Hàng kết quả tìm kiếm / spotlight — dùng lại cho modal “Giá rẻ nhất” v.v.
class MapStationDiscoveryTile extends StatelessWidget {
  const MapStationDiscoveryTile({
    super.key,
    required this.row,
    required this.onTap,
    this.chrome = MapDiscoverySheetChrome.standard,
    this.highlightKeyword,
  });

  final MapStationListRow row;
  final VoidCallback onTap;
  final MapDiscoverySheetChrome chrome;
  final String? highlightKeyword;

  @override
  Widget build(BuildContext context) {
    if (_chromeUsesUnifiedList(chrome)) {
      return _MapDiscoveryListStationCard(
        row: row,
        chrome: chrome,
        highlightKeyword: highlightKeyword,
        onTap: onTap,
      );
    }
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = row.item;
    final name = s.stationName.trim().isNotEmpty ? s.stationName : 'Cây xăng #${s.stationId}';
    final addr = s.shortAddress?.trim();
    final availability = StationOpenStatus.forMapItem(s);

    return Material(
      color: scheme.surfaceContainerLow.withValues(alpha: 0.92),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.07),
      surfaceTintColor: scheme.surfaceTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(Icons.local_gas_station_rounded, size: 22, color: scheme.onPrimaryContainer),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StationOpenStatusPill(
                          availability: availability,
                          dense: true,
                          showSecondary: true,
                        ),
                        if (row.distanceKm != null)
                          _MetaChip(
                            icon: Icons.near_me_outlined,
                            label: '${row.distanceKm!.toStringAsFixed(1)} km',
                            scheme: scheme,
                          ),
                      ],
                    ),
                    if (addr != null && addr.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        addr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (_standardPriceChips(context, row).isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _standardPriceChips(context, row),
                      ),
                    ],
                    if (_hasRatingLine(row)) ...[
                      const SizedBox(height: 8),
                      _RatingLine(row: row, theme: theme, scheme: scheme),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 4),
                child: Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant, size: 26),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<Widget> _standardPriceChips(BuildContext context, MapStationListRow row) {
  final s = row.item;
  final scheme = Theme.of(context).colorScheme;
  final out = <Widget>[];
  final em = row.priceEmphasisFuel?.toLowerCase();
  if (s.priceRon95 != null) {
    out.add(
      _PriceChip(
        label: 'RON 95',
        value: formatVndCurrency(s.priceRon95),
        scheme: scheme,
        emphasized: em == 'ron95',
      ),
    );
  }
  if (s.priceDiesel != null) {
    out.add(
      _PriceChip(
        label: 'Diesel',
        value: formatVndCurrency(s.priceDiesel),
        scheme: scheme,
        emphasized: em == 'diesel',
      ),
    );
  }
  return out;
}

abstract final class _InStockSheetColors {
  static const sheetBg = Color(0xFFF5FAFF);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFE6EEF8);
  static const textPrimary = Color(0xFF0B3A7A);
  static const textSecondary = Color(0xFF6B7897);
  static const brandBlue = Color(0xFF0F4C9A);
  static const accentGreen = Color(0xFF35D66B);
  static const statusOpenBg = Color(0xFFEAFBF1);
  static const statusOpenFg = Color(0xFF178A45);
  static const statusClosedBg = Color(0xFFFDECEC);
  static const statusClosedFg = Color(0xFFD93025);
  static const statusPausedBg = Color(0xFFFFF4E5);
  static const statusPausedFg = Color(0xFFC77700);
  static const distanceBg = Color(0xFFF1F5FB);
  static const distanceFg = Color(0xFF4D5B75);
  static const chipBg = Color(0xFFF7FAFF);
  static const chipBorder = Color(0xFFE2EAF5);
  static const chipText = Color(0xFF1F2A44);
  static const iconCircleBg = Color(0xFFE8F0FB);
  static const starGold = Color(0xFFFFB82E);
  static const priceHighlightBg = Color(0xFFE8F8EF);
  static const priceHighlightBorder = Color(0xFF35D66B);
}

class _InStockSheetHeader extends StatelessWidget {
  const _InStockSheetHeader({
    required this.chrome,
    required this.title,
    required this.subtitle,
    required this.count,
  });

  final MapDiscoverySheetChrome chrome;
  final String title;
  final String? subtitle;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: _InStockSheetColors.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _InStockSheetColors.textSecondary,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _MapDiscoveryHeaderBadge(chrome: chrome, theme: theme),
                if (chrome != MapDiscoverySheetChrome.keywordSearch) ...[
                  const SizedBox(height: 6),
                  Text(
                    '$count cửa hàng',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _InStockSheetColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _MapDiscoveryHeaderBadge extends StatelessWidget {
  const _MapDiscoveryHeaderBadge({required this.chrome, required this.theme});

  final MapDiscoverySheetChrome chrome;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    switch (chrome) {
      case MapDiscoverySheetChrome.inStock:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _InStockSheetColors.accentGreen.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _InStockSheetColors.accentGreen.withValues(alpha: 0.35)),
          ),
          child: Text(
            'Còn hàng',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF15803D),
            ),
          ),
        );
      case MapDiscoverySheetChrome.nearest:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _InStockSheetColors.iconCircleBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _InStockSheetColors.brandBlue.withValues(alpha: 0.22)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.navigation_rounded, size: 16, color: _InStockSheetColors.brandBlue),
              const SizedBox(width: 6),
              Text(
                'Gần nhất',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: _InStockSheetColors.brandBlue,
                ),
              ),
            ],
          ),
        );
      case MapDiscoverySheetChrome.cheapest:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _InStockSheetColors.priceHighlightBg.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _InStockSheetColors.priceHighlightBorder.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.payments_rounded, size: 16, color: _InStockSheetColors.brandBlue),
              const SizedBox(width: 6),
              Text(
                'Rẻ nhất',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: _InStockSheetColors.brandBlue,
                ),
              ),
            ],
          ),
        );
      case MapDiscoverySheetChrome.topRated:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _InStockSheetColors.starGold.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _InStockSheetColors.starGold.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, size: 18, color: _InStockSheetColors.starGold),
              const SizedBox(width: 4),
              Text(
                'Uy tín',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: _InStockSheetColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      case MapDiscoverySheetChrome.keywordSearch:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _InStockSheetColors.iconCircleBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _InStockSheetColors.brandBlue.withValues(alpha: 0.22)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_rounded, size: 18, color: _InStockSheetColors.brandBlue),
              const SizedBox(width: 6),
              Text(
                'Tìm kiếm',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: _InStockSheetColors.brandBlue,
                ),
              ),
            ],
          ),
        );
      case MapDiscoverySheetChrome.standard:
        return const SizedBox.shrink();
    }
  }
}

class _InStockEmptyState extends StatelessWidget {
  const _InStockEmptyState({
    required this.chrome,
    required this.title,
    required this.subtitle,
    required this.message,
    this.subMessage,
  });

  final MapDiscoverySheetChrome chrome;
  final String title;
  final String? subtitle;
  final String message;
  final String? subMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: _InStockSheetColors.textPrimary,
            ),
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _InStockSheetColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 28),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _InStockSheetColors.iconCircleBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _emptyStateIcon(chrome),
                    size: 40,
                    color: _InStockSheetColors.brandBlue.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _InStockSheetColors.textPrimary,
                  ),
                ),
                if (subMessage != null && subMessage!.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    subMessage!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _InStockSheetColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

IconData _inStockStatusIcon(StationAvailability a) {
  return switch (a.tone) {
    StationOpenTone.open => a.usedSchedule ? Icons.schedule_rounded : Icons.check_circle_rounded,
    StationOpenTone.closed => Icons.do_not_disturb_on_rounded,
    StationOpenTone.unknown => Icons.help_outline_rounded,
  };
}

class _InStockStatusBadge extends StatelessWidget {
  const _InStockStatusBadge({required this.availability});

  final StationAvailability availability;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (Color bg, Color fg) = switch (availability.tone) {
      StationOpenTone.open => (_InStockSheetColors.statusOpenBg, _InStockSheetColors.statusOpenFg),
      StationOpenTone.closed => (_InStockSheetColors.statusClosedBg, _InStockSheetColors.statusClosedFg),
      StationOpenTone.unknown => (_InStockSheetColors.statusPausedBg, _InStockSheetColors.statusPausedFg),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_inStockStatusIcon(availability), size: 18, color: fg),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  availability.primaryLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                if (availability.secondaryLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    availability.secondaryLabel!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: fg.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InStockDistanceBadge extends StatelessWidget {
  const _InStockDistanceBadge({required this.km, this.prominent = false});

  final double km;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconSize = prominent ? 18.0 : 16.0;
    final pad = prominent
        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 6);
    return Container(
      padding: pad,
      decoration: BoxDecoration(
        color: _InStockSheetColors.distanceBg,
        borderRadius: BorderRadius.circular(20),
        border: prominent ? Border.all(color: _InStockSheetColors.chipBorder) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.navigation_outlined, size: iconSize, color: _InStockSheetColors.distanceFg),
          const SizedBox(width: 6),
          Text(
            '${km.toStringAsFixed(1)} km',
            style: (prominent ? theme.textTheme.titleSmall : theme.textTheme.labelMedium)?.copyWith(
              fontWeight: FontWeight.w800,
              color: _InStockSheetColors.distanceFg,
            ),
          ),
        ],
      ),
    );
  }
}

class _InStockPriceChip extends StatelessWidget {
  const _InStockPriceChip({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.cheapestChromeHighlight = false,
  });

  final String label;
  final String value;
  final bool emphasized;
  /// Giá nổi bật (modal Rẻ nhất) — nền xanh nhạt, viền accent.
  final bool cheapestChromeHighlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final useGreen = cheapestChromeHighlight && emphasized;
    final bg = useGreen ? _InStockSheetColors.priceHighlightBg : _InStockSheetColors.chipBg;
    final borderColor = useGreen
        ? _InStockSheetColors.priceHighlightBorder
        : (emphasized ? _InStockSheetColors.brandBlue.withValues(alpha: 0.55) : _InStockSheetColors.chipBorder);
    final borderW = emphasized || useGreen ? 1.5 : 1.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: borderW,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: _InStockSheetColors.chipText.withValues(alpha: 0.85),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: useGreen ? _InStockSheetColors.brandBlue : _InStockSheetColors.chipText,
            ),
          ),
        ],
      ),
    );
  }
}

class _InStockPriceChipsRow extends StatelessWidget {
  const _InStockPriceChipsRow({required this.row, this.cheapestChromeHighlight = false});

  final MapStationListRow row;
  final bool cheapestChromeHighlight;

  @override
  Widget build(BuildContext context) {
    final s = row.item;
    final em = row.priceEmphasisFuel?.toLowerCase();
    final chips = <Widget>[];
    if (s.priceRon95 != null) {
      chips.add(
        _InStockPriceChip(
          label: 'RON 95',
          value: formatVndCurrency(s.priceRon95),
          emphasized: em == 'ron95',
          cheapestChromeHighlight: cheapestChromeHighlight,
        ),
      );
    }
    if (s.priceDiesel != null) {
      chips.add(
        _InStockPriceChip(
          label: 'Diesel',
          value: formatVndCurrency(s.priceDiesel),
          emphasized: em == 'diesel',
          cheapestChromeHighlight: cheapestChromeHighlight,
        ),
      );
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            chips[i],
          ],
        ],
      ),
    );
  }
}

class _InStockRatingLine extends StatelessWidget {
  const _InStockRatingLine({required this.row});

  final MapStationListRow row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avg = row.spotlightAverageRating;
    final count = row.spotlightReviewCount;
    final parts = <String>[];
    if (avg != null) {
      parts.add('${avg.toStringAsFixed(1)} ★');
    }
    if (count != null && count > 0) {
      parts.add('$count đánh giá');
    }
    if (parts.isEmpty) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        Icon(Icons.star_rounded, size: 18, color: _InStockSheetColors.starGold),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            parts.join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: _InStockSheetColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Dòng đánh giá nổi bật (modal Uy tín) — cùng dữ liệu [MapStationListRow], chỉ bố cục UI.
class _DiscoveryTopRatedProminentLine extends StatelessWidget {
  const _DiscoveryTopRatedProminentLine({required this.row});

  final MapStationListRow row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avg = row.spotlightAverageRating;
    final count = row.spotlightReviewCount;
    if (avg == null && (count == null || count <= 0)) {
      return const SizedBox.shrink();
    }
    final String text;
    if (avg != null) {
      text = (count != null && count > 0) ? '${avg.toStringAsFixed(1)} ($count)' : avg.toStringAsFixed(1);
    } else if (count != null && count > 0) {
      text = '$count đánh giá';
    } else {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _InStockSheetColors.starGold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _InStockSheetColors.starGold.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 22, color: _InStockSheetColors.starGold),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: _InStockSheetColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapDiscoveryListStationCard extends StatelessWidget {
  const _MapDiscoveryListStationCard({
    required this.row,
    required this.chrome,
    required this.onTap,
    this.highlightKeyword,
  });

  final MapStationListRow row;
  final MapDiscoverySheetChrome chrome;
  final VoidCallback onTap;
  final String? highlightKeyword;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = row.item;
    final name = s.stationName.trim().isNotEmpty ? s.stationName : 'Cây xăng #${s.stationId}';
    final addr = s.shortAddress?.trim();
    final availability = StationOpenStatus.forMapItem(s);
    final isNearest = chrome == MapDiscoverySheetChrome.nearest;
    final isCheapest = chrome == MapDiscoverySheetChrome.cheapest;
    final isTopRated = chrome == MapDiscoverySheetChrome.topRated;
    final showDistance = row.distanceKm != null;

    return Material(
      color: _InStockSheetColors.card,
      elevation: 2,
      shadowColor: const Color(0x120F4C9A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: _InStockSheetColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: _InStockSheetColors.iconCircleBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_gas_station_rounded,
                  size: 26,
                  color: _InStockSheetColors.brandBlue.withValues(alpha: 0.88),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _discoveryHighlightedText(
                      name,
                      highlightKeyword,
                      (theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16)).copyWith(
                        fontWeight: FontWeight.w800,
                        color: _InStockSheetColors.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _InStockStatusBadge(availability: availability),
                    if (addr != null && addr.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color: _InStockSheetColors.textSecondary.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _discoveryHighlightedText(
                              addr,
                              highlightKeyword,
                              (theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14)).copyWith(
                                color: _InStockSheetColors.textSecondary,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (showDistance) ...[
                      const SizedBox(height: 10),
                      _InStockDistanceBadge(
                        km: row.distanceKm!,
                        prominent: isNearest,
                      ),
                    ],
                    if (_inStockHasPrices(row)) ...[
                      const SizedBox(height: 12),
                      _InStockPriceChipsRow(
                        row: row,
                        cheapestChromeHighlight: isCheapest,
                      ),
                    ],
                    if (isTopRated && _hasRatingLine(row)) ...[
                      const SizedBox(height: 10),
                      _DiscoveryTopRatedProminentLine(row: row),
                    ] else if (_hasRatingLine(row)) ...[
                      const SizedBox(height: 10),
                      _InStockRatingLine(row: row),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 6, top: 2),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: _InStockSheetColors.textSecondary,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _inStockHasPrices(MapStationListRow row) {
  return row.item.priceRon95 != null || row.item.priceDiesel != null;
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.scheme,
  });

  final IconData icon;
  final String label;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  const _PriceChip({
    required this.label,
    required this.value,
    required this.scheme,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final ColorScheme scheme;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: emphasized ? scheme.primaryContainer.withValues(alpha: 0.9) : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: emphasized ? scheme.primary.withValues(alpha: 0.55) : scheme.outlineVariant.withValues(alpha: 0.35),
          width: emphasized ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}

class _RatingLine extends StatelessWidget {
  const _RatingLine({
    required this.row,
    required this.theme,
    required this.scheme,
  });

  final MapStationListRow row;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final avg = row.spotlightAverageRating;
    final count = row.spotlightReviewCount;
    final parts = <String>[];
    if (avg != null) {
      parts.add('${avg.toStringAsFixed(1)} ★');
    }
    if (count != null && count > 0) {
      parts.add('$count đánh giá');
    }
    if (parts.isEmpty) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        Icon(Icons.star_rounded, size: 18, color: scheme.tertiary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            parts.join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
