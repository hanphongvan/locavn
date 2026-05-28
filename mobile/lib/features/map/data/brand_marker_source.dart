import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/assets/brand_marker_registry.dart';

/// Cache `ui.Image` cho marker brand bundled (`<brand>_<kind>.png`).
///
/// 200 trạm cùng brand+kind+DPR chỉ decode ảnh 1 lần — composer dùng `markerImageSync`
/// để vẽ vào canvas. Cache không evict trong session: 3 brand × 3 kind × 1 size ≈ 9
/// ảnh × ~40KB ≈ 360KB, ổn với mọi cấu hình máy.
///
/// **Hợp đồng:** [BrandMarkerRegistry] chỉ trả path bundled (whitelist slug). Brand
/// không bundle → composer rơi về marker chung [MapStationMarkerFactory].
class BrandMarkerSource {
  BrandMarkerSource._();

  static final BrandMarkerSource instance = BrandMarkerSource._();

  final Map<String, ui.Image> _images = {};
  final Map<String, Future<ui.Image?>> _inflight = {};

  String _key(String brandKey, String kind, int sizePx) =>
      '${brandKey}_$kind@$sizePx';

  ui.Image? markerImageSync(String? brandKey, String kind, int sizePx) {
    if (brandKey == null) return null;
    return _images[_key(brandKey, kind, sizePx)];
  }

  Future<ui.Image?> markerImage(String brandKey, String kind, int sizePx) async {
    final path = BrandMarkerRegistry.assetPathFor(brandKey, kind);
    if (path == null) return null;
    final cacheKey = _key(brandKey, kind, sizePx);
    final hit = _images[cacheKey];
    if (hit != null) return hit;
    final pending = _inflight[cacheKey];
    if (pending != null) return pending;
    final future = _decode(path: path, sizePx: sizePx).then((img) {
      _inflight.remove(cacheKey);
      if (img != null) {
        _images[cacheKey] = img;
      }
      return img;
    });
    _inflight[cacheKey] = future;
    return future;
  }

  /// Preload toàn bộ 9 marker bundled (3 brand × 3 kind) ở [sizePx].
  /// Gọi cùng `MapStationMarkerFactory.preloadAll` trong [MapStationMapBody._buildMarkers].
  Future<void> preloadAll(int sizePx) async {
    await Future.wait([
      for (final brand in BrandMarkerRegistry.bundled)
        for (final kind in BrandMarkerRegistry.kinds)
          markerImage(brand, kind, sizePx),
    ]);
  }

  Future<ui.Image?> _decode({required String path, required int sizePx}) async {
    try {
      final raw = await rootBundle.load(path);
      final bytes = raw.buffer.asUint8List();
      // Placeholder (1×1, ~67 B) hoặc file rỗng — bỏ qua, composer rơi về marker chung.
      if (bytes.length < 200) {
        if (kDebugMode) {
          debugPrint(
            'BrandMarkerSource: "$path" chỉ ${bytes.length} B — coi như chưa có. '
            'Thay file PNG thật (48×56 nền trong suốt) rồi rebuild app.',
          );
        }
        return null;
      }
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: sizePx,
      );
      final frame = await codec.getNextFrame();
      codec.dispose();
      return frame.image;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BrandMarkerSource: decode $path failed — $e');
      }
      return null;
    }
  }

  @visibleForTesting
  void clearAll() {
    for (final img in _images.values) {
      img.dispose();
    }
    _images.clear();
    _inflight.clear();
  }
}
