import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/auth/auth_session.dart';
import '../../../../core/auth/biometric/biometric_providers.dart';
import '../../../../core/auth/portal_route_access.dart';
import '../../../../core/router/app_routes.dart';
import 'account_palette.dart';
import 'account_personal_info_page.dart';
import 'widgets/account_menu_item.dart';
import 'widgets/account_screen_skeleton.dart';
import 'account_activity_providers.dart';
import 'widgets/activity_summary_row.dart';
import 'widgets/menu_section.dart';
import 'widgets/app_version_footer.dart';
import 'widgets/profile_header_card.dart';
import 'widgets/request_delete_data_bottom_sheet.dart';

/// Tab **Tài khoản** — giao diện hồ sơ + menu; giữ nguyên điều hướng / đăng xuất như [MoreShellPage] trước đây.
///
/// [embeddedInLeaderShell]: khi `true` (Lãnh đạo `Loai == 6`), không dùng AppBar riêng; chỉ hồ sơ + Thông tin cá nhân + Bảo mật (đổi mật khẩu / đăng xuất).
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key, this.embeddedInLeaderShell = false});

  final bool embeddedInLeaderShell;

  static Future<void> _confirmDisableBiometric(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tắt đăng nhập sinh trắc học?'),
        content: const Text(
          'Bạn sẽ chỉ đăng nhập bằng mật khẩu trên thiết bị này. Bạn có thể bật lại sau khi đăng nhập thành công.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tắt')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(biometricCredentialStoreProvider).clearEnrollment();
    ref.invalidate(biometricLoginUiProvider);
    ref.invalidate(biometricEnrollmentActiveProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tắt đăng nhập sinh trắc học.')),
      );
    }
  }

  static void _openPersonal(BuildContext context, AuthSession session) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AccountPersonalInfoPage(session: session),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch chỉ `(isReady, session)` qua record-select — không rebuild cho
    // mọi `notifyListeners` lặt vặt khác của AuthSessionController.
    final (isReady, session) = ref.watch(
      authSessionControllerProvider.select((c) => (c.isReady, c.session)),
    );

    if (!isReady) {
      if (embeddedInLeaderShell) {
        return const ColoredBox(
          color: AccountPalette.background,
          child: AccountScreenSkeleton(),
        );
      }
      return Scaffold(
        backgroundColor: AccountPalette.background,
        appBar: AppBar(
          title: const Text('Tài khoản'),
          backgroundColor: AccountPalette.cardWhite,
          foregroundColor: AccountPalette.textPrimary,
          surfaceTintColor: Colors.transparent,
        ),
        body: const AccountScreenSkeleton(),
      );
    }

    final leaderAccount = embeddedInLeaderShell;

    final body = ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        if (session != null) ...[
          ProfileHeaderCard(
            session: session,
            onEditTap: () => _openPersonal(context, session),
          ),
          if (!leaderAccount) ...[
            const SizedBox(height: 20),
            Consumer(
              builder: (context, ref, _) {
                final summary = ref.watch(accountActivitySummaryProvider);
                return summary.when(
                  loading: () => const ActivitySummaryRow(
                    reviewsCount: null,
                    reportsCount: null,
                    fuelCount: null,
                  ),
                  error: (error, stackTrace) => const ActivitySummaryRow(
                    reviewsCount: null,
                    reportsCount: null,
                    fuelCount: null,
                  ),
                  data: (s) => ActivitySummaryRow(
                    reviewsCount: s.reviewsCount,
                    reportsCount: s.reportsCount,
                    fuelCount: s.fuelTransactionsCount,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
          if (leaderAccount) const SizedBox(height: 20),
          MenuSection(
            title: 'CÁ NHÂN',
            child: Column(
              children: [
                AccountMenuItem(
                  icon: Icons.badge_outlined,
                  label: 'Thông tin cá nhân',
                  onTap: () => _openPersonal(context, session),
                  showDividerBelow: !leaderAccount,
                ),
                if (!leaderAccount)
                  AccountMenuItem(
                    icon: Icons.history_rounded,
                    label: 'Lịch sử nhiên liệu',
                    onTap: () => context.go(AppRoute.fuel.path),
                    showDividerBelow: false,
                  ),
              ],
            ),
          ),
          if (!leaderAccount) ...[
            const SizedBox(height: 20),
            MenuSection(
              title: 'TƯƠNG TÁC',
              child: Column(
                children: [
                  AccountMenuItem(
                    icon: Icons.star_outline_rounded,
                    label: 'Đánh giá của tôi',
                    onTap: () => context.push(AppRoute.myStationReviews.path),
                  ),
                  AccountMenuItem(
                    icon: Icons.assignment_outlined,
                    label: 'Báo cáo của tôi',
                    onTap: () => context.push(AppRoute.myViolationReports.path),
                    showDividerBelow: false,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          MenuSection(
            title: 'QUYỀN RIÊNG TƯ & DỮ LIỆU',
            child: Column(
              children: [
                AccountMenuItem(
                  icon: Icons.delete_outline_rounded,
                  label: 'Xoá tài khoản',
                  onTap: () => showRequestDeleteDataSheet(context, ref),
                  danger: true,
                  showDividerBelow: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          MenuSection(
            title: leaderAccount ? 'THÔNG TIN BẢO MẬT' : 'BẢO MẬT',
            child: Column(
              children: [
                AccountMenuItem(
                  icon: Icons.lock_outline_rounded,
                  label: 'Đổi mật khẩu',
                  onTap: () => context.push(AppRoute.changePassword.path),
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final enrolled = ref.watch(biometricEnrollmentActiveProvider);
                    return enrolled.when(
                      data: (on) {
                        if (!on) return const SizedBox.shrink();
                        return AccountMenuItem(
                          icon: Icons.fingerprint_outlined,
                          label: 'Tắt đăng nhập sinh trắc học',
                          onTap: () => AccountScreen._confirmDisableBiometric(context, ref),
                          showDividerBelow: true,
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (err, st) => const SizedBox.shrink(),
                    );
                  },
                ),
                AccountMenuItem(
                  icon: Icons.logout_rounded,
                  label: 'Đăng xuất',
                  onTap: () => ref.read(authSessionControllerProvider).logout(),
                  danger: true,
                  showDividerBelow: false,
                ),
              ],
            ),
          ),
          if (!leaderAccount) ...[
            const SizedBox(height: 22),
            MenuSection(
              title: 'TRUY CẬP NHANH',
              child: Column(
                children: [
                  AccountMenuItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    onTap: () => context.go(AppRoute.reports.path),
                  ),
                  AccountMenuItem(
                    icon: Icons.map_outlined,
                    label: 'Bản đồ cây xăng',
                    onTap: () => context.go(AppRoute.map.path),
                  ),
                  AccountMenuItem(
                    icon: Icons.local_gas_station_outlined,
                    label: 'Nhiên liệu',
                    onTap: () => context.go(AppRoute.fuel.path),
                    showDividerBelow: PortalRouteAccess.canAccessInventoryStockMap(session.loai),
                  ),
                  if (PortalRouteAccess.canAccessInventoryStockMap(session.loai))
                    AccountMenuItem(
                      icon: Icons.layers_outlined,
                      label: 'Bản đồ tồn kho',
                      onTap: () => context.push(AppRoute.inventoryStockMap),
                      showDividerBelow: false,
                    ),
                ],
              ),
            ),
          ],
        ] else ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 8, 4, 16),
            child: Text(
              'Chưa đăng nhập.',
              style: TextStyle(fontWeight: FontWeight.w800, color: AccountPalette.textPrimary),
            ),
          ),
          if (!leaderAccount)
            MenuSection(
              title: 'TRUY CẬP NHANH',
              child: Column(
                children: [
                  AccountMenuItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    onTap: () => context.go(AppRoute.reports.path),
                  ),
                  AccountMenuItem(
                    icon: Icons.map_outlined,
                    label: 'Bản đồ cây xăng',
                    onTap: () => context.go(AppRoute.map.path),
                  ),
                  AccountMenuItem(
                    icon: Icons.local_gas_station_outlined,
                    label: 'Nhiên liệu',
                    onTap: () => context.go(AppRoute.fuel.path),
                    showDividerBelow: false,
                  ),
                ],
              ),
            ),
        ],
        if (session != null || !leaderAccount) ...[
          const SizedBox(height: 20),
          const AppVersionFooter(),
        ],
      ],
    );

    if (embeddedInLeaderShell) {
      return ColoredBox(
        color: AccountPalette.background,
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: AccountPalette.background,
      appBar: AppBar(
        title: const Text('Tài khoản'),
        backgroundColor: AccountPalette.cardWhite,
        foregroundColor: AccountPalette.textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      body: body,
    );
  }
}
