/** GeoJSON từ `GET /api/httm/map-data` (RFC 7946, tọa độ [lng, lat]). */

export interface HttmMapPointGeometryDto {
  type: 'Point';
  coordinates: [number, number];
}

export interface HttmMapFeaturePropertiesDto {
  name: string;
  httmType: string;
  status: string;
  provinceCode: string;
  addressDetail?: string | null;
  floorArea?: number | null;
  stallCount?: number | null;
}

export interface HttmMapFeatureDto {
  type: 'Feature';
  id: string;
  geometry: HttmMapPointGeometryDto;
  properties: HttmMapFeaturePropertiesDto;
}

export interface HttmMapFeatureCollectionResponse {
  type: 'FeatureCollection';
  features: HttmMapFeatureDto[];
}
