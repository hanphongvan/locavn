import { APP_BASE_HREF, registerLocaleData } from '@angular/common';
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import localeVi from '@angular/common/locales/vi';
import { ApplicationConfig, importProvidersFrom, LOCALE_ID, provideZoneChangeDetection } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideAnimationsAsync } from '@angular/platform-browser/animations/async';
import { provideNativeDateAdapter } from '@angular/material/core';

import { MatSnackBarModule } from '@angular/material/snack-bar';

import { routes } from './app.routes';
import { adminApiKeyInterceptor } from './core/http/admin-api-key.interceptor';
import { adminApiUnauthorizedInterceptor } from './core/http/admin-api-unauthorized.interceptor';
import { httmScopeFeedbackInterceptor } from './core/http/httm-scope-feedback.interceptor';
import { authBearerInterceptor } from './core/http/auth-bearer.interceptor';
import { API_BASE_URL } from './core/tokens/api-base-url.token';
import { environment } from '../environments/environment';

registerLocaleData(localeVi);

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
    { provide: API_BASE_URL, useValue: environment.apiBaseUrl },
  ],
};
