import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/portal_loai.dart';
import '../../../core/auth/role_service.dart';
import '../../map/presentation/map_screen_palette.dart';
import '../../reports/presentation/dashboard/loca_dashboard_tokens.dart';
import 'leader_executive_app_bar.dart';
import 'leader_floating_bottom_nav.dart';
import 'stabilization_fund_filter_bus.dart';

/// Nền [Scaffold] (khe quanh thẻ AppBar + vùng dưới) theo tab — AppBar vẫn gradient navy.
Color _leaderShellCanvasColor(int index) {
  return switch (index) {
    1 => MapScreenPalette.screenBackground,
    0 || 2 => LocaDashboardTokens.gradientTop,
    _ => LocaDashboardTokens.background,
  };
}

/// Index nhánh **Bản đồ** trong [StatefulNavigationShell] (không dùng [LeaderExecutiveAppBar]).
const int kLeaderMapShellBranchIndex = 1;

/// **LeaderMainScreen** — màn chính lãnh đạo khi `user.Loai == 6` ([PortalLoai.leader]).
///
/// Tabs: **Tổng quan**, **Bản đồ**, **Phân tích**, **Quỹ bình ổn**, **Tài khoản**.
class LeaderMainScreen extends ConsumerWidget {
  const LeaderMainScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `.select` để chỉ rebuild khi `loai` đổi (gần như chỉ login/logout),
    // không phải mọi `notifyListeners` của AuthSessionController.
    final loai = ref.watch(
      authSessionControllerProvider.select((c) => c.session?.loai),
    );
    if (!RoleService.isLeaderUser(loai)) {
      return Scaffold(
        backgroundColor: LocaDashboardTokens.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Chỉ tài khoản lãnh đạo (Loai = ${PortalLoai.leader}) được phép dùng giao diện này.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: LocaDashboardTokens.textPrimary,
              ),
            ),
          ),
        ),
      );
    }

    final idx = navigationShell.currentIndex;
    final canvas = _leaderShellCanvasColor(idx);

    final showExecutiveHeader = idx != kLeaderMapShellBranchIndex;

    return Scaffold(
      extendBody: true,
      backgroundColor: canvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showExecutiveHeader)
            LeaderExecutiveAppBar(
              filterAction: idx == 3
                  ? () => ref.read(stabilizationFundFilterBusProvider).open()
                  : null,
            ),
          Expanded(
            child: showExecutiveHeader
                ? MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: navigationShell,
                  )
                : navigationShell,
          ),
        ],
      ),
      bottomNavigationBar: LeaderFloatingBottomNav(
        currentIndex: idx,
        onDestinationSelected: (i) {
          navigationShell.goBranch(
            i,
            initialLocation: i == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
