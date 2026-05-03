import type { PortalRole } from './portal-loai-role';

/**
 * Normalized in-memory view of the signed-in portal user (API-sourced only).
 * `role` is always derived from `Loai` via {@link mapLoaiToPortalRole}; not taken from backend `role` string alone.
 */
export interface AdminPortalUserSession {
  accessToken: string;
  userName: string;
  displayName: string | null;
  email: string | null;
  donViId: number | null;
  loai: number | null;
  role: PortalRole | null;
}
