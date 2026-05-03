/** Mirrors backend `StoreAdminStorePriceListItemDto`. */
export interface StoreAdminStorePriceListItemDto {
  id: number;
  donViId: number;
  productId: number;
  price: number;
  unitId: number | null;
  effectiveDate: string;
  isCurrent: boolean;
  note: string | null;
  stationPricesId: number;
}

/** Mirrors backend `StoreAdminStorePriceDetailDto`. */
export interface StoreAdminStorePriceDetailDto {
  id: number;
  donViId: number;
  productId: number;
  price: number;
  unitId: number | null;
  effectiveDate: string;
  isCurrent: boolean;
  note: string | null;
  stationPricesId: number;
  created: string;
  createdBy: string | null;
  modified: string;
  modifiedBy: string | null;
}

export interface StoreAdminStorePriceListPageDto {
  items: StoreAdminStorePriceListItemDto[];
  totalCount: number;
  skip: number;
  take: number;
}

/** Mirrors backend `StoreAdminStorePriceUpsertRequest`. */
export interface StoreAdminStorePriceUpsertRequest {
  donViId: number;
  productId: number;
  price: number;
  unitId?: number | null;
  effectiveDate: string;
  isCurrent: boolean;
  note?: string | null;
}

/** Query params for `GET /api/admin/store-prices`. */
export interface StoreAdminStorePriceListQuery {
  donViId?: number | null;
  productId?: number | null;
  isCurrent?: boolean | null;
  skip?: number;
  take?: number;
}

/** Row from `StationPrices` (danh sách bảng giá). */
export interface StoreAdminStationPriceBoardListItemDto {
  id: number;
  donViId: number;
  activeDate: string;
  isActive: boolean;
  created: string;
  createdBy: string | null;
  modified: string;
  modifiedBy: string | null;
}

export interface StoreAdminStationPriceBoardDetailDto {
  id: number;
  donViId: number;
  activeDate: string;
  isActive: boolean;
  created: string;
  createdBy: string | null;
  modified: string;
  modifiedBy: string | null;
}

export interface StoreAdminStationPriceBoardListPageDto {
  items: StoreAdminStationPriceBoardListItemDto[];
  totalCount: number;
  skip: number;
  take: number;
}

export interface StoreAdminStationPriceBoardUpdateRequest {
  activeDate: string;
  isActive: boolean;
}

/** Query for `GET /api/admin/store-prices/price-boards`. */
export interface StoreAdminStationPriceBoardListQuery {
  donViId?: number | null;
  isActive?: boolean | null;
  skip?: number;
  take?: number;
}

export interface StoreAdminStationPriceBoardEditorLineDto {
  lineId: number;
  productId: number;
  price: number;
  unitId: number | null;
  note: string | null;
}

export interface StoreAdminStationPriceBoardEditorResponseDto {
  stationPricesId: number;
  donViId: number;
  activeDate: string;
  isActive: boolean;
  lines: StoreAdminStationPriceBoardEditorLineDto[];
}

export interface StoreAdminStationPriceBoardEditorSaveRow {
  id: number;
  productId: number;
  price: number;
  unitId?: number | null;
  note?: string | null;
}

export interface StoreAdminStationPriceBoardEditorSaveRequest {
  effectiveDate: string;
  isCurrent: boolean;
  rows: StoreAdminStationPriceBoardEditorSaveRow[];
}

/** Mirrors backend `StoreAdminDonViTinhLookupDto` (`DM_DonViTinh`). */
export interface StoreAdminDonViTinhLookupDto {
  id: number;
  ma: string | null;
  ten: string | null;
}

/** Mirrors backend `StoreAdminFuelProductLookupDto`. */
export interface StoreAdminFuelProductLookupDto {
  id: number;
  code: string;
  name: string;
  unitId: number | null;
  sortOrder: number | null;
}

/** Mirrors backend `StoreAdminStorePriceLatestSubmissionRowDto`. */
export interface StoreAdminStorePriceLatestSubmissionRowDto {
  productId: number;
  price: number;
  unitId: number | null;
  note: string | null;
  effectiveDate: string;
  isCurrent: boolean;
}

export interface StoreAdminStorePriceBatchRowRequest {
  productId: number;
  price: number;
  unitId?: number | null;
  note?: string | null;
}

export interface StoreAdminStorePriceBatchCreateRequest {
  donViId: number;
  effectiveDate: string;
  isCurrent: boolean;
  rows: StoreAdminStorePriceBatchRowRequest[];
}

export interface StoreAdminStorePriceBatchCreateResponseDto {
  stationPricesId: number;
  createdIds: number[];
  rowCount: number;
}

/** Query for `GET /api/admin/store-prices/products`. */
export interface StoreAdminStorePriceProductsQuery {
  search?: string | null;
  take?: number;
  defaultsOnly?: boolean;
}
