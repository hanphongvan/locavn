import type { AdminAuthMe } from './admin-auth-me.model';

/** Persisted document schema version (increment when shape changes). */
export const ADMIN_PORTAL_USER_CONTEXT_SCHEMA_VERSION = 1 as const;

/**
 * Durable portal user context persisted to `localStorage` (API-shaped profile).
 * Keeps a single JSON blob so restore logic stays in one place.
 */
export interface AdminPortalUserContextPersistedV1 {
  readonly v: typeof ADMIN_PORTAL_USER_CONTEXT_SCHEMA_VERSION;
  readonly profile: AdminAuthMe;
}
