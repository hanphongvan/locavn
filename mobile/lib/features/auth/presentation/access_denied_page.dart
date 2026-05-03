import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/router/role_home_navigation.dart';

/// Hai trạng thái:
/// - `?reason=forbidden` → RBAC chặn quyền truy cập (vd citizen mở `/leader/...`).
///   Hiện thông báo thân thiện + nút **Về trang chủ** (theo `Loai` của session).
/// - Không có query → `Loai` không được app hỗ trợ. Hiện hướng dẫn + nút **Đăng nhập lại**.
class AccessDeniedPage extends ConsumerWidget {
  const AccessDeniedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final reason = GoRouterState.of(context).uri.queryParameters['reason'];
    final loai = ref.watch(
      authSessionControllerProvider.select((c) => c.session?.loai),
    );
    final isForbidden = reason == 'forbidden';

    final title = isForbidden ? 'Không có quyền truy cập' : 'Tài khoản không hợp lệ';
    final body = isForbidden
        ? 'Bạn không có quyền truy cập chức năng này.'
        : 'Tài khoản không được hỗ trợ trên ứng dụng này. Liên hệ quản trị nếu bạn cần quyền truy cập.';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.lock_person_outlined, size: 64, color: scheme.primary),
              const SizedBox(height: 20),
              Text(
                body,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  if (isForbidden) {
                    final home = roleHomeLocationForLoai(loai);
                    if (home != null && context.mounted) {
                      context.go(home);
                    }
                  } else {
                    ref.read(authSessionControllerProvider).logout();
                  }
                },
                child: Text(isForbidden ? 'Về trang chủ' : 'Quay lại đăng nhập'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
