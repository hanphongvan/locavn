/**
 * JSON body from `POST /api/oauth/token` (resource-owner grant).
 * Matches backend: JWT fields + merged `AuthenticationProperties` (dictionary keys as issued by the API).
 */
export interface OAuthPasswordGrantTokenResponse {
  access_token?: string;
  token_type?: string;
  expires_in?: number;
  /** ISO 8601 from legacy-style ticket properties when present. */
  '.issued'?: string;
  '.expires'?: string;
  userName?: string;
  displayName?: string;
  /** Stringified `AspNetUsers.Loai` when set (same semantics as JWT `Loai` claim). */
  loai?: string;
  id_don_vi?: string;
  ten_don_vi?: string;
  isStoreAdmin?: string;
}
