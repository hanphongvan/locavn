import { Injectable } from '@angular/core';

import { STORE_ADMIN_ACCESS_TOKEN_KEY, STORE_ADMIN_PORTAL_PROFILE_KEY } from './auth.constants';

/**
 * Persists OAuth access_token and optional cached portal profile for the admin SPA (tab-scoped).
 * Values originate from the API only — not a parallel auth model.
 */
@Injectable({ providedIn: 'root' })
export class AuthSessionStorage {
  getAccessToken(): string | null {
    if (typeof sessionStorage === 'undefined') {
      return null;
    }
    const t = sessionStorage.getItem(STORE_ADMIN_ACCESS_TOKEN_KEY)?.trim();
    return t || null;
  }

  setAccessToken(accessToken: string): void {
    if (typeof sessionStorage === 'undefined') {
      return;
    }
    sessionStorage.setItem(STORE_ADMIN_ACCESS_TOKEN_KEY, accessToken.trim());
  }

  clearAccessToken(): void {
    if (typeof sessionStorage === 'undefined') {
      return;
    }
    sessionStorage.removeItem(STORE_ADMIN_ACCESS_TOKEN_KEY);
  }

  hasAccessToken(): boolean {
    return !!this.getAccessToken();
  }

  /** Raw JSON from `GET /api/admin/auth/me` (caller validates `Loai`). */
  getPortalProfileJson(): string | null {
    if (typeof sessionStorage === 'undefined') {
      return null;
    }
    const j = sessionStorage.getItem(STORE_ADMIN_PORTAL_PROFILE_KEY)?.trim();
    return j || null;
  }

  setPortalProfileJson(json: string): void {
    if (typeof sessionStorage === 'undefined') {
      return;
    }
    sessionStorage.setItem(STORE_ADMIN_PORTAL_PROFILE_KEY, json);
  }

  clearPortalProfile(): void {
    if (typeof sessionStorage === 'undefined') {
      return;
    }
    sessionStorage.removeItem(STORE_ADMIN_PORTAL_PROFILE_KEY);
  }

  /** Clears Bearer token and cached portal profile together. */
  clearPortalSession(): void {
    this.clearAccessToken();
    this.clearPortalProfile();
  }
}
