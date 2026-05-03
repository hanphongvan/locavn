import 'package:flutter/material.dart';

import '../../../station_detail/presentation/station_detail_shell_theme.dart';
import 'station_map_preview_strings.dart';

/// Bốn thao tác cùng một hàng: chi tiết, chỉ đường, đánh giá, báo vi phạm.
class StationPreviewActionRow extends StatelessWidget {
  const StationPreviewActionRow({
    super.key,
    required this.onDetail,
    required this.onDirections,
    required this.onRate,
    required this.onReport,
  });

  final VoidCallback onDetail;
  final VoidCallback onDirections;
  final VoidCallback onRate;
  final VoidCallback onReport;

  static const Color _reportColor = Color(0xFFB91C1C);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniAction(
            icon: Icons.arrow_forward_rounded,
            label: StationMapPreviewStrings.actionDetail,
            onTap: onDetail,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _MiniAction(
            icon: Icons.navigation_rounded,
            label: StationMapPreviewStrings.actionDirections,
            onTap: onDirections,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _MiniAction(
            icon: Icons.star_rounded,
            label: StationMapPreviewStrings.actionRate,
            onTap: onRate,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _MiniAction(
            icon: Icons.outlined_flag_rounded,
            label: StationMapPreviewStrings.actionReport,
            onTap: onReport,
            iconColor: _reportColor,
            labelColor: _reportColor,
          ),
        ),
      ],
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final defaultMain = StationDetailShellTheme.textPrimary;
    return Material(
      color: StationDetailShellTheme.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: iconColor ?? StationDetailShellTheme.primary,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: labelColor ?? defaultMain,
                      fontSize: 10.5,
                      height: 1.15,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
