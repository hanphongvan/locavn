/** `GET /api/admin/store-auth/me` — matches `StoreAdminMeDto` on the API (camelCase JSON). */
export interface StoreAdminMe {
  userName: string;
  displayName: string | null;
  email: string | null;
  /** `0` = built-in root user `system` (no retail store). */
  donViId: number;
  storeName: string;
  isStoreAdmin: boolean;
}
