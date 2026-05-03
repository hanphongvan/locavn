import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/auth/portal_route_access.dart';
import '../../../../core/router/app_routes.dart';

/// Overflow menu entries + handler — same behavior as legacy Dashboard AppBar menu.
void handleDashboardOverflowSelection(BuildContext context, WidgetRef ref, String value) async {
  switch (value) {
    case 'map':
      context.go(AppRoute.map.path);
      break;
    case 'fuel':
      context.go(AppRoute.fuel.path);
      break;
    case 'vehicles':
      context.go(AppRoute.myVehicles.path);
      break;
    case 'inventory':
      context.push(AppRoute.inventoryStockMap);
      break;
    case 'more':
      context.go(AppRoute.more.path);
      break;
    case 'logout':
      await ref.read(authSessionControllerProvider).logout();
      break;
  }
}

List<PopupMenuEntry<String>> buildDashboardOverflowMenuEntries(WidgetRef ref) {
  final loai = ref.read(authSessionControllerProvider).session?.loai;
  return [
    const PopupMenuItem(value: 'map', child: Text('Bản đồ cây xăng')),
    const PopupMenuItem(value: 'fuel', child: Text('Nhiên liệu')),
    const PopupMenuItem(value: 'vehicles', child: Text('Xe của tôi')),
    if (PortalRouteAccess.canAccessInventoryStockMap(loai))
      const PopupMenuItem(value: 'inventory', child: Text('Bản đồ tồn kho (Admin)')),
    const PopupMenuItem(value: 'more', child: Text('Thêm…')),
    const PopupMenuDivider(),
    const PopupMenuItem(value: 'logout', child: Text('Đăng xuất')),
  ];
}
