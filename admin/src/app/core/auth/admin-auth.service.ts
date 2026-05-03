import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable, computed, inject, signal } from '@angular/core';
import { Router } from '@angular/router';
import { Observable, catchError, of, switchMap, throwError } from 'rxjs';

import { API_BASE_URL } from '../tokens/api-base-url.token';
import type { AdminPortalUserSession } from './admin-auth.types';
import { AuthSessionStorage } from './auth-session.storage';
import { CurrentUserContextService } from './current-user-context.service';
import type { AdminAuthMe } from './models/admin-auth-me.model';
import type { OAuthPasswordGrantTokenResponse } from './models/oauth-password-grant-token-response.model';
import type { StoreAdminMe } from './models/store-admin-me.model';
import {
  buildRoleLandingPathFromPortalRole,
  resolvePostLoginNavigationUrl,
} from './admin-post-login-navigation';
import { extractAccessTokenFromPasswordGrant } from './oauth-password-grant-response.parse';
import { isAuthorizedPortalLoai, mapLoaiToPortalRole } from './portal-loai-role';
import { PortalRoleUnauthorizedError } from './portal-role-unauthorized.error';

const OAUTH_FORM_MEDIA_TYPE = 'application/x-www-form-urlencoded';

@Injectable({ providedIn: 'root' })
export class AdminAuthService {
  private readonly http = inject(HttpClient);
  private readonly router = inject(Router);
  private readonly apiBase = inject(API_BASE_URL).replace(/\/$/, '');
  private readonly session = inject(AuthSessionStorage);
  private readonly userContext = inject(CurrentUserContextService);

  /** Latest validated profile from `GET /api/admin/auth/me` (also cached in sessionStorage). */
  readonly currentUserProfile = signal<AdminAuthMe | null>(null);

  readonly portalRole = computed(() => mapLoaiToPortalRole(this.currentUserProfile()?.loai));

  /** Merged view: Bearer token + profile; `null` when token or profile is missing or `Loai` is not allowed. */
  readonly userSession = computed((): AdminPortalUserSession | null => {
    const token = this.session.getAccessToken();
    const p = this.currentUserProfile();
    if (!token || !p || !isAuthorizedPortalLoai(p.loai)) {
      return null;
    }
    return {
      accessToken: token,
      userName: p.userName,
      displayName: p.displayName,
      email: p.email,
      donViId: p.donViId,
      loai: p.loai,
      role: mapLoaiToPortalRole(p.loai),
    };
  });

  /**
   * Dashboard home for the current profile (`Loai` → role). Uses `/api/admin/auth/me` data only.
   * Invalid / missing role → `/access-denied` (e.g. corrupt cache); unauthenticated callers should not rely on this.
   */
  readonly defaultDashboardUrl = computed(() => buildRoleLandingPathFromPortalRole(this.portalRole()));

  constructor() {
    if (!this.session.hasAccessToken()) {
      this.userContext.clear();
      this.currentUserProfile.set(null);
      return;
    }
    const me = this.readValidProfileFromSession();
    this.currentUserProfile.set(me);
  }

  /** Same as {@link defaultDashboardUrl} — explicit name for post-login / redirect flows. */
  getRoleLandingPath(): string {
    return buildRoleLandingPathFromPortalRole(this.portalRole());
  }

  /**
   * Central post-login target: role landing from backend `Loai`, or safe `returnUrl` if not another role's dashboard.
   */
  resolvePostLoginNavigationTarget(returnUrl: string | null): string {
    return resolvePostLoginNavigationUrl({
      returnUrl,
      portalRole: this.portalRole(),
    });
  }

  hasAccessToken(): boolean {
    return this.session.hasAccessToken();
  }

  getAccessToken(): string | null {
    return this.session.getAccessToken();
  }

  clearCredentials(): void {
    this.session.clearPortalSession();
    this.currentUserProfile.set(null);
    this.userContext.clear();
  }

  logout(): void {
    this.clearCredentials();
    void this.router.navigate(['/login']);
  }

  isAdmin(): boolean {
    return this.portalRole() === 'ADMIN';
  }

  isTrader(): boolean {
    return this.portalRole() === 'TRADER';
  }

  isStore(): boolean {
    return this.portalRole() === 'STORE';
  }

  hasValidLocalPortalSession(): boolean {
    const me = this.readValidProfileFromSession();
    if (!me) {
      this.currentUserProfile.set(null);
      if (this.session.hasAccessToken()) {
        this.userContext.clear();
      }
      return false;
    }
    this.currentUserProfile.set(me);
    return true;
  }

  /**
   * OAuth2 password grant to the real backend (`POST /api/oauth/token`), then loads portal profile.
   * Invalid `Loai` for this app clears the session and errors with {@link PortalRoleUnauthorizedError}.
   */
  login(username: string, password: string): Observable<AdminAuthMe> {
    const tokenUrl = `${this.apiBase}/api/oauth/token`;
    const body = new HttpParams({
      fromObject: {
        grant_type: 'password',
        username: username.trim(),
        password,
      },
    });

    return this.http
      .post<OAuthPasswordGrantTokenResponse>(tokenUrl, body.toString(), {
        headers: { 'Content-Type': OAUTH_FORM_MEDIA_TYPE },
      })
      .pipe(
        switchMap((res) => {
          const token = extractAccessTokenFromPasswordGrant(res);
          if (!token) {
            return throwError(() => new Error('Phản hồi đăng nhập không chứa access_token hợp lệ.'));
          }
          this.session.setAccessToken(token);
          return this.getCurrentUserProfile().pipe(
            catchError((err) => {
              this.session.clearPortalSession();
              this.userContext.clear();
              return throwError(() => err);
            }),
          );
        }),
        switchMap((me) => {
          if (!this.applyValidatedAdminProfile(me)) {
            void this.router.navigate(['/access-denied'], {
              queryParams: { reason: 'unsupported_loai' },
            });
            return throwError(() => new PortalRoleUnauthorizedError());
          }
          return of(me);
        }),
      );
  }

  /** `GET /api/admin/auth/me` — portal user + `Loai` (authoritative for RBAC in this SPA). */
  getCurrentUserProfile(): Observable<AdminAuthMe> {
    return this.http.get<AdminAuthMe>(`${this.apiBase}/api/admin/auth/me`);
  }

  applyValidatedAdminProfile(me: AdminAuthMe): boolean {
    if (!isAuthorizedPortalLoai(me.loai)) {
      this.clearCredentials();
      return false;
    }
    this.session.setPortalProfileJson(JSON.stringify(me));
    this.currentUserProfile.set(me);
    this.userContext.applyValidatedProfile(me);
    return true;
  }

  /** `GET /api/admin/store-auth/me` — optional store-admin eligibility (separate from `Loai`). */
  getStoreAdminProfile(): Observable<StoreAdminMe> {
    return this.http.get<StoreAdminMe>(`${this.apiBase}/api/admin/store-auth/me`);
  }

  private readValidProfileFromSession(): AdminAuthMe | null {
    this.userContext.tryHydrateSessionProfileFromPersisted(this.session);
    const first = this.tryParseAuthorizedPortalProfile(this.session.getPortalProfileJson());
    if (first) {
      this.userContext.applyValidatedProfile(first);
      return first;
    }
    const bad = this.session.getPortalProfileJson();
    if (bad) {
      this.session.clearPortalProfile();
      this.userContext.tryHydrateSessionProfileFromPersisted(this.session);
      const second = this.tryParseAuthorizedPortalProfile(this.session.getPortalProfileJson());
      if (second) {
        this.userContext.applyValidatedProfile(second);
        return second;
      }
    }
    return null;
  }

  private tryParseAuthorizedPortalProfile(json: string | null): AdminAuthMe | null {
    if (!json) {
      return null;
    }
    try {
      const me = JSON.parse(json) as AdminAuthMe;
      if (!me || typeof me.userName !== 'string') {
        return null;
      }
      if (!isAuthorizedPortalLoai(me.loai)) {
        return null;
      }
      return me;
    } catch {
      return null;
    }
  }
}
