import type { CurrentUserContextService } from '../../core/auth/current-user-context.service';

/**
 * STORE portal users operate only on their linked `donViId` (from `/api/admin/auth/me`).
 * Returns that id for form defaults / disabled store pickers; `null` for ADMIN and TRADER.
 */
export function retailPinnedDonViIdForStoreRole(ctx: CurrentUserContextService): number | null {
  if (!ctx.isStorePortal()) {
    return null;
  }
  const id = ctx.donViId();
  return typeof id === 'number' && Number.isFinite(id) ? id : null;
}
