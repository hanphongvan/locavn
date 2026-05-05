/// Goong style URLs cho MapLibre GL — tiles từ `tiles.goong.io`.
/// Map Tiles Key (KHÁC REST API key) truyền qua `?api_key=...`.
/// Xem `mobile/docs/map-provider-architecture.md`.
abstract final class GoongStyle {
  GoongStyle._();

  static const String _host = 'https://tiles.goong.io';
  static const String _highlightPath = '/assets/goong_map_highlight.json';
  static const String _satellitePath = '/assets/goong_satellite.json';

  static String highlight(String mapTilesKey) =>
      '$_host$_highlightPath?api_key=${Uri.encodeQueryComponent(mapTilesKey)}';

  static String satellite(String mapTilesKey) =>
      '$_host$_satellitePath?api_key=${Uri.encodeQueryComponent(mapTilesKey)}';
}
