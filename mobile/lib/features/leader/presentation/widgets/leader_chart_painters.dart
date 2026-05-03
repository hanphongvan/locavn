import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Biểu đồ đường 1–3 chuỗi trên cùng hệ trục (giá trị min–max tự scale).
class LeaderMultiLineChart extends StatelessWidget {
  const LeaderMultiLineChart({
    super.key,
    required this.series,
    required this.height,
    this.padding = const EdgeInsets.fromLTRB(4, 8, 12, 22),
  });

  final List<LeaderLineSeries> series;
  final double height;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _MultiLinePainter(series: series, padding: padding),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class LeaderLineSeries {
  const LeaderLineSeries({
    required this.values,
    required this.color,
    required this.label,
  });

  final List<double> values;
  final Color color;
  final String label;
}

class _MultiLinePainter extends CustomPainter {
  _MultiLinePainter({required this.series, required this.padding});

  final List<LeaderLineSeries> series;
  final EdgeInsets padding;

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) return;
    final n = series.map((s) => s.values.length).fold<int>(0, math.max);
    if (n < 1) return;
    double valAt(LeaderLineSeries s, int i) {
      if (s.values.isEmpty) return 0;
      final idx = i.clamp(0, s.values.length - 1);
      return s.values[idx];
    }

    final rect = Rect.fromLTWH(
      padding.left,
      padding.top,
      size.width - padding.horizontal,
      size.height - padding.vertical,
    );
    if (rect.width <= 0 || rect.height <= 0) return;

    var minV = double.infinity;
    var maxV = -double.infinity;
    for (var i = 0; i < n; i++) {
      for (final s in series) {
        final v = valAt(s, i);
        minV = math.min(minV, v);
        maxV = math.max(maxV, v);
      }
    }
    if (minV == maxV) {
      minV -= 1;
      maxV += 1;
    }
    final span = maxV - minV;

    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = rect.top + rect.height * (i / 3);
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), gridPaint);
    }

    double xFor(int i) {
      if (n <= 1) return rect.left + rect.width / 2;
      return rect.left + rect.width * (i / (n - 1));
    }

    for (final s in series) {
      if (s.values.isEmpty) continue;
      if (n == 1) {
        final t = (valAt(s, 0) - minV) / span;
        final y = rect.bottom - rect.height * t;
        final x = xFor(0);
        canvas.drawCircle(Offset(x, y), 5, Paint()..color = s.color);
        canvas.drawCircle(
          Offset(x, y),
          5,
          Paint()
            ..color = s.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        continue;
      }
      final path = Path();
      for (var i = 0; i < n; i++) {
        final t = (valAt(s, i) - minV) / span;
        final y = rect.bottom - rect.height * t;
        final x = xFor(i);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      final paint = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true;
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MultiLinePainter oldDelegate) =>
      oldDelegate.series != series || oldDelegate.padding != padding;
}

/// Hai cột nhập / xuất (một nhóm).
class LeaderNhapXuatBarChart extends StatelessWidget {
  const LeaderNhapXuatBarChart({
    super.key,
    required this.nhap,
    required this.xuat,
    required this.height,
    this.nhapColor = const Color(0xFF1565C0),
    this.xuatColor = const Color(0xFFE65100),
  });

  final double nhap;
  final double xuat;
  final double height;
  final Color nhapColor;
  final Color xuatColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _TwinBarPainter(
          nhap: nhap,
          xuat: xuat,
          nhapColor: nhapColor,
          xuatColor: xuatColor,
        ),
      ),
    );
  }
}

class _TwinBarPainter extends CustomPainter {
  _TwinBarPainter({
    required this.nhap,
    required this.xuat,
    required this.nhapColor,
    required this.xuatColor,
  });

  final double nhap;
  final double xuat;
  final Color nhapColor;
  final Color xuatColor;

  @override
  void paint(Canvas canvas, Size size) {
    final maxV = math.max(math.max(nhap, xuat), 1.0);
    const pad = 24.0;
    const gap = 20.0;
    final barW = (size.width - pad * 2 - gap) / 2;
    final hMax = size.height - 36;
    final nh = hMax * (nhap / maxV);
    final xh = hMax * (xuat / maxV);
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(pad, size.height - 28 - nh, barW, nh),
      const Radius.circular(10),
    );
    final r2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(pad + barW + gap, size.height - 28 - xh, barW, xh),
      const Radius.circular(10),
    );
    final p1 = Paint()..color = nhapColor;
    final p2 = Paint()..color = xuatColor;
    canvas.drawRRect(r, p1);
    canvas.drawRRect(r2, p2);
  }

  @override
  bool shouldRepaint(covariant _TwinBarPainter oldDelegate) =>
      nhap != oldDelegate.nhap || xuat != oldDelegate.xuat;
}
