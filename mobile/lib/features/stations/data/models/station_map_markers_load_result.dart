import 'station_map_item.dart';

/// Result of loading map markers across `/api/stations/map` (and optional keyword ∩ list).
class StationMapMarkersLoadResult {
  const StationMapMarkersLoadResult({
    required this.items,
    required this.mapTotalCount,
    required this.truncated,
    this.keywordApplied = false,
    this.keywordListTruncated = false,
    /// Số trạm sau merge từ khóa, **trước** lọc chip client-side (để phân biệt “trống do lọc”).
    this.loadedItemCount,
  });

  final List<StationMapItem> items;

  /// Total stations with coordinates matching geo filters (`GET /api/stations/map` totalCount).
  final int mapTotalCount;

  /// Map pages stopped early (client cap).
  final bool truncated;

  /// True when [items] were filtered by keyword via `GET /api/stations`.
  final bool keywordApplied;

  /// True when list paging stopped before all keyword matches were fetched.
  final bool keywordListTruncated;

  /// Mặc định bằng [items.length] khi không truyền (luồng tải thuần).
  final int? loadedItemCount;

  int get effectiveLoadedCount => loadedItemCount ?? items.length;

  bool get isEmptyDueToClientFilters =>
      items.isEmpty && !keywordApplied && effectiveLoadedCount > 0;
}
