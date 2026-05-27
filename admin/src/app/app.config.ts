import { APP_BASE_HREF, registerLocaleData } from '@angular/common';
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import localeVi from '@angular/common/locales/vi';
import {
  ApplicationConfig,
  importProvidersFrom,
  inject,
  LOCALE_ID,
  provideAppInitializer,
  provideZoneChangeDetection,
} from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideAnimationsAsync } from '@angular/platform-browser/animations/async';
import { provideNativeDateAdapter } from '@angular/material/core';

import { MatSnackBarModule } from '@angular/material/snack-bar';

import { routes } from './app.routes';
import { BUILD_INFO } from './core/config/build-info';
import { RuntimeConfigService } from './core/config/runtime-config.service';
import { adminApiKeyInterceptor } from './core/http/admin-api-key.interceptor';
import { adminApiUnauthorizedInterceptor } from './core/http/admin-api-unauthorized.interceptor';
import { httmScopeFeedbackInterceptor } from './core/http/httm-scope-feedback.interceptor';
import { authBearerInterceptor } from './core/http/auth-bearer.interceptor';
import { API_BASE_URL } from './core/tokens/api-base-url.token';

registerLocaleData(localeVi);

// Pin BUILD_INFO vào bundle (in ra console + gắn lên `window` để dev/QA xem version
// nhanh qua DevTools). Side effect quan trọng: ép main bundle có nội dung khác sau
// mỗi `npm run build:prod` → Angular content-hash đổi → tên file `main-<hash>.js`
// mới → browser bắt buộc tải bản mới (không dính cache cũ).
console.info('[App] Build:', BUILD_INFO);
(globalThis as { __APP_BUILD__?: typeof BUILD_INFO }).__APP_BUILD__ = BUILD_INFO;

export const appConfig: ApplicationConfig = {
  providers: [
    /** Must match `<base href>` in `index.html` (Leaflet marker URLs, Router). */
    { provide: APP_BASE_HREF, useValue: '/' },
    { provide: LOCALE_ID, useValue: 'vi' },
    provideAnimationsAsync(),
    provideNativeDateAdapter(),
    provideZoneChangeDetection({ eventCoalescing: true }),
    provideRouter(routes),
    provideHttpClient(
      withInterceptors([
        adminApiUnauthorizedInterceptor,
        authBearerInterceptor,
        adminApiKeyInterceptor,
        httmScopeFeedbackInterceptor,
      ]),
    ),
    importProvidersFrom(MatSnackBarModule),
    /**
     * Tải `assets/runtime-config.json` TRƯỚC khi app bootstrap → `API_BASE_URL` factory
     * dưới đây luôn đọc được giá trị đã load. Đổi URL API trên server: chỉ sửa file JSON
     * + F5, không cần build lại.
     */
    provideAppInitializer(() => inject(RuntimeConfigService).load()),
    {
      provide: API_BASE_URL,
      useFactory: (cfg: RuntimeConfigService) => cfg.apiBaseUrl,
      deps: [RuntimeConfigService],
    },
  ],
};
