import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';

import { AdminAuthService } from '../auth/admin-auth.service';

/** Login route: if a valid local portal session exists, skip to the app shell. */
export const storeAdminGuestGuard: CanActivateFn = () => {
  const auth = inject(AdminAuthService);
  const router = inject(Router);
  if (!auth.hasAccessToken()) {
    return true;
  }
  if (!auth.hasValidLocalPortalSession()) {
    auth.clearCredentials();
    return true;
  }
  return router.parseUrl(auth.getRoleLandingPath());
};
