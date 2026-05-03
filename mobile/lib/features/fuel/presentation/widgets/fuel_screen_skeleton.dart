import 'package:flutter/material.dart';

import '../fuel_palette.dart';

/// Giữ layout màn Nhiên liệu khi đang tải API (không dùng dữ liệu giả).
class FuelScreenSkeleton extends StatelessWidget {
  const FuelScreenSkeleton({super.key, required this.bottomInset});

  final double bottomInset;

  static const _r = 18.0;

  Widget _shimmerBlock({double height = 88, double? width}) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: FuelPalette.border.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(_r),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [
        _shimmerBlock(height: 96),
        const SizedBox(height: 18),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, _) => SizedBox(width: 168, child: _shimmerBlock(height: 168)),
          ),
        ),
        const SizedBox(height: 18),
        _shimmerBlock(height: 200),
        const SizedBox(height: 18),
        _shimmerBlock(height: 220),
        SizedBox(height: 88 + bottomInset),
      ],
    );
  }
}
