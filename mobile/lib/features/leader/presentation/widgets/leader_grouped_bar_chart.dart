import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Biểu đồ cột nhóm Nhập / Xuất theo từng nhãn thời gian (đọc trên mobile).
class LeaderGroupedBarChart extends StatelessWidget {
  const LeaderGroupedBarChart({
    super.key,
    required this.labels,
    required this.nhap,
    required this.xuat,
    required this.height,
    this.nhapColor = const Color(0xFF1565C0),
    this.xuatColor = const Color(0xFFE65100),
  });

  final List<String> labels;
  final List<double> nhap;
  final List<double> xuat;
  final double height;
  final Color nhapColor;
  final Color xuatColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _GroupedBarPainter(
          labels: labels,
          nhap: nhap,
          xuat: xuat,
          nhapColor: nhapColor,
          xuatColor: xuatColor,
        ),
      ),
    );
  }
}

class _GroupedBarPainter extends CustomPainter {
  _GroupedBarPainter({
    required this.labels,
    required this.nhap,
    required this.xuat,
    required this.nhapColor,
    required this.xuatColor,
  });

  final List<String> labels;
  final List<double> nhap;
  final List<double> xuat;
  final Color nhapColor;
  final Color xuatColor;

  @override
  void paint(Canvas canvas, Size size) {
    final n = math.min(labels.length, math.min(nhap.length, xuat.length));
    if (n == 0) return;

    const bottomPad = 28.0;
    const topPad = 8.0;
    final chartH = size.height - bottomPad - topPad;
    if (chartH <= 0) return;

    var maxV = 1.0;
    for (var i = 0; i < n; i++) {
      maxV = math.max(maxV, math.max(nhap[i], xuat[i]));
    }

    final groupW = size.width / n;
    final barW = (groupW * 0.32).clamp(4.0, 22.0);
    final gap = groupW * 0.08;

    final grid = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    for (var g = 0; g <= 3; g++) {
      final y = topPad + chartH * (g / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final tp = TextPainter(
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    );

    for (var i = 0; i < n; i++) {
      final cx = groupW * (i + 0.5);
      final nh = chartH * (nhap[i] / maxV);
      final xh = chartH * (xuat[i] / maxV);
      final y0 = topPad + chartH;

      final rN = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - barW / 2 - gap / 2, y0 - nh / 2), width: barW, height: nh),
        const Radius.circular(6),
      );
      final rX = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + barW / 2 + gap / 2, y0 - xh / 2), width: barW, height: xh),
        const Radius.circular(6),
      );
      canvas.drawRRect(rN, Paint()..color = nhapColor);
      canvas.drawRRect(rX, Paint()..color = xuatColor);

      tp.text = TextSpan(
        text: labels[i],
        style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
      );
      tp.layout(maxWidth: groupW - 2);
      tp.paint(canvas, Offset(cx - tp.width / 2, y0 + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _GroupedBarPainter oldDelegate) =>
      oldDelegate.labels != labels ||
      oldDelegate.nhap != nhap ||
      oldDelegate.xuat != xuat;
}
