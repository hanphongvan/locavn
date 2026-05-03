/** Mirrors backend `StoreAdminInventoryCurrentLineDto`. */
export interface StoreAdminInventoryCurrentLineDto {
  donViId: number;
  productId: number;
  currentQuantity: number;
  productCode: string;
  productName: string;
  unitId: number | null;
  unitMa: string | null;
  unitTen: string | null;
  /** Max transaction timestamp for this store + product aggregate. */
  lastTransactionDate: string;
}

export interface StoreAdminInventoryCurrentPageDto {
  items: StoreAdminInventoryCurrentLineDto[];
  totalCount: number;
  skip: number;
  take: number;
}

/** Query params for `GET /api/admin/inventories/current`. */
export interface StoreAdminInventoryCurrentListQuery {
  donViId?: number | null;
  productId?: number | null;
  skip?: number;
  take?: number;
}
