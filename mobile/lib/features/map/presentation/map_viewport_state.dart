import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/map/app_lat_lng_bounds.dart';

/// Trạng thái camera bản đồ ở thời điểm gần nhất (cập nhật khi `onCameraIdle` debounce).
/// Dùng làm tham số cho viewport-aware fetch (Phase 2.G).
class MapViewport {
  const MapViewport({required this.zoom, required this.bounds});
  final double zoom;
  final AppLatLngBounds bounds;

  @override
  bool operator ==(Object other) =>
      other is MapViewport && other.zoom == zoom && other.bounds == bounds;

  @override
  int get hashCode => Object.hash(zoom, bounds);
}

/// Ngưỡng zoom phân biệt cluster (tỉnh) vs marker chi tiết (trạm).
/// Dưới ngưỡng → fetch `/map/clusters` (1 marker / 1 tỉnh). ≥ ngưỡng → fetch `/map/bounds`.
const double kMapClusterZoomThreshold = 11.0;

/// Camera state hiện tại — `null` nghĩa là chưa biết (chưa có frame nào idle).
final mapViewportProvider = StateProvider<MapViewport?>((_) => null);
