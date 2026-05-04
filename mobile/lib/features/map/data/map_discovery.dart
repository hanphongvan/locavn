import '../../../core/map/app_lat_lng.dart';
import '../../stations/data/models/station_map_item.dart';
import '../../stations/domain/station_availability.dart';
import '../../stations/station_open_status.dart';

/// Last-used quick shortcut (for chip selection UI).
enum MapDiscoveryShortcut { none, nearest, cheapest, bestRated, openNow }

/// Client-side discovery on the **already loaded** map marker set (may be truncated by API).
abstract final class MapDiscovery {
  static double _dist2(StationMapItem s, AppLatLng origin) {
    final dx = s.latitude - origin.latitude;
    final dy = s.longitude - origin.longitude;
    return dx * dx + dy * dy;
  }

  /// Nearest by straight-line distance in lat/lng space (fast proxy; same ordering as Haversine for ranking).
  static List<StationMapItem> nearest(List<StationMapItem> items, AppLatLng user) {
    final copy = List<StationMapItem>.from(items);
    copy.sort((a, b) => _dist2(a, user).compareTo(_dist2(b, user)));
    return copy;
  }

  /// Stations resolved as “open” (schedule or server fallback).
  static List<StationMapItem> openNow(List<StationMapItem> items, {DateTime? clock}) {
    return items.where((e) {
      final a = StationOpenStatus.forMapItem(e, clock: clock);
      return a.tone == StationOpenTone.open;
    }).toList();
  }

}
