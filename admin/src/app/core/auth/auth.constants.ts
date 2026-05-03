/** sessionStorage key for OAuth access_token (resource-owner grant). */
export const STORE_ADMIN_ACCESS_TOKEN_KEY = 'httm.storeAdmin.accessToken';

/** sessionStorage key for cached `GET /api/admin/auth/me` payload (real backend only). */
export const STORE_ADMIN_PORTAL_PROFILE_KEY = 'httm.storeAdmin.portalProfile';

/** localStorage key for validated portal user context (profile snapshot from `/api/admin/auth/me`). */
export const STORE_ADMIN_USER_CONTEXT_KEY = 'httm.storeAdmin.userContext';
