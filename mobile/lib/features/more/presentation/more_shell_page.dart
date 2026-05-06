import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../auth/presentation/login_page.dart';
import 'account/account_screen.dart';

/// Tab **Tài khoản** (bottom navigation).
///
/// Chưa đăng nhập: hiển thị [LoginPage] trong shell (đúng UX Citizen — không ép route `/login` toàn màn hình).
class MoreShellPage extends ConsumerWidget {
  const MoreShellPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authed = ref.watch(
      authSessionControllerProvider.select((c) => c.isAuthenticated),
    );
    if (!authed) {
      return const LoginPage();
    }
    return const AccountScreen();
  }
}
