import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/portal_loai.dart';
import '../../../core/auth/role_service.dart';
import '../../../core/router/app_routes.dart';
import '../../map/presentation/map_screen_palette.dart';
import '../../more/presentation/account/account_screen.dart';
import '../../reports/presentation/dashboard/loca_dashboard_tokens.dart';
import 'leader_executive_app_bar.dart';
import 'leader_floating_bottom_nav.dart';
import 'stabilization_fund_filter_bus.dart';

/// Nền [Scaffold] (khe quanh thẻ AppBar + vùng dưới) theo tab — AppBar vẫn gradient navy.
///
/// Index sau Phần 2: 0=Tổng quan, 1=Bản đồ, 2=Bán lẻ, 3=Phân tích, 4=Quỹ bình ổn.
Color _leaderShellCanvasColor(int index) {
  return switch (index) {
    1 => MapScreenPalette.screenBackground,
    0 || 3 => LocaDashboardTokens.gradientTop,
    _ => LocaDashboardTokens.background,
  };
}

/// Index nhánh **Bản đồ** trong [StatefulNavigationShell] (không dùng [LeaderExecutiveAppBar]).
const int kLeaderMapShellBranchIndex = 1;

/// Index nhánh **Quỹ bình ổn** — tab có nút lọc tháng/năm trên AppBar.
const int kLeaderStabilizationFundBranchIndex = 4;

/// **LeaderMainScreen** — màn chính lãnh đạo khi `user.Loai == 6` ([PortalLoai.leader]).
///
/// Tabs: **Tổng quan**, **Bản đồ**, **Bán lẻ**, **Phân tích**, **Quỹ bình ổn**.
/// Tài khoản đã rời bottom nav — mở qua icon trên AppBar (`/leader/account`).
class LeaderMainScreen extends ConsumerWidget {
  const LeaderMainScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Mở Account screen bằng Navigator imperative (root navigator), KHÔNG qua go_router.
  ///
  /// Lý do: nếu push qua go_router (`context.push('/leader/account')`), shell `LeaderMainScreen`
  /// vẫn được preserve dưới đáy stack. Khi logout, redirect kéo cả 2 (account + shell) → mount
  /// Citizen shell mới trong cùng frame → duplicate `GlobalKey<StatefulNavigationShellState>`
  /// và assertion `_lifecycleState == inactive`. Push raw MaterialPageRoute trên root navigator
  /// tách AccountScreen khỏi go_router state machinery; root nav tự pop khi router refresh.
  void _openAccount(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const AccountScreen(embeddedInLeaderShell: true),
      ),
    );
  }

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
              filterAction: idx == kLeaderStabilizationFundBranchIndex
                  ? () => ref.read(stabilizationFundFilterBusProvider).open()
                  : null,
              accountAction: () => _openAccount(context),
              aiAction: () => context.push(AppRoute.leaderAiChat),
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
