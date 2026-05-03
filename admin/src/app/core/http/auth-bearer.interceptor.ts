import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';

import { AuthSessionStorage } from '../auth/auth-session.storage';
import { environment } from '../../../environments/environment';
import { isRequestToApiBase } from './api-origin-matches.util';

export const authBearerInterceptor: HttpInterceptorFn = (req, next) => {
  const base = environment.apiBaseUrl.replace(/\/$/, '');
  if (!base || !isRequestToApiBase(req.url, base)) {
    return next(req);
  }
  const token = inject(AuthSessionStorage).getAccessToken();
  if (!token) {
    return next(req);
  }
  return next(req.clone({ setHeaders: { Authorization: `Bearer ${token}` } }));
};
