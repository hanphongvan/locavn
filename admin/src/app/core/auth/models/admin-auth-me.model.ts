/** `GET /api/admin/auth/me` — matches `AdminAuthMeDto` (camelCase JSON). */
export interface AdminAuthMeOrganization {
  id: number;
  ma: string;
  ten: string;
  capDonViId: number;
  capTrenId: number | null;
  phanLoaiId: number | null;
  loaiHinh: number | null;
  isPetrolRetailStore: boolean;
}

export interface AdminAuthMe {
  userName: string;
  displayName: string | null;
  email: string | null;
  donViId: number | null;
  /** Authoritative for this SPA RBAC: derive portal role only from this field (see `portal-loai-role.ts`), not from `role` alone. */
  loai: number | null;
  /** From backend mapping of `loai`: ADMIN | TRADER | STORE, or null if unknown. */
  role: string | null;
  fullSystemScope: boolean;
  organization: AdminAuthMeOrganization | null;
}
