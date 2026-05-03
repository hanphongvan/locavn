import 'package:flutter/material.dart';

import 'leader_map_inventory_page.dart';

/// Bản đồ tab **Lãnh đạo** — tồn kho xăng/dầu (không dùng [MapShellPage] / bộ lọc người dùng chung).
class LeaderMapShell extends StatelessWidget {
  const LeaderMapShell({super.key});

  @override
  Widget build(BuildContext context) => const LeaderMapInventoryPage();
}
