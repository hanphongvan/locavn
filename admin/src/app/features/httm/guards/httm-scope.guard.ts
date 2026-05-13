import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';

import { AdminAuthService } from '../../../core/auth/admin-auth.service';
import { HTTM_PORTAL_ROLES } from '../../../core/auth/portal-route-roles.config';

/** Chỉ các vai trò được gọi API HTTM (đồng bộ backend `CanUseHttmModule`). */
export const httmScopeGuard: CanActivateFn = () => {
  const auth = inject(AdminAuthService);
  const router = inject(Router);
  const role = auth.portalRole();
  if (role && (HTTM_PORTAL_ROLES as readonly string[]).includes(role)) {
    return true;
  }
  return router.createUrlTree(['/access-denied']);
};
