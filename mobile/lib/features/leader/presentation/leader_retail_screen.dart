import 'package:flutter/material.dart';

import '../../reports/presentation/dashboard/loca_dashboard_tokens.dart';

/// Tab **Bán lẻ** (`Loai == 6`) — KPI cửa hàng + bảng xếp hạng theo tỉnh.
///
/// Phase 1: placeholder rỗng để gắn vào `StatefulShellRoute`. UI thật ráp ở Phần 4.
class LeaderRetailScreen extends StatelessWidget {
  const LeaderRetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: LocaDashboardTokens.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Bán lẻ — đang xây dựng',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: LocaDashboardTokens.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }}
