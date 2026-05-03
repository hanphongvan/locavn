import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/portal_session_scope.dart';
import '../../../core/router/app_routes.dart';
import '../data/store_sale_prices_role_guard.dart';
import 'store_sale_prices_hub_page.dart';

/// Full-screen **Nhập giá bán** — Store (`Loai == 4`) only; others see an inline access message.
class StoreSalePricesShellPage extends ConsumerWidget {
  const StoreSalePricesShellPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scope = ref.watch(portalSessionScopeProvider);
    final allowed = StoreSalePricesRoleGuard.canUseStoreSalePricesDataLayer(scope);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Quay lại',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoute.storeMap);
            }
          },
        ),
        title: Text(
          'Nhập giá bán',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.92),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: allowed
          ? const StoreSalePricesHubPage()
          : _AccessDeniedBody(scope: scope),
    );
  }
}

class _AccessDeniedBody extends StatelessWidget {
  const _AccessDeniedBody({required this.scope});

  final PortalSessionScope? scope;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'Không có quyền truy cập',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tính năng nhập giá bán chỉ dành cho tài khoản cửa hàng (Loai = 4) có DonViId.\n'
              'Tài khoản hiện tại: ${scope?.userName ?? '—'} · Loai: ${scope?.loai?.toString() ?? '—'}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
