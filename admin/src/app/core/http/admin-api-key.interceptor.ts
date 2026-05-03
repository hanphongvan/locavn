import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';

import { AuthSessionStorage } from '../auth/auth-session.storage';
import { environment } from '../../../environments/environment';
import { isRequestToApiBase } from './api-origin-matches.util';

/** Phải khớp `AdminApiKeyDefaults.ApiKeyHeaderName` trên backend. */
const ADMIN_API_KEY_HEADER = 'X-Admin-Api-Key';

export const adminApiKeyInterceptor: HttpInterceptorFn = (req, next) => {
  const key = environment.adminApiKey?.trim();
  if (!key) {
    return next(req);
  }
  const base = environment.apiBaseUrl.replace(/\/$/, '');
  if (!base || !isRequestToApiBase(req.url, base)) {
    return next(req);
  }
  // Khi đã đăng nhập Bearer, backend ưu tiên AdminApiKey trước Bearer — không gửi API key để `/me` và API người dùng dùng đúng JWT.
  if (inject(AuthSessionStorage).hasAccessToken()) {
    return next(req);
  }
  return next(req.clone({ setHeaders: { [ADMIN_API_KEY_HEADER]: key } }));
};
