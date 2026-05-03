import { Injectable, computed, signal } from '@angular/core';

import { STORE_ADMIN_USER_CONTEXT_KEY } from './auth.constants';
import type { AuthSessionStorage } from './auth-session.storage';
import type { AdminAuthMe } from './models/admin-auth-me.model';
import {
  ADMIN_PORTAL_USER_CONTEXT_SCHEMA_VERSION,
  type AdminPortalUserContextPersistedV1,
} from './models/admin-portal-user-context.model';
import { isAuthorizedPortalLoai, mapLoaiToPortalRole } from './portal-loai-role';

function isRecord(v: unknown): v is Record<string, unknown> {
  return typeof v === 'object' && v !== null;
}

function parsePersistedUserContextJson(raw: string): AdminAuthMe | null {
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw) as unknown;
  } catch {
    return null;
  }
  if (!isRecord(parsed)) {
    return null;
  }
  if (parsed['v'] !== ADMIN_PORTAL_USER_CONTEXT_SCHEMA_VERSION) {
    return null;
  }
  const profile = parsed['profile'];
  if (!isRecord(profile)) {
    return null;
  }
  const me = profile as unknown as AdminAuthMe;
  if (typeof me.userName !== 'string') {
    return null;
  }
  if (!isAuthorizedPortalLoai(me.loai)) {
    return null;
  }
  return me;
}

/**
 * Central client-side portal user context: validated `/api/admin/auth/me` snapshot in memory,
 * persisted to `localStorage`, with optional in-memory prefill for hub → create-form flows
 * (not persisted — avoids putting session-scope ids in the URL).
 */
@Injectable({ providedIn: 'root' })
export class CurrentUserContextService {
  private readonly profile = signal<AdminAuthMe | null>(null);

  readonly donViId = computed(() => this.profile()?.donViId ?? null);
  readonly loai = computed(() => this.profile()?.loai ?? null);
  readonly userName = computed(() => this.profile()?.userName ?? '');
  readonly displayName = computed(() => this.profile()?.displayName ?? null);
  readonly email = computed(() => this.profile()?.email ?? null);
  readonly fullSystemScope = computed(() => this.profile()?.fullSystemScope ?? false);
  readonly portalRole = computed(() => mapLoaiToPortalRole(this.loai()));

  readonly isStorePortal = computed(() => this.portalRole() === 'STORE');

  private pendingStorePriceDonViId: number | null = null;
  private pendingStorePriceProductId: number | null = null;
  private pendingInventoryTxDonViId: number | null = null;
  private pendingInventoryTxProductId: number | null = null;

  constructor() {
    const me = this.readValidatedProfileFromLocalStorage();
    if (me) {
      this.profile.set(me);
    }
  }

  /** When session profile is missing but a Bearer token exists, rehydrate tab session from durable context. */
  tryHydrateSessionProfileFromPersisted(session: AuthSessionStorage): void {
    if (session.getPortalProfileJson()) {
      return;
    }
    const me = this.readValidatedProfileFromLocalStorage();
    if (!me) {
      return;
    }
    session.setPortalProfileJson(JSON.stringify(me));
  }

  /**
   * Updates in-memory context and persists to `localStorage`.
   * Call only for profiles that already passed portal `Loai` checks.
   */
  applyValidatedProfile(me: AdminAuthMe): void {
    if (!isAuthorizedPortalLoai(me.loai)) {
      this.clear();
      return;
    }
    this.profile.set(me);
    this.writeValidatedProfileToLocalStorage(me);
  }

  clear(): void {
    this.profile.set(null);
    this.clearLocalStorageDocument();
    this.clearPendingPrefills();
  }

  prepareStorePriceCreatePrefill(donViId: number | null | undefined, productId: number | null | undefined): void {
    this.pendingStorePriceDonViId =
      donViId !== null && donViId !== undefined && Number.isFinite(Number(donViId)) ? Number(donViId) : null;
    this.pendingStorePriceProductId =
      productId !== null && productId !== undefined && Number.isFinite(Number(productId)) ? Number(productId) : null;
  }

  consumeStorePriceCreatePrefill(): { donViId: number | null; productId: number | null } {
    const out = { donViId: this.pendingStorePriceDonViId, productId: this.pendingStorePriceProductId };
    this.pendingStorePriceDonViId = null;
    this.pendingStorePriceProductId = null;
    return out;
  }

  prepareInventoryTransactionCreatePrefill(
    donViId: number | null | undefined,
    productId: number | null | undefined,
  ): void {
    this.pendingInventoryTxDonViId =
      donViId !== null && donViId !== undefined && Number.isFinite(Number(donViId)) ? Number(donViId) : null;
    this.pendingInventoryTxProductId =
      productId !== null && productId !== undefined && Number.isFinite(Number(productId)) ? Number(productId) : null;
  }

  consumeInventoryTransactionCreatePrefill(): { donViId: number | null; productId: number | null } {
    const out = { donViId: this.pendingInventoryTxDonViId, productId: this.pendingInventoryTxProductId };
    this.pendingInventoryTxDonViId = null;
    this.pendingInventoryTxProductId = null;
    return out;
  }

  private readValidatedProfileFromLocalStorage(): AdminAuthMe | null {
    if (typeof localStorage === 'undefined') {
      return null;
    }
    const raw = localStorage.getItem(STORE_ADMIN_USER_CONTEXT_KEY)?.trim();
    if (!raw) {
      return null;
    }
    return parsePersistedUserContextJson(raw);
  }

  private writeValidatedProfileToLocalStorage(me: AdminAuthMe): void {
    if (typeof localStorage === 'undefined') {
      return;
    }
    const doc: AdminPortalUserContextPersistedV1 = {
      v: ADMIN_PORTAL_USER_CONTEXT_SCHEMA_VERSION,
      profile: me,
    };
    try {
      localStorage.setItem(STORE_ADMIN_USER_CONTEXT_KEY, JSON.stringify(doc));
    } catch {
      /* ignore quota / private mode */
    }
  }

  private clearLocalStorageDocument(): void {
    if (typeof localStorage === 'undefined') {
      return;
    }
    try {
      localStorage.removeItem(STORE_ADMIN_USER_CONTEXT_KEY);
    } catch {
      /* ignore */
    }
  }

  private clearPendingPrefills(): void {
    this.pendingStorePriceDonViId = null;
    this.pendingStorePriceProductId = null;
    this.pendingInventoryTxDonViId = null;
    this.pendingInventoryTxProductId = null;
  }
}
