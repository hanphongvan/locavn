import 'package:flutter/material.dart';

import 'map_screen_palette.dart';

/// Một khối lọc: tiêu đề đậm + nội dung (chip, slider…).
class FilterSection extends StatelessWidget {
  const FilterSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: MapScreenPalette.filterTextPrimary,
        );
    final subStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: MapScreenPalette.filterTextSecondary,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: titleStyle),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: subStyle),
        ],
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}
