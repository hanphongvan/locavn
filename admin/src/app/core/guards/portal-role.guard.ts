import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';

import { AdminAuthService } from '../auth/admin-auth.service';
import { PORTAL_ROLES_ROUTE_DATA_KEY, type PortalRolesRouteData } from '../auth/portal-route-data';
import type { PortalRole } from '../auth/portal-loai-role';

/**
 * Restricts a route using `data.portalRoles` (mapped from backend `Loai` via {@link AdminAuthService.portalRole}).
 * - Omit `portalRoles` or use an empty array → no extra check (allow).
 * - Unauthenticated → `/login`.
 * - Authenticated but role not listed → `/access-denied`.
 *
 * Compose **after** {@link storeAdminAuthGuard} so profile is already loaded.
 */
export const portalRoleGuard: CanActivateFn = (route, state) => {
  const auth = inject(AdminAuthService);
  const router = inject(Router);

  const data = route.data as PortalRolesRouteData;
  const allowed = data[PORTAL_ROLES_ROUTE_DATA_KEY] as readonly PortalRole[] | undefined;

  if (!allowed || allowed.length === 0) {
    return true;
  }

  if (!auth.hasAccessToken()) {
    return router.createUrlTree(['/login'], { queryParams: { returnUrl: state.url } });
  }

  const role = auth.portalRole();
  if (!role) {
    return router.createUrlTree(['/access-denied'], { queryParams: { returnUrl: state.url } });
  }

  const ok = (allowed as readonly PortalRole[]).includes(role);
  if (!ok) {
    return router.createUrlTree(['/access-denied'], { queryParams: { returnUrl: state.url } });
  }

  return true;
};
