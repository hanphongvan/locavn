import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/change_password_page.dart';
import '../../features/bad_reports/presentation/my_violation_reports_page.dart';
import '../../features/my_reviews/presentation/my_station_reviews_page.dart';
import '../../features/auth/presentation/forgot_password_page.dart';
import '../../features/auth/presentation/register_user_page.dart';
import '../../features/auth/presentation/reset_password_page.dart';
import '../../features/auth/presentation/splash_page.dart';
import '../../features/fuel/data/models/fuel_tracking_models.dart';
import '../../features/fuel/presentation/add_fuel_transaction_page.dart';
import '../../features/fuel/presentation/fuel_all_transactions_page.dart';
import '../../features/fuel/presentation/fuel_shell_page.dart';
import '../../features/inventory_stock_map/presentation/inventory_stock_map_shell_page.dart';
import '../../features/map/presentation/map_shell_page.dart';
import '../../features/more/presentation/account/account_screen.dart';
import '../../features/leader/presentation/leader_analytics_page.dart';
import '../../features/leader/presentation/leader_map_shell.dart';
import '../../features/leader/presentation/leader_overview_page.dart';
import '../../features/leader/presentation/leader_main_screen.dart';
import '../../features/leader/presentation/leader_retail_screen.dart';
import '../../features/leader/presentation/stabilization_fund_screen.dart';
import '../../features/more/presentation/more_shell_page.dart';
import '../../features/my_vehicles/presentation/my_vehicles_shell_page.dart';
import '../../features/reports/presentation/reports_shell_page.dart';
import '../../features/station_detail/presentation/station_detail_shell_page.dart';
import '../../features/portal_role/presentation/portal_role_home_pages.dart';
import '../../features/store/presentation/store_account_page.dart';
import '../../features/store_inventory/presentation/inventory_form_screen.dart';
import '../../features/store_inventory/presentation/inventory_voucher_detail_screen.dart';
import '../../features/store_inventory/presentation/store_inventory_tab_page.dart';
import '../../features/store_services/presentation/store_services_tab_page.dart';
import '../../features/store/presentation/store_prices_tab_page.dart';
import '../../features/store/presentation/store_shell_page.dart';
import '../../features/reports/presentation/dashboard/loca_dashboard_tokens.dart';
import '../auth/auth_providers.dart';
import '../auth/auth_session_controller.dart';
import '../auth/portal_route_access.dart';
import 'citizen_guest_route_access.dart';
import '../../features/auth/presentation/access_denied_page.dart';
import '../../features/auth/presentation/citizen_login_prompt.dart';
import 'app_root_navigator_key.dart';
import 'app_routes.dart';
import 'role_home_navigation.dart';

/// Nhóm shell **tách biệt** trong cây route: khi đổi nhóm (vd Leader → guest Citizen),
/// [goRouterProvider] tạo **GoRouter mới** và dispose navigator cũ — tránh cùng frame có hai
/// [StatefulNavigationShell] (duplicate `GlobalKey<StatefulNavigationShellState>`,
/// `_ElementLifecycle.inactive` khi GoRouter redirect thay shell).
///
/// Guest + `Loai == 5` cùng nhóm `consumer` (cùng tab shell `/map`…): đăng nhập/xuất citizen
/// không recreate router, chỉ redirect + session.
final _routerPortalShellFamilyProvider = Provider<String>((ref) {
  return ref.watch(
    authSessionControllerProvider.select((c) {
      if (!c.isReady) {
        return 'loading';
      }
      final loai = c.session?.loai;
      if (loai == null || loai == 5) {
        return 'consumer';
      }
      if (loai == 4) {
        return 'store';
      }
      if (loai == 6) {
        return 'leader';
      }
      if (loai == 1) {
        return 'admin';
      }
      if (loai == 3) {
        return 'trader';
      }
      return 'consumer';
    }),
  );
});

String _initialLocationForAuth(AuthSessionController auth) {
  if (!auth.isReady) {
    return AppRoute.splash;
  }
  if (!auth.isAuthenticated) {
    return AppRoute.map.path;
  }
  return roleHomeLocationForLoai(auth.session?.loai) ?? AppRoute.map.path;
}

/// Single [GoRouter] bound to [AuthSessionController] for redirect + refresh.
///
/// After `AppSessionBootstrap` restores local session, [redirect] sends authed users to the
/// role home from stored `Loai` (Leader `Loai == 6` → `/leader/overview`).
/// **Chưa đăng nhập (Citizen guest):** vào `/map` + tra cứu trạm công khai; không ép `/login` toàn app.
/// Đổi `Loai` khi URL vẫn là shell portal khác → redirect về home đúng role ([PortalRouteAccess.shouldBounceFromForeignPortalShell]).
final goRouterProvider = Provider<GoRouter>((ref) {
  ref.watch(_routerPortalShellFamilyProvider);
  final auth = ref.read(authSessionControllerProvider);
  final router = GoRouter(
    navigatorKey: appRootNavigatorKey,
    initialLocation: _initialLocationForAuth(auth),
    refreshListenable: auth,
    errorBuilder: (context, state) => _RouteNotFoundPage(
      attemptedLocation: state.uri.toString(),
    ),
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (!auth.isReady) {
        if (loc == AppRoute.splash) return null;
        return AppRoute.splash;
      }
      if (auth.isAuthenticated && loc == AppRoute.accessDenied) {
        if (state.uri.queryParameters['reason'] != 'forbidden') {
          final home = roleHomeLocationForLoai(auth.session?.loai);
          if (home != null) {
            return home;
          }
        }
        return null;
      }
      if (!auth.isAuthenticated) {
        if (loc == AppRoute.login ||
            loc == AppRoute.register ||
            loc == AppRoute.forgotPassword ||
            loc == AppRoute.resetPassword) {
          return null;
        }
        if (loc == AppRoute.splash) {
          return AppRoute.map.path;
        }
        if (CitizenGuestRouteAccess.isPublicLocation(loc)) {
          return null;
        }
        return AppRoute.map.path;
      }
      if (loc == AppRoute.login || loc == AppRoute.splash) {
        final home = roleHomeLocationForLoai(auth.session?.loai);
        if (home == null) {
          return AppRoute.accessDenied;
        }
        return home;
      }
      final loai = auth.session?.loai;
      final roleHome = roleHomeLocationForLoai(loai);
      if (roleHome != null && PortalRouteAccess.shouldBounceFromForeignPortalShell(loc, loai)) {
        return roleHome;
      }
      if (!PortalRouteAccess.isAllowedLocation(loc, loai)) {
        // Theo spec: khi RBAC chặn → luôn hiện AccessDenied (không bounce âm thầm về home),
        // truyền `?reason=forbidden` để page biết hiển thị thông báo "không có quyền".
        return '${AppRoute.accessDenied}?reason=forbidden';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoute.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoute.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoute.register,
        builder: (context, state) => const RegisterUserPage(),
      ),
      GoRoute(
        path: AppRoute.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoute.resetPassword,
        builder: (context, state) => ResetPasswordPage(
          initialToken: state.uri.queryParameters['token'],
        ),
      ),
      GoRoute(
        path: AppRoute.changePassword.path,
        parentNavigatorKey: appRootNavigatorKey,
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: AppRoute.myViolationReports.path,
        parentNavigatorKey: appRootNavigatorKey,
        builder: (context, state) => const MyViolationReportsPage(),
      ),
      GoRoute(
        path: AppRoute.myStationReviews.path,
        parentNavigatorKey: appRootNavigatorKey,
        builder: (context, state) => const MyStationReviewsPage(),
      ),
      GoRoute(
        path: AppRoute.accessDenied,
        builder: (context, state) => const AccessDeniedPage(),
      ),
      GoRoute(
        path: AppRoute.leaderRoot,
        redirect: (context, state) => AppRoute.leaderOverview,
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return LeaderMainScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.leaderOverview,
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: LeaderOverviewPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.leaderMap,
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: LeaderMapShell(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.leaderRetail,
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: LeaderRetailScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.leaderAnalytics,
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: LeaderAnalyticsPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.leaderStabilizationFund,
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: StabilizationFundScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoute.leaderAccount,
        parentNavigatorKey: appRootNavigatorKey,
        builder: (context, state) =>
            const AccountScreen(embeddedInLeaderShell: true),
      ),
      GoRoute(
        path: AppRoute.storeRoot,
        redirect: (context, state) => AppRoute.storeMap,
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return StoreShellPage(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.storeMap,
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: MapShellPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.storeSalePrices,
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: StorePricesTabPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.storeServices,
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: StoreServicesTabPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.storeInventory,
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: StoreInventoryTabPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.storeAccount,
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: StoreAccountPage(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoute.portalAdminHome,
        parentNavigatorKey: appRootNavigatorKey,
        pageBuilder: (context, state) => const NoTransitionPage<void>(
          child: AdminPortalHomePage(),
        ),
      ),
      GoRoute(
        path: AppRoute.portalTraderHome,
        parentNavigatorKey: appRootNavigatorKey,
        pageBuilder: (context, state) => const NoTransitionPage<void>(
          child: TraderPortalHomePage(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _MainTabShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.map.path,
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: MapShellPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.fuel.path,
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: FuelShellPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.myVehicles.path,
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: MyVehiclesShellPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.more.path,
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: MoreShellPage(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoute.reports.path,
        parentNavigatorKey: appRootNavigatorKey,
        pageBuilder: (context, state) => const NoTransitionPage<void>(
          child: ReportsShellPage(),
        ),
      ),
      GoRoute(
        path: AppRoute.stationDetailPattern,
        parentNavigatorKey: appRootNavigatorKey,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return StationDetailShellPage(stationId: id);
        },
      ),
      GoRoute(
        path: AppRoute.inventoryStockMap,
        parentNavigatorKey: appRootNavigatorKey,
        builder: (context, state) => const InventoryStockMapShellPage(),
      ),
      GoRoute(
        path: AppRoute.fuelTransactionsHistory.path,
        parentNavigatorKey: appRootNavigatorKey,
        builder: (context, state) {
          final vid = int.tryParse(state.uri.queryParameters['vehicleId'] ?? '') ?? 0;
          return FuelAllTransactionsPage(vehicleId: vid > 0 ? vid : 0);
        },
      ),
      GoRoute(
        path: AppRoute.storeInventoryCreate,
        parentNavigatorKey: appRootNavigatorKey,
        builder: (context, state) => const InventoryFormScreen(),
      ),
      GoRoute(
        path: AppRoute.storeInventoryVoucherPattern,
        parentNavigatorKey: appRootNavigatorKey,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['headerId'] ?? '') ?? 0;
          return InventoryVoucherDetailScreen(headerId: id);
        },
      ),
      GoRoute(
        path: AppRoute.addFuelTransaction.path,
        parentNavigatorKey: appRootNavigatorKey,
        builder: (context, state) {
          final id = int.tryParse(state.uri.queryParameters['vehicleId'] ?? '') ?? 0;
          final editId = int.tryParse(state.uri.queryParameters['editId'] ?? '') ?? 0;
          final extra = state.extra;
          FuelTransactionEditPrefill? prefill;
          if (extra is FuelTransactionEditPrefill) {
            prefill = extra;
          }
          return AddFuelTransactionPage(
            vehicleId: id > 0 ? id : 0,
            editTransactionId: editId > 0 ? editId : null,
            editPrefill: prefill,
          );
        },
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Hiển thị khi GoRouter không khớp được path (URL lạ / link cũ / typo).
/// Nút "Về trang chủ" điều hướng theo `Loai` của session hiện tại; guest → `/map`.
class _RouteNotFoundPage extends ConsumerWidget {
  const _RouteNotFoundPage({required this.attemptedLocation});

  final String attemptedLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final loai = ref.watch(
      authSessionControllerProvider.select((c) => c.session?.loai),
    );
    final authed = ref.watch(
      authSessionControllerProvider.select((c) => c.isAuthenticated),
    );
    final fallback = roleHomeLocationForLoai(loai) ?? (authed ? AppRoute.login : AppRoute.map.path);

    return Scaffold(
      appBar: AppBar(title: const Text('Liên kết không hợp lệ')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.link_off_rounded, size: 64, color: scheme.error),
              const SizedBox(height: 20),
              Text(
                'Đường dẫn không tồn tại trong ứng dụng.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                attemptedLocation,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                    ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go(fallback),
                child: const Text('Về trang chủ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom tabs **Người dân** (`Loai == 5`): Bản đồ, Nhiên liệu, Xe của tôi, Tài khoản.
/// Cửa hàng (`Loai == 4`) dùng [StoreShellPage]; **Lãnh đạo** (`Loai == 6`) dùng [LeaderMainScreen];
/// Admin / Trader dùng màn placeholder — xem [roleHomeLocationForLoai].
///
/// Guest: tab Nhiên liệu / Xe → [showCitizenLoginRequiredPrompt]; tab Tài khoản → [LoginPage] trong shell.
class _MainTabShell extends ConsumerWidget {
  const _MainTabShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const primaryNav = LocaDashboardTokens.primaryBlue;
    const mutedNav = LocaDashboardTokens.textSecondary;
    const accentNav = LocaDashboardTokens.primaryBlue;

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
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                    );
                  }
                  return const TextStyle(
                    color: mutedNav,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  );
                }),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const IconThemeData(color: primaryNav, size: 26);
                  }
                  return const IconThemeData(color: mutedNav, size: 26);
                }),
              ),
              child: NavigationBar(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: (i) {
                  final guest = !ref.read(authSessionControllerProvider).isAuthenticated;
                  if (guest && (i == 1 || i == 2)) {
                    showCitizenLoginRequiredPrompt(context);
                    return;
                  }
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
                    icon: Icon(Icons.local_gas_station_outlined),
                    selectedIcon: Icon(Icons.local_gas_station_rounded),
                    label: 'Nhiên liệu',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.directions_car_outlined),
                    selectedIcon: Icon(Icons.directions_car_rounded),
                    label: 'Xe của tôi',
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
