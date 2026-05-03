/** Mirrors backend `StoreAdminInventoryTransactionHeaderListItemDto`. */
export interface StoreAdminInventoryTransactionHeaderListItemDto {
  id: number;
  donViId: number;
  transactionType: number;
  transactionDate: string;
  note: string | null;
  lineCount: number;
  created: string;
  createdBy: string | null;
  modified: string;
  modifiedBy: string | null;
}

/** Mirrors backend `StoreAdminInventoryTransactionLineDto` (detail row from DB). */
export interface StoreAdminInventoryTransactionLineDto {
  id: number;
  headerId: number;
  productId: number;
  /** `DM_DonViTinh.Id` — đơn vị tính của dòng chi tiết. */
  unitId: number;
  /** `DM_DonViTinh.Ten` (read from list/latest procedures). */
  unitName?: string | null;
  quantity: number;
  amount: number | null;
  note: string | null;
}

/** Mirrors backend `StoreAdminInventoryTransactionBundleDto`. */
export interface StoreAdminInventoryTransactionBundleDto {
  id: number;
  donViId: number;
  transactionType: number;
  transactionDate: string;
  note: string | null;
  created: string;
  createdBy: string | null;
  modified: string;
  modifiedBy: string | null;
  details: StoreAdminInventoryTransactionLineDto[];
}

export interface StoreAdminInventoryTransactionListPageDto {
  items: StoreAdminInventoryTransactionHeaderListItemDto[];
  totalCount: number;
  skip: number;
  take: number;
}

/** One detail row in save payload (maps to `StationInventoryTransactionDetails`). */
export interface StoreAdminInventoryTransactionDetailRequest {
  productId: number;
  /** `DM_DonViTinh.Id` — bắt buộc khi `useProductDefaultUnit` là `false`. */
  unitId: number;
  /**
   * Khi `true`, API lưu `FuelProducts.UnitId` của mặt hàng (bỏ qua `unitId` gửi lên).
   * Đổi số lượng giữa đơn vị: dự phòng cho bản sau.
   */
  useProductDefaultUnit?: boolean;
  quantity: number;
  amount?: number | null;
  note?: string | null;
}

/** Mirrors backend `StoreAdminInventoryTransactionSaveRequest`. */
export interface StoreAdminInventoryTransactionSaveRequest {
  donViId: number;
  transactionType: number;
  transactionDate: string;
  note?: string | null;
  details: StoreAdminInventoryTransactionDetailRequest[];
}

/** Query params for `GET /api/admin/inventory-transactions`. */
export interface StoreAdminInventoryTransactionListQuery {
  donViId?: number | null;
  productId?: number | null;
  transactionType?: number | null;
  transactionDateFrom?: string | Date | null;
  transactionDateTo?: string | Date | null;
  skip?: number;
  take?: number;
}

/** Optional filters for `GET /api/admin/inventory-transactions/by-store/:donViId`. */
export interface StoreAdminInventoryTransactionByStoreQuery {
  productId?: number | null;
  transactionType?: number | null;
  transactionDateFrom?: string | Date | null;
  transactionDateTo?: string | Date | null;
}
