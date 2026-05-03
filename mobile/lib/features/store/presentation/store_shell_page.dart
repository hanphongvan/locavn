import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/role_service.dart';

/// Bottom navigation **chỉ cửa hàng** (`Loai == 4`) — không trộn với shell người dân.
class StoreShellPage extends ConsumerWidget {
  const StoreShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loai = ref.watch(
      authSessionControllerProvider.select((c) => c.session?.loai),
    );
    if (!RoleService.isStoreUser(loai)) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Chỉ tài khoản cửa hàng (Loai = 4) được phép dùng giao diện này.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      );
    }

    const primaryNav = Color(0xFF0F4C9A);
    const mutedNav = Color(0xFF6B7897);
    const accentNav = Color(0xFF0F4C9A);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Material(
            elevation: 10,
            shadowColor: Colors.black.withValues(alpha: 0.12),
            color: Colors.white,
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                height: 68,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                shadowColor: Colors.transparent,
                indicatorColor: accentNav.withValues(alpha: 0.14),
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const TextStyle(
                      color: primaryNav,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                    );
                  }
                  return const TextStyle(
                    color: mutedNav,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  );
                }),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const IconThemeData(color: primaryNav, size: 24);
                  }
                  return const IconThemeData(color: mutedNav, size: 24);
                }),
              ),
              child: NavigationBar(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: (i) {
                  navigationShell.goBranch(
                    i,
                    initialLocation: i == navigationShell.currentIndex,
                  );
                },
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.map_outlined),
                    selectedIcon: Icon(Icons.map_rounded),
                    label: 'Bản đồ',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.price_change_outlined),
                    selectedIcon: Icon(Icons.price_change_rounded),
                    label: 'Giá bán',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.room_service_outlined),
                    selectedIcon: Icon(Icons.room_service_rounded),
                    label: 'Dịch vụ',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.inventory_2_outlined),
                    selectedIcon: Icon(Icons.inventory_2_rounded),
                    label: 'Tồn kho',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline_rounded),
                    selectedIcon: Icon(Icons.person_rounded),
                    label: 'Tài khoản',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
