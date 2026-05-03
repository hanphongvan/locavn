import type { PortalRole } from './portal-loai-role';

/**
 * Allowed {@link PortalRole} sets for `Route.data.portalRoles`.
 * Role values always come from backend `Loai` via {@link mapLoaiToPortalRole} — these arrays only list which roles may enter a route.
 *
 * **Admin-only (`Loai === 1`):** {@link ADMIN_PORTAL_ROLES_ONLY} — ví dụ `/inventory-map`, `/users`, CRUD mặt hàng…
 * Phải giữ **cùng một hằng** trên menu (`getShellNavGroupsForRole`) và route (`portalRoleGuard`).
 */

/** Any valid portal user (after `storeAdminAuthGuard`). */
export const ALL_PORTAL_ROLES: readonly PortalRole[] = ['ADMIN', 'TRADER', 'STORE'];

/** Cửa hàng, giá, kho — mọi vai trò portal; phạm vi dữ liệu do API lọc theo `Loai` / `DonViId`. */
export const RETAIL_PORTAL_ROLES: readonly PortalRole[] = ['ADMIN', 'TRADER', 'STORE'];

/** ADMIN-only areas. */
export const ADMIN_PORTAL_ROLES_ONLY: readonly PortalRole[] = ['ADMIN'];

/** TRADER-only areas. */
export const TRADER_PORTAL_ROLES_ONLY: readonly PortalRole[] = ['TRADER'];

/** STORE-only areas. */
export const STORE_PORTAL_ROLES_ONLY: readonly PortalRole[] = ['STORE'];
