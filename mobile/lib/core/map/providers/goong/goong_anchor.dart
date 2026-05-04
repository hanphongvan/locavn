import '../../app_map_marker.dart';

/// MapLibre `iconAnchor` chỉ nhận chuỗi enum (xem maplibre style spec).
/// Map AppMapAnchor → tên hợp lệ; ngoài 9 vị trí chuẩn → quy về cạnh gần nhất.
String goongIconAnchor(AppMapAnchor a) {
  final x = a.x;
  final y = a.y;
  final isLeft = x < 1 / 3;
  final isRight = x > 2 / 3;
  final isTop = y < 1 / 3;
  final isBottom = y > 2 / 3;

  if (isTop && isLeft) return 'top-left';
  if (isTop && isRight) return 'top-right';
  if (isBottom && isLeft) return 'bottom-left';
  if (isBottom && isRight) return 'bottom-right';
  if (isTop) return 'top';
  if (isBottom) return 'bottom';
  if (isLeft) return 'left';
  if (isRight) return 'right';
  return 'center';
}
