import { InjectionToken } from '@angular/core';

/** Absolute base URL for the ASP.NET Core admin API (no trailing slash). */
export const API_BASE_URL = new InjectionToken<string>('API_BASE_URL');
