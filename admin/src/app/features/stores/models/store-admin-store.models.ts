/** Mirrors backend `StoreAdminStoreDto` (camelCase JSON). `TimeOnly` fields are ISO-like time strings. */
export interface StoreAdminStoreDto {
  id: number;
  ma: string;
  ten: string;
  dienThoai: string | null;
  diaChi: string | null;
  email: string | null;
  trangThai: boolean | null;
  tinh: number | null;
  xa: number | null;
  diaChiChiTiet: string | null;
  viDo: number | null;
  kinhDo: number | null;
  openTime: string | null;
  closeTime: string | null;
}

export interface StoreAdminStoreListPageDto {
  items: StoreAdminStoreDto[];
  totalCount: number;
  skip: number;
  take: number;
}

/** Mirrors backend `StoreAdminStoreUpsertRequest`. */
export interface StoreAdminStoreUpsertRequest {
  ma: string;
  ten: string;
  dienThoai?: string | null;
  diaChi?: string | null;
  email?: string | null;
  trangThai?: boolean | null;
  tinh?: number | null;
  xa?: number | null;
  diaChiChiTiet?: string | null;
  viDo?: number | null;
  kinhDo?: number | null;
  openTime?: string | null;
  closeTime?: string | null;
}

/** Query params for `GET /api/admin/stores`. */
export interface StoreAdminStoreListQuery {
  ma?: string | null;
  ten?: string | null;
  tinh?: number | null;
  trangThai?: boolean | null;
  skip?: number;
  take?: number;
}
