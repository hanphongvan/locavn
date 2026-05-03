import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../presentation/leader_theme.dart';

/// Nhóm màu theo ngưỡng ngày (đồng bộ với [LeaderTheme.daysCoverageColor]).
enum LeaderStockBandKind {
  safe,
  warn,
  risk,
}

LeaderStockBandKind leaderBandKindFromDays(double days) {
  if (days < 5) return LeaderStockBandKind.risk;
  if (days <= 10) return LeaderStockBandKind.warn;
  return LeaderStockBandKind.safe;
}

Color leaderBandColor(LeaderStockBandKind k) {
  return switch (k) {
    LeaderStockBandKind.risk => LeaderTheme.alert,
    LeaderStockBandKind.warn => LeaderTheme.coverageWarn,
    LeaderStockBandKind.safe => LeaderTheme.coverageOk,
  };
}

final Map<String, BitmapDescriptor> _haloCache = {};
final Map<String, BitmapDescriptor> _clusterCache = {};

double _dprKey(double raw) {
  if (raw.isNaN || raw <= 0) return 2.5;
  return raw.clamp(2.0, 3.0);
}

/// Vòng mờ phía sau marker cửa hàng (3 biến thể cache theo DPR).
Future<BitmapDescriptor> leaderStockHaloDescriptor(double devicePixelRatio, LeaderStockBandKind band) async {
  final dpr = _dprKey(devicePixelRatio);
  final key = 'halo_${band.name}_${dpr.toStringAsFixed(2)}';
  final hit = _haloCache[key];
  if (hit != null) return hit;
  final c = leaderBandColor(band);
  final logical = 36.0;
  final size = (logical * dpr).round();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()..isAntiAlias = true;
  final center = Offset(size / 2, size / 2);
  final radius = size / 2 - 1;
  paint.color = c.withValues(alpha: 0.38);
  canvas.drawCircle(center, radius, paint);
  paint.style = PaintingStyle.stroke;
  paint.strokeWidth = dpr;
  paint.color = c.withValues(alpha: 0.55);
  canvas.drawCircle(center, radius - dpr, paint);
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final descriptor = BitmapDescriptor.bytes(
    bytes!.buffer.asUint8List(),
    width: logical,
    height: logical,
    bitmapScaling: MapBitmapScaling.auto,
  );
  _haloCache[key] = descriptor;
  return descriptor;
}

/// Marker cluster: số lượng điểm.
Future<BitmapDescriptor> leaderClusterCountDescriptor(int count, double devicePixelRatio) async {
  final dpr = _dprKey(devicePixelRatio);
  final key = 'clu_${count}_${dpr.toStringAsFixed(2)}';
  final hit = _clusterCache[key];
  if (hit != null) return hit;
  const logical = 48.0;
  final size = (logical * dpr).round();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final center = Offset(size / 2, size / 2);
  final radius = size / 2 - 2 * dpr;
  final paint = Paint()..isAntiAlias = true;
  paint.color = LeaderTheme.navy.withValues(alpha: 0.92);
  canvas.drawCircle(center, radius, paint);
  final label = count > 99 ? '99+' : '$count';
  final tp = TextPainter(
    text: TextSpan(
      text: label,
      style: TextStyle(color: Colors.white, fontSize: 13 * dpr, fontWeight: FontWeight.w800),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final descriptor = BitmapDescriptor.bytes(
    bytes!.buffer.asUint8List(),
    width: logical,
    height: logical,
    bitmapScaling: MapBitmapScaling.auto,
  );
  _clusterCache[key] = descriptor;
  return descriptor;
}
