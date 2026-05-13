import {
  ADMIN_PORTAL_ROLES_ONLY,
  ALL_PORTAL_ROLES,
  HTTM_PORTAL_ROLES,
  RETAIL_PORTAL_ROLES,
} from '../core/auth/portal-route-roles.config';
import type { PortalRole } from '../core/auth/portal-loai-role';

/**
 * ## Single app — portal roles (`Loai` → Fuel + HTTM)
 *
 * **Route access (authoritative):** guards + `Route.data.portalRoles`.
 *
 * **Menu (UX):** `SHELL_NAV_MENU_GROUPS` + `getShellNavGroupsForRole` — lọc theo vai trò.
 * Giữ menu đồng bộ ý định với `portalRoleGuard` khi thêm route.
 */

/** Một mục trong sidebar (Material Symbols / Icons ligature, ex. `dashboard`). */
export interface ShellNavMenuItem {
  readonly path: string;
  readonly label: string;
  readonly icon: string;
  readonly roles: readonly PortalRole[];
}

/**
 * Nhóm menu: hiển thị khi còn ít nhất một `items` sau khi lọc theo vai trò.
 * `roles` trên nhóm = ai được thấy nhóm (thường trùng tập hợp union của items).
 */
export interface ShellNavMenuGroup {
  readonly id: string;
  readonly title: string;
  readonly roles: readonly PortalRole[];
  readonly items: readonly ShellNavMenuItem[];
}

export const SHELL_NAV_MENU_GROUPS: readonly ShellNavMenuGroup[] = [
  {
    id: 'dashboard',
    title: 'Dashboard',
    roles: ALL_PORTAL_ROLES,
    items: [
      { path: '/dashboard', label: 'Tổng quan', icon: 'dashboard', roles: ALL_PORTAL_ROLES },
    ],
  },
  {
    id: 'retail-station',
    title: 'Cửa hàng xăng dầu',
    roles: RETAIL_PORTAL_ROLES,
    items: [
      { path: '/store-prices', label: 'Giá tại cửa hàng', icon: 'local_offer', roles: RETAIL_PORTAL_ROLES },
      { path: '/inventory-transactions', label: 'Nhập xuất kho', icon: 'swap_horiz', roles: RETAIL_PORTAL_ROLES },
      { path: '/inventory-current', label: 'Tồn kho', icon: 'warehouse', roles: RETAIL_PORTAL_ROLES },
      /* Bản đồ tồn kho: chỉ Admin — `Loai === 1` → `PortalRole.ADMIN` (khớp `retail.routes` + `portalRoleGuard`). */
      { path: '/inventory-map', label: 'Bản đồ tồn kho', icon: 'map', roles: ADMIN_PORTAL_ROLES_ONLY },
    ],
  },
  {
    id: 'httm',
    title: 'Hạ tầng thương mại',
    roles: HTTM_PORTAL_ROLES,
    items: [
      { path: '/httm', label: 'Hồ sơ HTTM', icon: 'store_mall_directory', roles: HTTM_PORTAL_ROLES },
      { path: '/httm/map', label: 'Bản đồ HTTM', icon: 'map', roles: HTTM_PORTAL_ROLES },
    ],
  },
  {
    id: 'catalog',
    title: 'Danh mục',
    roles: RETAIL_PORTAL_ROLES,
    items: [
      { path: '/stores', label: 'Cửa hàng', icon: 'storefront', roles: RETAIL_PORTAL_ROLES },
      { path: '/fuel-products', label: 'Mặt hàng xăng dầu', icon: 'local_gas_station', roles: ADMIN_PORTAL_ROLES_ONLY },
    ],
  },
  {
    id: 'system',
    title: 'Hệ thống',
    roles: ADMIN_PORTAL_ROLES_ONLY,
    items: [
      { path: '/users', label: 'Người dùng', icon: 'group', roles: ADMIN_PORTAL_ROLES_ONLY },
      { path: '/demo-data', label: 'Demo Data', icon: 'science', roles: ADMIN_PORTAL_ROLES_ONLY },
    ],
  },
] as const;

export function getShellNavGroupsForRole(role: PortalRole | null): ShellNavMenuGroup[] {
  if (!role) {
    return [];
  }
  return SHELL_NAV_MENU_GROUPS.filter((g) => g.roles.includes(role))
    .map((g) => ({
      ...g,
      items: g.items.filter((it) => it.roles.includes(role)),
    }))
    .filter((g) => g.items.length > 0);
}
