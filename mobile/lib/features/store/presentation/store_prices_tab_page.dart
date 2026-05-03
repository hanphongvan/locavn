import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/widgets/login_screen_theme.dart';
import '../../../core/auth/auth_providers.dart';
import '../../store_sale_prices/data/store_sale_prices_role_guard.dart';
import '../../store_sale_prices/presentation/store_sale_prices_hub_page.dart';

/// Tab **Giá bán** trong shell cửa hàng — không có nút quay về `/more`.
class StorePricesTabPage extends ConsumerWidget {
  const StorePricesTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scope = ref.watch(portalSessionScopeProvider);
    final allowed = StoreSalePricesRoleGuard.canUseStoreSalePricesDataLayer(scope);

    return Scaffold(
      backgroundColor: LoginScreenTheme.bgTop,
      appBar: AppBar(
        titleSpacing: 18,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Giá bán',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: LoginScreenTheme.titleBlue,
              ),
            ),
            Text(
              'Quản lý bảng giá xăng dầu',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.94),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.06),
      ),
      body: allowed
          ? const StoreSalePricesHubPage()
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Không thể tải nhập giá bán (thiếu DonViId hoặc không đủ quyền).',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
    );
  }
}
