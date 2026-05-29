import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';

import { AuthSessionStorage } from '../auth/auth-session.storage';
import { API_BASE_URL } from '../tokens/api-base-url.token';
import { isRequestToApiBase } from './api-origin-matches.util';

export const authBearerInterceptor: HttpInterceptorFn = (req, next) => {
  const base = inject(API_BASE_URL);
  if (!base || !isRequestToApiBase(req.url, base)) {
    return next(req);
  }
  const token = inject(AuthSessionStorage).getAccessToken();
  if (!token) {
    return next(req);
  }
  return next(req.clone({ setHeaders: { Authorization: `Bearer ${token}` } }));
};
