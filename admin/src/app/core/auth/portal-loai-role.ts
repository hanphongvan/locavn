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

/** HTTM — {@link AdminPortalLoaiRoleMapper.LoaiHttmAdmin}. */
export const PORTAL_LOAI_HT_TM_ADMIN = 10;
/** HTTM — Bộ Công Thương. */
export const PORTAL_LOAI_BCT_STAFF = 11;
/** HTTM — Sở (phạm vi tỉnh theo claim backend). */
export const PORTAL_LOAI_SO_STAFF = 12;

export type PortalRole =
  | 'ADMIN'
  | 'TRADER'
  | 'STORE'
  | 'HTTM_ADMIN'
  | 'BCT_STAFF'
  | 'SO_STAFF';

/** URL segment under `/dashboard/...` for Fuel dashboards. */
export type DashboardPortalSegment = 'admin' | 'trader' | 'store';

export function isHttmPortalRole(role: PortalRole | null): role is 'HTTM_ADMIN' | 'BCT_STAFF' | 'SO_STAFF' {
  return role === 'HTTM_ADMIN' || role === 'BCT_STAFF' || role === 'SO_STAFF';
}

export function portalRoleToDashboardSegment(role: PortalRole): DashboardPortalSegment | null {
  if (role === 'ADMIN') {
    return 'admin';
  }
  if (role === 'TRADER') {
    return 'trader';
  }
  if (role === 'STORE') {
    return 'store';
  }
  return null;
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
  if (loai === PORTAL_LOAI_HT_TM_ADMIN) {
    return 'HTTM_ADMIN';
  }
  if (loai === PORTAL_LOAI_BCT_STAFF) {
    return 'BCT_STAFF';
  }
  if (loai === PORTAL_LOAI_SO_STAFF) {
    return 'SO_STAFF';
  }
  return null;
}

/** Short label for UI (topbar, etc.). */
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
  if (role === 'HTTM_ADMIN') {
    return 'Quản trị HTTM';
  }
  if (role === 'BCT_STAFF') {
    return 'Cán bộ BCT';
  }
  if (role === 'SO_STAFF') {
    return 'Cán bộ Sở';
  }
  return '';
}

/** True when `Loai` is allowed for this admin SPA (Fuel 1,3,4 hoặc HTTM 10,11,12). */
export function isAuthorizedPortalLoai(loai: number | null | undefined): boolean {
  return mapLoaiToPortalRole(loai) !== null;
}
