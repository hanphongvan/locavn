/** Query `GET /api/httm` — camelCase theo ASP.NET default. */
export interface HttmFacilitySearchQuery {
  q?: string | null;
  httmType?: string | null;
  provinceCode?: string | null;
  districtCode?: string | null;
  wardCode?: string | null;
  status?: string | null;
  areaMin?: number | null;
  areaMax?: number | null;
  stallMin?: number | null;
  stallMax?: number | null;
  yearFrom?: number | null;
  yearTo?: number | null;
  page?: number;
  pageSize?: number;
}

export interface HttmFacilityListItemDto {
  id: string;
  name: string;
  httmType: string;
  status: string;
  provinceCode: string;
  districtCode?: string | null;
  wardCode?: string | null;
  addressDetail?: string | null;
  landArea?: number | null;
  floorArea?: number | null;
  stallCount?: number | null;
  yearEstablished?: number | null;
  updatedAt: string;
}

export interface HttmFacilitySearchPageDto {
  totalCount: number;
  items: HttmFacilityListItemDto[];
}

export interface HttmFacilityDto {
  id: string;
  name: string;
  httmType: string;
  status: string;
  provinceCode: string;
  districtCode?: string | null;
  wardCode?: string | null;
  addressDetail?: string | null;
  lat?: number | null;
  lng?: number | null;
  gpsAccuracy?: string | null;
  landArea?: number | null;
  floorArea?: number | null;
  floors?: number | null;
  stallCount?: number | null;
  avgStallArea?: number | null;
  parkingSlots?: number | null;
  yearEstablished?: number | null;
  yearRenovated?: number | null;
  ownerName?: string | null;
  operatorName?: string | null;
  operatorUserId?: string | null;
  fillRate?: number | null;
  vendorCount?: number | null;
  avgRentPrice?: number | null;
  annualRevenue?: number | null;
  hasBackupPower: boolean;
  hasFireProtection: boolean;
  buildingQuality?: string | null;
  sourceSurveyId?: string | null;
  notes?: string | null;
  createdBy: string;
  updatedBy?: string | null;
  createdAt: string;
  updatedAt: string;
  isSensitiveVisible: boolean;
}

export interface HttmFacilityCreateRequest {
  name: string;
  httmType: string;
  status: string;
  provinceCode: string;
  districtCode?: string | null;
  wardCode?: string | null;
  addressDetail?: string | null;
  lat?: number | null;
  lng?: number | null;
  gpsAccuracy?: string | null;
  landArea?: number | null;
  floorArea?: number | null;
  floors?: number | null;
  stallCount?: number | null;
  avgStallArea?: number | null;
  parkingSlots?: number | null;
  yearEstablished?: number | null;
  yearRenovated?: number | null;
  ownerName?: string | null;
  operatorName?: string | null;
  operatorUserId?: string | null;
  fillRate?: number | null;
  vendorCount?: number | null;
  avgRentPrice?: number | null;
  annualRevenue?: number | null;
  hasBackupPower?: boolean | null;
  hasFireProtection?: boolean | null;
  buildingQuality?: string | null;
  sourceSurveyId?: string | null;
  notes?: string | null;
}

export type HttmFacilityUpdateRequest = Partial<HttmFacilityCreateRequest> & {
  clearLocation?: boolean;
};

export interface HttmFacilityLicenseDto {
  id: string;
  facilityId: string;
  licenseType: string;
  licenseNumber?: string | null;
  issuedDate?: string | null;
  expiryDate?: string | null;
  issuedBy?: string | null;
  fileUrl?: string | null;
  notes?: string | null;
  expiryAlert30d: boolean;
  createdAt: string;
}

export interface HttmFacilityLicenseUpsertRequest {
  id?: string | null;
  licenseType: string;
  licenseNumber?: string | null;
  issuedDate?: string | null;
  expiryDate?: string | null;
  issuedBy?: string | null;
  fileUrl?: string | null;
  notes?: string | null;
}

export interface HttmAuditLogDto {
  id: string;
  facilityId: string;
  action: string;
  changedFields?: string | null;
  performedBy: string;
  performedAt: string;
  ipAddress?: string | null;
  userAgent?: string | null;
}

export interface HttmAuditLogsPageDto {
  totalCount: number;
  items: HttmAuditLogDto[];
}

export interface HttmCatalogItemDto {
  id: string;
  type: string;
  code: string;
  name: string;
  nameEn?: string | null;
  parentCode?: string | null;
  sortOrder: number;
  isActive: boolean;
  metadata?: string | null;
}

export interface ProvinceOptionDto {
  id: number;
  code: string;
  name: string;
  sapXep?: number | null;
  vungMien?: number | null;
}

export interface DistrictOptionDto {
  districtId: number;
  districtCode: string;
  districtName?: string | null;
}

export interface WardOptionDto {
  code: string;
  name: string;
  tinhId?: number | null;
  quanHuyenId?: number | null;
}
