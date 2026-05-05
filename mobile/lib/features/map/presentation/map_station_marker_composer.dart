import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/assets/map_marker_asset_paths.dart';
import '../../../core/formatting/vnd_currency_format.dart';
import '../../../core/map/app_map_marker.dart';
import '../../stations/data/models/station_map_item.dart';
import 'map_providers.dart';
import 'map_screen_palette.dart';
import 'map_station_marker_factory.dart';

/// Marker bitmap: icon trạm (asset) + viên giá — không nền thẻ trắng; cache theo DPR / trạng thái / giá.
abstract final class MapStationMarkerComposer {
  /// Khung logic — **48×56** dp, đồng bộ [MapStationMarkerFactory._logicalMarkerSize].
  static const Size _logicalSize = Size(48, 56);
  static const AppMapAnchor anchor = AppMapAnchor.bottom;

  static final LinkedHashMap<String, AppMapMarkerIcon> _cache = LinkedHashMap();

  /// Tránh đọc lặp asset PNG từ disk khi compose nhiều marker.
  static final Map<String, Future<ByteData>> _bundleLoadFutures = {};

  static String _pathForKind(StationMapMarkerAssetKind kind) => switch (kind) {
        StationMapMarkerAssetKind.open => MapMarkerAssetPaths.stationOpen,
        StationMapMarkerAssetKind.closed => MapMarkerAssetPaths.stationClosed,
        StationMapMarkerAssetKind.cheap => MapMarkerAssetPaths.stationCheap,
      };

  static double? _price(StationMapItem item, MapMarkerFuelPriceMode mode) =>
      mode == MapMarkerFuelPriceMode.ron95 ? item.priceRon95 : item.priceDiesel;

  static String _cacheKey({
    required int stationId,
    required StationMapMarkerAssetKind kind,
    required bool selected,
    required double dpr,
    required MapMarkerFuelPriceMode fuel,
    required double? price,
    required bool displayBothFuelPrices,
    double? priceRon95,
    double? priceDiesel,
  }) {
    if (displayBothFuelPrices) {
      return '${stationId}_${kind.name}_${selected ? 1 : 0}_${dpr.toStringAsFixed(1)}_dual_'
          '${priceRon95?.round() ?? -1}_${priceDiesel?.round() ?? -1}';
    }

    return '${stationId}_${kind.name}_${selected ? 1 : 0}_${dpr.toStringAsFixed(1)}_${fuel.name}_${price?.round() ?? -1}';
  }

  static void _remember(String key, AppMapMarkerIcon d) {
    _cache.remove(key);
    _cache[key] = d;
    while (_cache.length > 160) {
      _cache.remove(_cache.keys.first);
    }
  }

  static Future<ByteData> _bundleBytes(String path) {
    return _bundleLoadFutures.putIfAbsent(path, () => rootBundle.load(path));
  }

  static Future<ui.Image?> _decodeInnerIcon(String path, int px) async {
    try {
      final raw = await _bundleBytes(path);
      final codec = await ui.instantiateImageCodec(
        raw.buffer.asUint8List(),
        targetWidth: px,
        targetHeight: px,
      );
      final frame = await codec.getNextFrame();
      codec.dispose();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  static Future<AppMapMarkerIcon> buildIcon({
    required StationMapItem item,
    required StationMapMarkerAssetKind kind,
    required bool selected,
    required double devicePixelRatio,
    required MapMarkerFuelPriceMode fuelMode,
    /// `true`: hai dòng giá (RON95 + diesel). `false`: một dòng theo [fuelMode] (bản đồ Lãnh đạo dùng false).
    bool displayBothFuelPrices = false,
  }) async {
    final dpr = devicePixelRatio.clamp(2.0, 3.0);
    final price = _price(item, fuelMode);
    final key = _cacheKey(
      stationId: item.stationId,
      kind: kind,
      selected: selected,
      dpr: dpr,
      fuel: fuelMode,
      price: price,
      displayBothFuelPrices: displayBothFuelPrices,
      priceRon95: item.priceRon95,
      priceDiesel: item.priceDiesel,
    );
    final cached = _cache[key];
    if (cached != null) {
      _cache.remove(key);
      _cache[key] = cached;
      return cached;
    }

    final logicalW = displayBothFuelPrices ? 52.0 : _logicalSize.width;
    final logicalH = displayBothFuelPrices ? 62.0 : _logicalSize.height;
    final tw = (logicalW * dpr).round();
    final th = (logicalH * dpr).round();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final scale = dpr;

    const bottomMargin = 3.0;
    final pillHLogical = displayBothFuelPrices ? 22.0 : 15.0;
    const gapIconPill = 2.0;
    /// Icon trạm: nhỏ hơn một chút khi có hai dòng giá.
    final iconLogical = displayBothFuelPrices ? 30.0 : 36.0;
    final pillH = pillHLogical * scale;
    final pillBottom = th - bottomMargin * scale;
    final pillTop = pillBottom - pillH;
    final iconBottom = pillTop - gapIconPill * scale;
    final iconH = iconLogical * scale;
    final iconTop = iconBottom - iconH;
    final cx = tw / 2;
    final iconCenter = Offset(cx, iconTop + iconH / 2);

    // Bóng nhẹ dưới icon (không dùng thẻ trắng).
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

    if (selected) {
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * scale
        ..color = MapScreenPalette.primaryBlue;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: iconCenter, width: iconH + 4 * scale, height: iconH + 4 * scale),
          Radius.circular(10 * scale),
        ),
        ring,
      );
    }

    final innerPx = (iconH * 0.88).round().clamp(24, 200);
    final inner = await _decodeInnerIcon(_pathForKind(kind), innerPx);
    if (inner != null) {
      final iw = inner.width.toDouble();
      final ih = inner.height.toDouble();
      final dst = Rect.fromCenter(center: iconCenter, width: iconH, height: iconH);
      final src = Rect.fromLTWH(0, 0, iw, ih);
      canvas.drawImageRect(inner, src, dst, Paint()..filterQuality = FilterQuality.medium);
      inner.dispose();
    } else {
      final iconPaint = Paint()..color = MapScreenPalette.textSecondary;
      canvas.drawCircle(iconCenter, iconH * 0.32, iconPaint);
    }

    final maxLabelW = tw - 4 * scale;
    final hPad = 3 * scale;
    var fontPx = displayBothFuelPrices ? 7.2 * scale : 8.5 * scale;
    late TextPainter tp;
    if (displayBothFuelPrices) {
      final xLabel = 'Xăng: ${formatVndIntegerDigits(item.priceRon95)}';
      final dLabel = 'Dầu: ${formatVndIntegerDigits(item.priceDiesel)}';
      for (var attempt = 0; attempt < 6; attempt++) {
        tp = TextPainter(
          text: TextSpan(
            style: TextStyle(
              color: Colors.white,
              fontSize: fontPx,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            children: [
              TextSpan(text: '$xLabel\n'),
              TextSpan(text: dLabel),
            ],
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: maxLabelW - 2 * hPad);
        if (tp.width <= maxLabelW - 2 * hPad || fontPx <= 6.0 * scale) break;
        fontPx -= 0.5 * scale;
      }
    } else {
      final label = formatVndIntegerDigits(price);
      for (var attempt = 0; attempt < 5; attempt++) {
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
        if (tp.width <= maxLabelW - 2 * hPad || fontPx <= 6.5 * scale) break;
        fontPx -= 0.75 * scale;
      }
    }
    final pillW = (tp.width + 2 * hPad).clamp(28.0 * scale, tw.toDouble());
    final pillLeft = (tw - pillW) / 2;
    final pill = RRect.fromRectAndRadius(
      Rect.fromLTWH(pillLeft, pillTop, pillW, pillH),
      Radius.circular(pillH / 2),
    );
    final pillBg = Paint()
      ..shader = LinearGradient(
        colors: const [MapScreenPalette.primaryBlue, Color(0xFF2563EB)],
      ).createShader(Rect.fromLTWH(pillLeft, pillTop, pillW, pillH));
    canvas.drawRRect(pill, pillBg);

    tp.paint(canvas, Offset(pillLeft + hPad, pillTop + (pillH - tp.height) / 2));

    final picture = recorder.endRecording();
    final image = await picture.toImage(tw, th);
    picture.dispose();
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (png == null || png.lengthInBytes == 0) {
      return MapStationMarkerFactory.iconFor(kind: kind, devicePixelRatio: dpr);
    }
    final bytes = png.buffer.asUint8List();
    final icon = AppMapMarkerIconBytes(
      pngBytes: bytes,
      devicePixelRatio: dpr,
    );
    _remember(key, icon);
    return icon;
  }
}
