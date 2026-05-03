import 'package:flutter/material.dart';

import '../../../station_detail/presentation/station_reviews_section.dart';
import '../../../station_detail/presentation/station_detail_shell_theme.dart';

/// Khi kéo sheet: chỉ **Nhận xét** (cùng UI màn chi tiết). Nút *Báo vi phạm* nằm cùng hàng 4 thao tác ở [StationPreviewActionRow].
class StationPreviewExpandedBlock extends StatelessWidget {
  const StationPreviewExpandedBlock({
    super.key,
    required this.stationId,
    required this.stationName,
    required this.stationAddress,
  });

  final int stationId;
  final String stationName;
  final String? stationAddress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(height: 1, color: StationDetailShellTheme.textSecondary.withValues(alpha: 0.15)),
        const SizedBox(height: 14),
        StationReviewsSection(
          stationId: stationId,
          stationName: stationName,
          stationAddress: stationAddress,
          listOnly: true,
        ),
      ],
    );
  }
}
