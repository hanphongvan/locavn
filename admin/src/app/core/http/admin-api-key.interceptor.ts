import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';

import { AuthSessionStorage } from '../auth/auth-session.storage';
import { RuntimeConfigService } from '../config/runtime-config.service';
import { API_BASE_URL } from '../tokens/api-base-url.token';
import { isRequestToApiBase } from './api-origin-matches.util';

/** Phải khớp `AdminApiKeyDefaults.ApiKeyHeaderName` trên backend. */
const ADMIN_API_KEY_HEADER = 'X-Admin-Api-Key';

export const adminApiKeyInterceptor: HttpInterceptorFn = (req, next) => {
  const key = inject(RuntimeConfigService).adminApiKey?.trim();
  if (!key) {
    return next(req);
  }
  const base = inject(API_BASE_URL);
  if (!base || !isRequestToApiBase(req.url, base)) {
    return next(req);
  }
  // Khi đã đăng nhập Bearer, backend ưu tiên AdminApiKey trước Bearer — không gửi API key để `/me` và API người dùng dùng đúng JWT.
  if (inject(AuthSessionStorage).hasAccessToken()) {
    return next(req);
  }
  return next(req.clone({ setHeaders: { [ADMIN_API_KEY_HEADER]: key } }));
};
