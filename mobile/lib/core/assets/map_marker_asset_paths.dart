/// Canonical paths for bundled station / stock map marker PNGs.
///
/// Files live under `assets/map_markers/` at the package root (not under `lib/`).
/// Declared explicitly in `pubspec.yaml` so the bundle stays predictable.
///
/// Inventory stock map: API `stockStatus` (`out` / `low` / `normal`) dùng cùng các file
/// này (BitmapDescriptor / `MapStationMarkerFactory` trên Google Map).
abstract final class MapMarkerAssetPaths {
  static const String stationClosed = 'assets/map_markers/station_closed.png';
  static const String stationCheap = 'assets/map_markers/station_cheap.png';
  static const String stationOpen = 'assets/map_markers/station_open.png';

  /// Leader — doanh nghiệp đầu mối (lớp riêng, không dùng marker vẽ tay).
  static const String distributorSafe = 'assets/map_markers/distributor_safe.png';
  static const String distributorWarning = 'assets/map_markers/distributor_warning.png';
  static const String distributorDanger = 'assets/map_markers/distributor_danger.png';

  /// All registered marker rasters (e.g. for tests and tooling).
  static const List<String> all = [
    stationClosed,
    stationCheap,
    stationOpen,
    distributorSafe,
    distributorWarning,
    distributorDanger,
  ];
}
