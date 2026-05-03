/** Mirrors backend `StoreAdminFuelProductListItemDto`. */
export interface StoreAdminFuelProductListItemDto {
  id: number;
  code: string;
  name: string;
  parentId: number | null;
  unitId: number | null;
  isActive: boolean;
  sortOrder: number | null;
  description: string | null;
}

/** Mirrors backend `StoreAdminFuelProductDetailDto`. */
export interface StoreAdminFuelProductDetailDto {
  id: number;
  code: string;
  name: string;
  parentId: number | null;
  unitId: number | null;
  isActive: boolean;
  sortOrder: number | null;
  description: string | null;
  created: string;
  createdBy: string | null;
  modified: string;
  modifiedBy: string | null;
}

/** Mirrors backend `StoreAdminFuelProductTreeNodeDto` (recursive). */
export interface StoreAdminFuelProductTreeNodeDto {
  id: number;
  code: string;
  name: string;
  parentId: number | null;
  unitId: number | null;
  isActive: boolean;
  sortOrder: number | null;
  description: string | null;
  children: StoreAdminFuelProductTreeNodeDto[];
}

export interface StoreAdminFuelProductListPageDto {
  items: StoreAdminFuelProductListItemDto[];
  totalCount: number;
  skip: number;
  take: number;
}

/** Mirrors backend `StoreAdminFuelProductUpsertRequest`. */
export interface StoreAdminFuelProductUpsertRequest {
  code: string;
  name: string;
  parentId?: number | null;
  unitId?: number | null;
  isActive: boolean;
  sortOrder?: number | null;
  description?: string | null;
}

/** Query params for `GET /api/admin/fuel-products`. */
export interface StoreAdminFuelProductListQuery {
  /** When set, restricts the list and `totalCount` to active or inactive rows only. */
  isActive?: boolean | null;
  skip?: number;
  take?: number;
}
