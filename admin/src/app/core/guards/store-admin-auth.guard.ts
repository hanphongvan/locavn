import { HttpErrorResponse } from '@angular/common/http';
import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { catchError, map, of } from 'rxjs';

import { AdminAuthService } from '../auth/admin-auth.service';

/**
 * Protects the admin shell: requires a stored OAuth access token **and** a successful
 * `GET /api/admin/auth/me` with `Loai` hợp lệ cho SPA (Fuel 1,3,4; HTTM 10,11,12).
 */
export const storeAdminAuthGuard: CanActivateFn = (_route, state) => {
  const auth = inject(AdminAuthService);
  const router = inject(Router);

  if (!auth.hasAccessToken()) {
    return router.createUrlTree(['/login'], { queryParams: { returnUrl: state.url } });
  }

  return auth.getCurrentUserProfile().pipe(
    map((me) => {
      if (!auth.applyValidatedAdminProfile(me)) {
        return router.createUrlTree(['/login'], {
          queryParams: { returnUrl: state.url, reason: 'portal_role' },
        });
      }
      return true;
    }),
    catchError((err: unknown) => {
      if (err instanceof HttpErrorResponse) {
        if (err.status === 401) {
          auth.clearCredentials();
          return of(router.createUrlTree(['/login'], { queryParams: { returnUrl: state.url } }));
        }
      }
      auth.clearCredentials();
      return of(router.createUrlTree(['/login'], { queryParams: { returnUrl: state.url } }));
    }),
  );
};
