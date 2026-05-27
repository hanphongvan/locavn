import type { PortalRole } from './portal-loai-role';
import { isHttmPortalRole, portalRoleToDashboardSegment } from './portal-loai-role';

/**
 * Landing path from backend-confirmed {@link PortalRole} (derived only from `Loai` on `/api/admin/auth/me`).
 * No guessing from token body or other sources.
 */
export function buildRoleLandingPathFromPortalRole(role: PortalRole | null): string {
  if (!role) {
    return '/access-denied';
  }
  if (isHttmPortalRole(role)) {
    return '/httm/dashboard';
  }
  const seg = portalRoleToDashboardSegment(role);
  if (!seg) {
    return '/access-denied';
  }
  return `/dashboard/${seg}`;
}

/**
 * After login, choose navigation target: role landing, or a safe `returnUrl` that is not another role's dashboard.
 */
export function resolvePostLoginNavigationUrl(options: {
  returnUrl: string | null;
  portalRole: PortalRole | null;
}): string {
  const roleLanding = buildRoleLandingPathFromPortalRole(options.portalRole);
  if (roleLanding === '/access-denied') {
    return roleLanding;
  }
  const raw = options.returnUrl?.trim();
  const safe =
    raw && raw.startsWith('/') && !raw.startsWith('//') && !raw.includes('://') ? raw : null;

  if (!safe || safe === '/dashboard') {
    return roleLanding;
  }

  if (safe.startsWith('/dashboard')) {
    const seg = portalRoleToDashboardSegment(options.portalRole!);
    if (!seg) {
      return roleLanding;
    }
    const prefix = `/dashboard/${seg}`;
    if (safe === prefix || safe.startsWith(`${prefix}/`)) {
      return safe;
    }
    return roleLanding;
  }

  if (safe.startsWith('/httm')) {
    const role = options.portalRole;
    if (role === 'ADMIN' || isHttmPortalRole(role)) {
      return safe;
    }
    return roleLanding;
  }

  return safe;
}
