/** Query for `GET /api/admin/inventory-map`. */
export type InventoryMapGroupCode = 'XANG' | 'DAU';

export interface StoreAdminInventoryMapListQuery {
  groupCode: InventoryMapGroupCode;
}

/** Row from `StoreAdminInventoryMapStationDto` (camelCase JSON). */
export interface StoreAdminInventoryMapStationDto {
  stationId: number;
  stationCode: string;
  stationName: string;
  address: string | null;
  latitude: number | null;
  longitude: number | null;
  currentQuantity: number;
  stockStatus: string;
}

/** `StoreAdminInventoryMapResponseDto`. */
export interface StoreAdminInventoryMapResponseDto {
  stations: StoreAdminInventoryMapStationDto[];
}
