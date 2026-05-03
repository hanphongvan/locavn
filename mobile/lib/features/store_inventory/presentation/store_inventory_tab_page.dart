import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/portal_loai.dart';
import '../../auth/presentation/widgets/login_screen_theme.dart';
import '../../store_sale_prices/data/store_sale_prices_role_guard.dart';
import 'inventory_list_screen.dart';

/// Tab **Tồn kho** — chỉ [PortalLoai.store] (`Loai == 4`) + `donViId`.
class StoreInventoryTabPage extends ConsumerWidget {
  const StoreInventoryTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scope = ref.watch(portalSessionScopeProvider);
    final allowed = scope?.loai == PortalLoai.store &&
        StoreSalePricesRoleGuard.canUseStoreSalePricesDataLayer(scope);

    return Scaffold(
      backgroundColor: LoginScreenTheme.bgTop,
      appBar: AppBar(
        titleSpacing: 18,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tồn kho',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: LoginScreenTheme.titleBlue,
              ),
            ),
            Text(
              'Quản lý nhập – xuất hàng hóa',
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
          ? const InventoryListScreen()
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Chỉ tài khoản cửa hàng (Loai = 4) có DonViId mới xem được tồn kho.',
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
