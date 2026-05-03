import 'package:flutter/material.dart';

import '../../../station_detail/presentation/station_detail_shell_theme.dart';

/// Bold station name + secondary address line.
class StationPreviewMiniCard extends StatelessWidget {
  const StationPreviewMiniCard({
    super.key,
    required this.stationName,
    required this.address,
  });

  final String stationName;
  final String address;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stationName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.2,
                color: StationDetailShellTheme.textPrimary,
                letterSpacing: -0.2,
              ),
        ),
        if (address.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: StationDetailShellTheme.textSecondary,
                  height: 1.35,
                ),
          ),
        ],
      ],
    );
  }
}
