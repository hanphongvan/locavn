import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../stations/data/models/station_map_markers_load_result.dart';
import '../data/map_discovery.dart';
import '../data/map_filters.dart';
import 'map_discovery_navigation.dart';
import 'map_discovery_results_sheet.dart';
import 'map_filter_sheet.dart';
import 'map_providers.dart';
import 'map_screen_palette.dart';

/// Thanh tìm kiếm nổi — nền trắng cả thanh; viền / đổ bóng nhẹ.
class MapSearchBar extends ConsumerStatefulWidget {
  const MapSearchBar({super.key});

  @override
  ConsumerState<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends ConsumerState<MapSearchBar> {
  late final TextEditingController _controller;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(mapFiltersProvider).keyword ?? '';
    _controller = TextEditingController(text: initial);
    _focus = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _onRefreshMarkers() async {
    ref.invalidate(stationMapMarkersFetchProvider);
    await ref.read(stationMapMarkersFetchProvider.future);
  }

  Future<void> _submitKeyword(BuildContext context) async {
    final t = _controller.text.trim();
    ref.read(mapDiscoveryShortcutProvider.notifier).state = MapDiscoveryShortcut.none;
    mapClearCheapSpotlightMarker(ref);
    ref.read(mapFiltersProvider.notifier).state = ref.read(mapFiltersProvider).copyWithKeyword(t.isEmpty ? null : t);
    FocusScope.of(context).unfocus();

    if (t.isEmpty) return;

    try {
      await ref.read(stationMapMarkersFetchProvider.future);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tải được bản đồ sau khi tìm.')),
        );
      }
      return;
    }

    if (!context.mounted) return;
    final data = ref.read(stationMapMarkersProvider).asData?.value;
    if (data == null) return;

    await _showKeywordResultsSheet(context, t, data);
  }

  Future<void> _showKeywordResultsSheet(
    BuildContext context,
    String keyword,
    StationMapMarkersLoadResult data,
  ) {
    return showMapDiscoveryResultsSheet(
      context: context,
      rows: data.items.map((e) => MapStationListRow(item: e)).toList(),
      title: 'Kết quả tìm kiếm',
      subtitle: '${data.items.length} kết quả',
      chrome: MapDiscoverySheetChrome.keywordSearch,
      keywordHighlight: keyword,
      emptyMessage: 'Không tìm thấy kết quả',
      emptySubtitle: 'Vui lòng thử từ khóa khác hoặc thay đổi khu vực tìm kiếm',
      initialChildSize: data.items.length <= 3 ? 0.34 : 0.42,
      onStationChosen: (row) => focusMapStationAndOpenSummary(context, ref, row.item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(mapFiltersProvider);
    final focused = _focus.hasFocus;
    final elevated = focused || filters.hasActiveKeyword || _controller.text.isNotEmpty;

    ref.listen<MapFilters>(mapFiltersProvider, (prev, next) {
      if (prev?.keyword != next.keyword && !_focus.hasFocus) {
        final t = next.keyword ?? '';
        if (_controller.text != t) {
          _controller.value = TextEditingValue(
            text: t,
            selection: TextSelection.collapsed(offset: t.length),
          );
        }
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: MapScreenPalette.cardWhite,
        borderRadius: BorderRadius.circular(MapScreenPalette.radiusMd + 2),
        border: Border.all(
          color: elevated
              ? MapScreenPalette.primaryBlue.withValues(alpha: 0.35)
              : MapScreenPalette.chipInactiveBorder,
          width: elevated ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: elevated ? 0.12 : 0.08),
            blurRadius: elevated ? 14 : 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.search_rounded, color: MapScreenPalette.textPrimary, size: 24),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => unawaited(_submitKeyword(context)),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: MapScreenPalette.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                decoration: InputDecoration(
                  hintText: 'Tìm cây xăng, địa điểm...',
                  hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: MapScreenPalette.textSecondary.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w500,
                      ),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(MapScreenPalette.radiusSm),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(MapScreenPalette.radiusSm),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(MapScreenPalette.radiusSm),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: filters.hasActiveKeyword || _controller.text.isNotEmpty
                      ? IconButton(
                          tooltip: 'Xóa từ khóa',
                          icon: const Icon(Icons.close_rounded, size: 20, color: MapScreenPalette.textPrimary),
                          onPressed: () {
                            _controller.clear();
                            ref.read(mapFiltersProvider.notifier).state = filters.copyWithKeyword(null);
                            ref.read(mapDiscoveryShortcutProvider.notifier).state = MapDiscoveryShortcut.none;
                            mapClearCheapSpotlightMarker(ref);
                          },
                        )
                      : null,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Làm mới dữ liệu',
              onPressed: () => unawaited(_onRefreshMarkers()),
              icon: const Icon(Icons.refresh_rounded, color: MapScreenPalette.textPrimary),
            ),
            IconButton(
              tooltip: 'Bộ lọc',
              onPressed: () => showMapFilterSheet(context, ref),
              icon: const Icon(Icons.tune_rounded, color: MapScreenPalette.primaryBlue),
            ),
          ],
        ),
      ),
    );
  }
}
