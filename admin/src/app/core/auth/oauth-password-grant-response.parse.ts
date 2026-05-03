import type { OAuthPasswordGrantTokenResponse } from './models/oauth-password-grant-token-response.model';

/** Returns trimmed `access_token` when the body shape is usable; otherwise `null`. */
export function extractAccessTokenFromPasswordGrant(
  body: OAuthPasswordGrantTokenResponse | null | undefined,
): string | null {
  if (!body || typeof body !== 'object') {
    return null;
  }
  const raw = body.access_token;
  if (typeof raw !== 'string') {
    return null;
  }
  const t = raw.trim();
  return t.length > 0 ? t : null;
}

/**
 * Parses optional `loai` from the token response (string digits from `AuthenticationProperties`).
 * Returns `null` when missing or not a finite integer.
 */
export function extractLoaiFromPasswordGrant(
  body: OAuthPasswordGrantTokenResponse | null | undefined,
): number | null {
  if (!body || typeof body !== 'object') {
    return null;
  }
  const raw = body.loai;
  if (raw === undefined || raw === null) {
    return null;
  }
  const s = String(raw).trim();
  if (!s) {
    return null;
  }
  const n = Number(s);
  return Number.isFinite(n) ? n : null;
}

/** Optional `DonViId` from `id_don_vi` on the token response. */
export function extractDonViIdFromPasswordGrant(
  body: OAuthPasswordGrantTokenResponse | null | undefined,
): number | null {
  if (!body || typeof body !== 'object') {
    return null;
  }
  const raw = body.id_don_vi;
  if (raw === undefined || raw === null) {
    return null;
  }
  const s = String(raw).trim();
  if (!s) {
    return null;
  }
  const n = Number(s);
  return Number.isFinite(n) ? n : null;
}
