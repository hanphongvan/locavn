import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/map/app_map_marker.dart';
import 'leader_distributor_marker_assets.dart';

/// Marker đầu mối: PNG trạng thái (safe / warning / danger) + **viên pill số ngày dự trữ**
/// (cùng ý bố cục với marker cửa hàng: icon + nhãn dưới).
abstract final class LeaderDistributorMapMarker {
  /// Neo đáy giữa — điểm địa lý trùng cạnh dưới bitmap (đồng bộ `MapStationMarkerComposer.anchor`).
  static const AppMapAnchor anchor = AppMapAnchor.bottom;

  static const double _logicalW = 48;
  static const double _logicalH = 56;

  static final LinkedHashMap<String, AppMapMarkerIcon> _cache = LinkedHashMap();
  static final Map<String, Future<ByteData>> _bundleFutures = {};

  static Future<ByteData> _bundleBytes(String path) {
    return _bundleFutures.putIfAbsent(path, () => rootBundle.load(path));
  }

  static Future<ui.Image?> _decodeIcon(String path, int targetPx) async {
    try {
      final raw = await _bundleBytes(path);
      final codec = await ui.instantiateImageCodec(
        raw.buffer.asUint8List(),
        targetWidth: targetPx,
      );
      final frame = await codec.getNextFrame();
      codec.dispose();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  static String _coverageDaysLabel(double? days) {
    if (days == null) return '—';
    if (days >= 999) return '999+ ngày';
    final whole = days == days.roundToDouble();
    final n = whole ? days.round().toString() : days.toStringAsFixed(1);
    return '$n ngày';
  }

  static String _cacheKey(int displayStatus, double dpr, double? days) {
    final d = days == null ? 'null' : days.toStringAsFixed(1);
    return 'ds_${displayStatus}_${dpr.toStringAsFixed(2)}_$d';
  }

  static void _remember(String key, AppMapMarkerIcon d) {
    _cache.remove(key);
    _cache[key] = d;
    while (_cache.length > 60) {
      _cache.remove(_cache.keys.first);
    }
  }

  static Future<AppMapMarkerIcon> buildIcon({
    required int displayStatus,
    required double? coverageDays,
    required double devicePixelRatio,
  }) async {
    final dpr = devicePixelRatio.clamp(2.0, 3.0);
    final path = getDistributorMarkerAssetForDisplayStatus(displayStatus);
    final key = _cacheKey(displayStatus, dpr, coverageDays);
    final hit = _cache[key];
    if (hit != null) {
      _cache.remove(key);
      _cache[key] = hit;
      return hit;
    }

    final tw = (_logicalW * dpr).round();
    final th = (_logicalH * dpr).round();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final scale = dpr;

    const bottomMargin = 3.0;
    const pillHLogical = 15.0;
    const gapIconPill = 2.0;
    const iconLogical = 36.0;

    final pillH = pillHLogical * scale;
    final pillBottom = th - bottomMargin * scale;
    final pillTop = pillBottom - pillH;
    final iconBottom = pillTop - gapIconPill * scale;
    final iconH = iconLogical * scale;
    final iconTop = iconBottom - iconH;
    final cx = tw / 2;
    final iconCenter = Offset(cx, iconTop + iconH / 2);

    final groundShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * scale);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, iconBottom - 2 * scale),
        width: iconH * 0.72,
        height: iconH * 0.28,
      ),
      groundShadow,
    );

    final innerPx = (iconH * 0.88).round().clamp(24, 200);
    final inner = await _decodeIcon(path, innerPx);
    if (inner != null) {
      final iw = inner.width.toDouble();
      final ih = inner.height.toDouble();
      final dst = Rect.fromCenter(center: iconCenter, width: iconH, height: iconH);
      final src = Rect.fromLTWH(0, 0, iw, ih);
      canvas.drawImageRect(inner, src, dst, Paint()..filterQuality = FilterQuality.medium);
      inner.dispose();
    } else {
      // PNG decode fail → fallback dùng asset trực tiếp (provider tự load).
      return AppMapMarkerIconAsset(assetPath: path, devicePixelRatio: dpr);
    }

    final maxLabelW = tw - 4 * scale;
    final hPad = 3 * scale;
    var fontPx = 8.5 * scale;
    final label = _coverageDaysLabel(coverageDays);
    late TextPainter tp;
    for (var attempt = 0; attempt < 6; attempt++) {
      tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontPx,
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxLabelW - 2 * hPad);
      if (tp.width <= maxLabelW - 2 * hPad || fontPx <= 6.0 * scale) break;
      fontPx -= 0.75 * scale;
    }

    final pillW = (tp.width + 2 * hPad).clamp(28.0 * scale, tw.toDouble());
    final pillLeft = (tw - pillW) / 2;
    final pill = RRect.fromRectAndRadius(
      Rect.fromLTWH(pillLeft, pillTop, pillW, pillH),
      Radius.circular(pillH / 2),
    );

    final status = getDistributorStatusColorForDisplayStatus(displayStatus);
    final statusDeep = Color.lerp(status, Colors.black, 0.18)!;
    final pillBg = Paint()
      ..shader = LinearGradient(
        colors: [statusDeep, status],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(pillLeft, pillTop, pillW, pillH));
    canvas.drawRRect(pill, pillBg);

    tp.paint(canvas, Offset(pillLeft + hPad, pillTop + (pillH - tp.height) / 2));

    final picture = recorder.endRecording();
    final image = await picture.toImage(tw, th);
    picture.dispose();
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (png == null || png.lengthInBytes == 0) {
      final fallback = AppMapMarkerIconAsset(assetPath: path, devicePixelRatio: dpr);
      _remember(key, fallback);
      return fallback;
    }

    final icon = AppMapMarkerIconBytes(
      pngBytes: png.buffer.asUint8List(),
      devicePixelRatio: dpr,
    );
    _remember(key, icon);
    return icon;
  }
}
