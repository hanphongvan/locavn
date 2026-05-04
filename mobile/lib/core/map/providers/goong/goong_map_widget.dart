import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;

import '../../app_map_camera.dart';
import '../../app_map_marker.dart';
import '../../app_map_polyline.dart';
import '../../map_provider_adapter.dart';
import 'goong_anchor.dart';
import 'goong_map_controller.dart';
import 'goong_value_codec.dart';

class GoongMapWidget extends StatefulWidget {
  final String styleUrl;
  final AppMapCameraPosition initialCameraPosition;
  final Set<AppMapMarker> markers;
  final Set<AppMapPolyline> polylines;
  final EdgeInsets padding;
  final bool myLocationEnabled;
  final bool compassEnabled;
  final AppMapCreatedCallback? onMapCreated;
  final AppMapTapCallback? onTap;
  final AppMapCameraIdleCallback? onCameraIdle;

  const GoongMapWidget({
    super.key,
    required this.styleUrl,
    required this.initialCameraPosition,
    this.markers = const {},
    this.polylines = const {},
    this.padding = EdgeInsets.zero,
    this.myLocationEnabled = false,
    this.compassEnabled = true,
    this.onMapCreated,
    this.onTap,
    this.onCameraIdle,
  });

  @override
  State<GoongMapWidget> createState() => _GoongMapWidgetState();
}

class _GoongMapWidgetState extends State<GoongMapWidget> {
  ml.MapLibreMapController? _controller;
  bool _styleLoaded = false;
  final Map<AppMapMarkerId, ml.Symbol> _symbols = {};
  final Map<AppMapPolylineId, ml.Line> _lines = {};
  final Set<String> _registeredImages = {};
  int _applySerial = 0;

  @override
  void didUpdateWidget(GoongMapWidget old) {
    super.didUpdateWidget(old);
    final markersChanged = !setEquals(old.markers, widget.markers);
    final polylinesChanged = !setEquals(old.polylines, widget.polylines);
    if (markersChanged || polylinesChanged) {
      unawaited(_applyAll());
    }
  }

  void _onMapCreated(ml.MapLibreMapController c) {
    _controller = c;
    c.onSymbolTapped.add(_handleSymbolTap);
    widget.onMapCreated?.call(GoongAppMapController(c));
  }

  Future<void> _onStyleLoaded() async {
    _styleLoaded = true;
    await _applyAll();
  }

  /// Diff + apply markers & polylines. Yêu cầu controller + style loaded.
  /// Serial token để cancel khi widget update liên tục.
  Future<void> _applyAll() async {
    final c = _controller;
    if (c == null || !_styleLoaded) return;
    final serial = ++_applySerial;
    try {
      await _applyMarkers(c, serial);
      if (serial != _applySerial) return;
      await _applyPolylines(c, serial);
    } catch (e, st) {
      debugPrint('[GoongMap] applyAll error: $e\n$st');
    }
  }

  Future<void> _applyMarkers(ml.MapLibreMapController c, int serial) async {
    final desired = {for (final m in widget.markers) m.id: m};
    final toRemove = _symbols.keys.toSet().difference(desired.keys.toSet());
    final toAdd = desired.keys.toSet().difference(_symbols.keys.toSet());

    for (final id in toRemove) {
      if (serial != _applySerial) return;
      final s = _symbols.remove(id);
      if (s != null) {
        try {
          await c.removeSymbol(s);
        } catch (_) {/* layer/symbol có thể đã bị remove khi style reload */}
      }
    }
    for (final id in toAdd) {
      if (serial != _applySerial) return;
      final m = desired[id]!;
      final iconName = await _ensureIcon(c, m.icon);
      if (serial != _applySerial) return;
      final symbol = await c.addSymbol(
        ml.SymbolOptions(
          geometry: GoongValueCodec.toLatLng(m.position),
          iconImage: iconName,
          iconSize: 1.0,
          iconAnchor: goongIconAnchor(m.anchor),
        ),
      );
      _symbols[id] = symbol;
    }
  }

  Future<void> _applyPolylines(
    ml.MapLibreMapController c,
    int serial,
  ) async {
    final desired = {for (final p in widget.polylines) p.id: p};
    final toRemove = _lines.keys.toSet().difference(desired.keys.toSet());
    final toAdd = desired.keys.toSet().difference(_lines.keys.toSet());

    for (final id in toRemove) {
      if (serial != _applySerial) return;
      final l = _lines.remove(id);
      if (l != null) {
        try {
          await c.removeLine(l);
        } catch (_) {}
      }
    }
    for (final id in toAdd) {
      if (serial != _applySerial) return;
      final p = desired[id]!;
      final line = await c.addLine(
        ml.LineOptions(
          geometry: p.points.map(GoongValueCodec.toLatLng).toList(),
          lineColor: _hexFromColor(p.color),
          lineWidth: p.width,
          lineOpacity: p.color.a,
        ),
      );
      _lines[id] = line;
    }
  }

  Future<String> _ensureIcon(
    ml.MapLibreMapController c,
    AppMapMarkerIcon icon,
  ) async {
    switch (icon) {
      case AppMapMarkerIconDefault():
        return _ensureDefaultMarker(c, icon.hue);
      case AppMapMarkerIconAsset():
        final name = 'asset__${icon.assetPath}';
        if (_registeredImages.add(name)) {
          final bytes = await rootBundle.load(icon.assetPath);
          await c.addImage(name, bytes.buffer.asUint8List());
        }
        return name;
      case AppMapMarkerIconBytes():
        // Caller phải reuse cùng AppMapMarkerIconBytes instance để cache hit;
        // bytes mới mỗi rebuild → register lại (tốn nhưng đúng).
        final name = 'bytes__${identityHashCode(icon.pngBytes)}';
        if (_registeredImages.add(name)) {
          await c.addImage(name, icon.pngBytes);
        }
        return name;
    }
  }

  Future<String> _ensureDefaultMarker(
    ml.MapLibreMapController c,
    double hue,
  ) async {
    final hueKey = hue.round();
    final name = 'default__hue_$hueKey';
    if (_registeredImages.add(name)) {
      final bytes = await _generatePin(hue);
      await c.addImage(name, bytes);
    }
    return name;
  }

  /// Pin PNG đơn giản 32×40 — provider không có default marker SDK như Google.
  Future<Uint8List> _generatePin(double hue) async {
    const size = 32.0;
    const height = 40.0;
    final color = HSVColor.fromAHSV(1, hue.clamp(0, 360).toDouble(), 0.85, 0.95)
        .toColor();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final body = Paint()..color = color;
    final outline = Paint()
      ..color = const Color(0xFF222222)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..moveTo(size / 2, height)
      ..quadraticBezierTo(0, size * 0.65, size / 2, 0)
      ..quadraticBezierTo(size, size * 0.65, size / 2, height)
      ..close();
    canvas.drawPath(path, body);
    canvas.drawPath(path, outline);
    canvas.drawCircle(Offset(size / 2, size * 0.42), size * 0.18,
        Paint()..color = const Color(0xFFFFFFFF));

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.round(), height.round());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _handleSymbolTap(ml.Symbol symbol) {
    for (final entry in _symbols.entries) {
      if (entry.value.id == symbol.id) {
        for (final m in widget.markers) {
          if (m.id == entry.key) {
            m.onTap?.call();
            return;
          }
        }
        return;
      }
    }
  }

  void _onMapClick(math.Point<double> point, ml.LatLng coords) {
    widget.onTap?.call(GoongValueCodec.fromLatLng(coords));
  }

  static String _hexFromColor(Color c) {
    int channel(double v) => (v.clamp(0, 1) * 255).round();
    return '#${channel(c.r).toRadixString(16).padLeft(2, '0')}'
        '${channel(c.g).toRadixString(16).padLeft(2, '0')}'
        '${channel(c.b).toRadixString(16).padLeft(2, '0')}';
  }

  @override
  void dispose() {
    final c = _controller;
    if (c != null) {
      c.onSymbolTapped.remove(_handleSymbolTap);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ml.MapLibreMap(
      styleString: widget.styleUrl,
      initialCameraPosition:
          GoongValueCodec.toCameraPosition(widget.initialCameraPosition),
      onMapCreated: _onMapCreated,
      onStyleLoadedCallback: _onStyleLoaded,
      onMapClick: widget.onTap == null ? null : _onMapClick,
      onCameraIdle: widget.onCameraIdle,
      myLocationEnabled: widget.myLocationEnabled,
      myLocationTrackingMode: widget.myLocationEnabled
          ? ml.MyLocationTrackingMode.tracking
          : ml.MyLocationTrackingMode.none,
      compassEnabled: widget.compassEnabled,
      attributionButtonPosition: ml.AttributionButtonPosition.bottomRight,
    );
  }
}
