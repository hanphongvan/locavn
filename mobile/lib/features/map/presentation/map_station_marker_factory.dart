import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/assets/map_marker_asset_paths.dart';
import '../../../core/map/app_map_marker.dart';
import '../../stations/data/models/station_map_item.dart';
import '../../stations/domain/station_availability.dart';
import '../../stations/station_open_status.dart';

/// Which bundled PNG to use for a station pin (see `assets/map_markers/`).
enum StationMapMarkerAssetKind { open, closed, cheap }

/// Asset-backed map markers — provider-agnostic (xem `lib/core/map/`).
///
/// Selection rules (single place):
/// 1. Closed → [station_closed.png]
/// 2. Open + cheapest spotlight id match → [station_cheap.png]
/// 3. Otherwise (open or unknown) → [station_open.png]
///
/// **Anchor:** assumes artwork tip at bottom center; adjust [_anchor] if your PNG differs.
abstract final class MapStationMarkerFactory {
  static const String _openAsset = MapMarkerAssetPaths.stationOpen;
  static const String _closedAsset = MapMarkerAssetPaths.stationClosed;
  static const String _cheapAsset = MapMarkerAssetPaths.stationCheap;

  /// Bottom tip of the pin → geographic point (tune when replacing marker art).
  static const AppMapAnchor anchor = AppMapAnchor.bottom;

  /// Logical on-map footprint; combined with [devicePixelRatio] for sharp decoding.
  static const Size _logicalMarkerSize = Size(48, 56);

  static final Map<String, AppMapMarkerIcon> _cache = {};
  static final Map<String, Future<AppMapMarkerIcon>> _inFlight = {};

  /// Quantize DPR so cache stays small but stays sharp on high-density screens.
  static double _markerDecodeDpr(double raw) {
    if (raw.isNaN || raw <= 0) return 2.5;
    return raw.clamp(2.0, 3.0);
  }

  static String _assetForKind(StationMapMarkerAssetKind kind) => switch (kind) {
        StationMapMarkerAssetKind.open => _openAsset,
        StationMapMarkerAssetKind.closed => _closedAsset,
        StationMapMarkerAssetKind.cheap => _cheapAsset,
      };

  /// Central mapping: closed wins; cheap only when open; unknown → open art.
  static StationMapMarkerAssetKind kindFor({
    required StationOpenTone tone,
    required int stationId,
    required int? cheapSpotlightStationId,
  }) {
    if (tone == StationOpenTone.closed) {
      return StationMapMarkerAssetKind.closed;
    }
    if (cheapSpotlightStationId == stationId && tone == StationOpenTone.open) {
      return StationMapMarkerAssetKind.cheap;
    }
    return StationMapMarkerAssetKind.open;
  }

  static String infoSnippet(StationMapItem item) {
    final a = StationOpenStatus.forMapItem(item);
    final status = a.primaryLabel;
    final a2 = item.shortAddress?.trim();
    if (a2 != null && a2.isNotEmpty) {
      final short = a2.length > 56 ? '${a2.substring(0, 53)}…' : a2;
      return '$short · $status';
    }
    return status;
  }

  static Future<void> preloadAll(double devicePixelRatio) async {
    final dpr = _markerDecodeDpr(devicePixelRatio);
    await Future.wait([
      for (final k in StationMapMarkerAssetKind.values) iconFor(kind: k, devicePixelRatio: dpr),
    ]);
  }

  static void invalidateCache() {
    _cache.clear();
    _inFlight.clear();
  }

  static Future<AppMapMarkerIcon> iconFor({
    required StationMapMarkerAssetKind kind,
    required double devicePixelRatio,
  }) async {
    final dpr = _markerDecodeDpr(devicePixelRatio);
    final path = _assetForKind(kind);
    final key = '$path@${dpr.toStringAsFixed(2)}';
    final hit = _cache[key];
    if (hit != null) return hit;
    final pending = _inFlight[key];
    if (pending != null) return pending;
    final future = _iconFromAssetPng(path: path, dpr: dpr, kind: kind).then((d) {
      _cache[key] = d;
      _inFlight.remove(key);
      return d;
    });
    _inFlight[key] = future;
    return future;
  }

  /// Load the asset directly (cheap path); nếu PNG hỏng/decode lỗi, fallback re-encode
  /// qua Flutter pipeline; cuối cùng default marker (hue) nếu không thể tạo bytes.
  static Future<AppMapMarkerIcon> _iconFromAssetPng({
    required String path,
    required double dpr,
    required StationMapMarkerAssetKind kind,
  }) async {
    final raw = await rootBundle.load(path);
    final rawBytes = raw.buffer.asUint8List();
    if (kDebugMode && rawBytes.length < 512) {
      debugPrint(
        'MapStationMarkerFactory: "$path" is only ${rawBytes.length} B — '
        'likely a solid placeholder. Replace with your marker PNG under '
        'assets/map_markers/ (see MapMarkerAssetPaths) then stop + run again (assets are baked at build).',
      );
    }

    // Cheap path: trỏ adapter về asset trực tiếp — Google `AssetMapBitmap` /
    // Goong `addImage(rootBundle.load(...))` đều handle được.
    if (rawBytes.length >= 512) {
      return AppMapMarkerIconAsset(
        assetPath: path,
        devicePixelRatio: dpr,
      );
    }

    try {
      final d = await _decodeAssetViaFlutterToBytes(
        rawBytes: rawBytes,
        dpr: dpr,
      );
      if (d != null) return d;
    } catch (_) {
      // Still unusable — drawn fallback below.
    }
    return _fallbackMarkerIcon(dpr: dpr, kind: kind);
  }

  /// Decode at intrinsic size, letterbox into the marker slot, export PNG.
  static Future<AppMapMarkerIcon?> _decodeAssetViaFlutterToBytes({
    required Uint8List rawBytes,
    required double dpr,
  }) async {
    final tw = (_logicalMarkerSize.width * dpr).round();
    final th = (_logicalMarkerSize.height * dpr).round();
    final codec = await ui.instantiateImageCodec(rawBytes);
    final frame = await codec.getNextFrame();
    final src = frame.image;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final srcW = src.width.toDouble();
    final srcH = src.height.toDouble();
    final dst = _containRect(
      srcW: srcW,
      srcH: srcH,
      boxW: tw.toDouble(),
      boxH: th.toDouble(),
    );
    final paint = Paint()..filterQuality = FilterQuality.medium;
    canvas.drawImageRect(
      src,
      Rect.fromLTWH(0, 0, srcW, srcH),
      dst,
      paint,
    );
    final picture = recorder.endRecording();
    final out = await picture.toImage(tw, th);
    picture.dispose();
    codec.dispose();
    src.dispose();
    final png = await out.toByteData(format: ui.ImageByteFormat.png);
    out.dispose();
    if (png == null || png.lengthInBytes == 0) return null;
    return AppMapMarkerIconBytes(
      pngBytes: png.buffer.asUint8List(),
      devicePixelRatio: dpr,
    );
  }

  static Rect _containRect({
    required double srcW,
    required double srcH,
    required double boxW,
    required double boxH,
  }) {
    if (srcW <= 0 || srcH <= 0) {
      return Rect.fromLTWH(0, 0, boxW, boxH);
    }
    final sx = boxW / srcW;
    final sy = boxH / srcH;
    final s = sx < sy ? sx : sy;
    final w = srcW * s;
    final h = srcH * s;
    return Rect.fromCenter(
      center: Offset(boxW / 2, boxH / 2),
      width: w,
      height: h,
    );
  }

  static Future<AppMapMarkerIcon> _fallbackMarkerIcon({
    required double dpr,
    required StationMapMarkerAssetKind kind,
  }) async {
    final tw = (_logicalMarkerSize.width * dpr).round();
    final th = (_logicalMarkerSize.height * dpr).round();
    final color = switch (kind) {
      StationMapMarkerAssetKind.open => const Color(0xFF2E7D32),
      StationMapMarkerAssetKind.closed => const Color(0xFF757575),
      StationMapMarkerAssetKind.cheap => const Color(0xFFFFB300),
    };
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = color;
    final cx = tw / 2;
    final headY = th * 0.32;
    final r = tw * 0.22;
    canvas.drawCircle(Offset(cx, headY), r, paint);
    final stem = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, th * 0.62),
        width: r * 0.55,
        height: th * 0.42,
      ),
      Radius.circular(r * 0.12),
    );
    canvas.drawRRect(stem, paint);
    final picture = recorder.endRecording();
    final image = await picture.toImage(tw, th);
    picture.dispose();
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final bytes = png?.buffer.asUint8List();
    if (bytes == null || bytes.isEmpty) {
      // Hue trên thang Google `BitmapDescriptor.defaultMarkerWithHue`:
      // red ≈ 0, yellow ≈ 60, green ≈ 120.
      final hue = switch (kind) {
        StationMapMarkerAssetKind.closed => 0.0,
        StationMapMarkerAssetKind.cheap => 60.0,
        StationMapMarkerAssetKind.open => 120.0,
      };
      return AppMapMarkerIconDefault(hue: hue);
    }
    return AppMapMarkerIconBytes(
      pngBytes: bytes,
      devicePixelRatio: dpr,
    );
  }

  static AppMapMarkerIcon? iconFromCache({
    required StationMapMarkerAssetKind kind,
    required double devicePixelRatio,
  }) {
    final dpr = _markerDecodeDpr(devicePixelRatio);
    final key = '${_assetForKind(kind)}@${dpr.toStringAsFixed(2)}';
    return _cache[key];
  }
}
