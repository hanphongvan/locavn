import { HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { catchError, throwError } from 'rxjs';

import { AuthSessionStorage } from '../auth/auth-session.storage';
import { environment } from '../../../environments/environment';
import { isRequestToApiBase } from './api-origin-matches.util';

/**
 * Khi API admin trả 401 (JWT hết hạn / không hợp lệ), xóa session và đưa về đăng nhập.
 * Không áp dụng cho `POST /api/oauth/*` (luồng token).
 */
export const adminApiUnauthorizedInterceptor: HttpInterceptorFn = (req, next) => {
  const base = environment.apiBaseUrl.replace(/\/$/, '').trim();
  const session = inject(AuthSessionStorage);
  const router = inject(Router);

  return next(req).pipe(
    catchError((err: unknown) => {
      if (!(err instanceof HttpErrorResponse) || err.status !== 401) {
        return throwError(() => err);
      }
      if (!base || !isRequestToApiBase(req.url, base)) {
        return throwError(() => err);
      }
      if (req.url.includes('/api/oauth/')) {
        return throwError(() => err);
      }
      session.clearPortalSession();
      if (!router.url.startsWith('/login')) {
        void router.navigate(['/login'], { queryParams: { returnUrl: router.url } });
      }
      return throwError(() => err);
    }),
  );
};
