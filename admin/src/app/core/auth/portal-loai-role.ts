/**
 * Single source of truth for portal RBAC: maps {@link AspNetUsers.Loai} from the API.
 * Do not duplicate these literals elsewhere in the admin app.
 */

/** Backend `AspNetUsers.Loai` for ADMIN (must match API contract). */
export const PORTAL_LOAI_ADMIN = 1;
/** Backend `AspNetUsers.Loai` for TRADER. */
export const PORTAL_LOAI_TRADER = 3;
/** Backend `AspNetUsers.Loai` for STORE. */
export const PORTAL_LOAI_STORE = 4;

export type PortalRole = 'ADMIN' | 'TRADER' | 'STORE';

/** URL segment under `/dashboard/...` (stable, lowercase). */
export type DashboardPortalSegment = 'admin' | 'trader' | 'store';

export function portalRoleToDashboardSegment(role: PortalRole): DashboardPortalSegment {
  if (role === 'ADMIN') {
    return 'admin';
  }
  if (role === 'TRADER') {
    return 'trader';
  }
  return 'store';
}

export function dashboardSegmentToPortalRole(segment: string | null): PortalRole | null {
  if (segment === 'admin') {
    return 'ADMIN';
  }
  if (segment === 'trader') {
    return 'TRADER';
  }
  if (segment === 'store') {
    return 'STORE';
  }
  return null;
}

export function mapLoaiToPortalRole(loai: number | null | undefined): PortalRole | null {
  if (loai === PORTAL_LOAI_ADMIN) {
    return 'ADMIN';
  }
  if (loai === PORTAL_LOAI_TRADER) {
    return 'TRADER';
  }
  if (loai === PORTAL_LOAI_STORE) {
    return 'STORE';
  }
  return null;
}

/** Short label for UI (topbar, etc.): Admin, TRADER, Store. */
export function portalRoleToTopbarLabel(role: PortalRole | null): string {
  if (role === 'ADMIN') {
    return 'Admin';
  }
  if (role === 'TRADER') {
    return 'TRADER';
  }
  if (role === 'STORE') {
    return 'Store';
  }
  return '';
}

/** True when `Loai` is allowed for this admin SPA (1, 3, or 4). */
export function isAuthorizedPortalLoai(loai: number | null | undefined): boolean {
  return mapLoaiToPortalRole(loai) !== null;
}
