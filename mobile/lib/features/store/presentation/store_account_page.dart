import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/router/app_routes.dart';
import '../../more/presentation/account/account_palette.dart';
import '../../more/presentation/account/account_personal_info_page.dart';
import '../../more/presentation/account/widgets/account_menu_item.dart';
import '../../more/presentation/account/widgets/profile_header_card.dart';
import '../../more/presentation/account/widgets/app_version_footer.dart';
import '../../more/presentation/account/widgets/menu_section.dart';
import '../../more/presentation/account/widgets/request_delete_data_bottom_sheet.dart';

/// Tab **Tài khoản** cho cửa hàng — tách biệt menu người dân (không có Nhiên liệu / Dashboard tiêu dùng).
class StoreAccountPage extends ConsumerWidget {
  const StoreAccountPage({super.key});

  static void _openPersonal(BuildContext context, AuthSession session) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AccountPersonalInfoPage(session: session),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Chỉ rebuild khi reference của `session` đổi (login/logout/restore).
    final session = ref.watch(
      authSessionControllerProvider.select((c) => c.session),
    );

    return Scaffold(
      backgroundColor: AccountPalette.background,
      appBar: AppBar(
        title: const Text('Tài khoản'),
        backgroundColor: AccountPalette.cardWhite,
        foregroundColor: AccountPalette.textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      body: session == null
          ? const Center(child: Text('Chưa đăng nhập.'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                ProfileHeaderCard(
                  session: session,
                  onEditTap: () => _openPersonal(context, session),
                ),
                const SizedBox(height: 24),
                MenuSection(
                  title: 'CÁ NHÂN',
                  child: Column(
                    children: [
                      AccountMenuItem(
                        icon: Icons.badge_outlined,
                        label: 'Thông tin cá nhân',
                        onTap: () => _openPersonal(context, session),
                        showDividerBelow: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                MenuSection(
                  title: 'QUYỀN RIÊNG TƯ & DỮ LIỆU',
                  child: Column(
                    children: [
                      AccountMenuItem(
                        icon: Icons.delete_outline_rounded,
                        label: 'Yêu cầu xoá dữ liệu',
                        onTap: () => showRequestDeleteDataSheet(context, ref),
                        showDividerBelow: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                MenuSection(
                  title: 'BẢO MẬT',
                  child: Column(
                    children: [
                      AccountMenuItem(
                        icon: Icons.lock_outline_rounded,
                        label: 'Đổi mật khẩu',
                        onTap: () => context.push(AppRoute.changePassword.path),
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
                const SizedBox(height: 20),
                const AppVersionFooter(),
              ],
            ),
    );
  }
}
