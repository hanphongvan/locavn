/** DTO khớp với backend `Features/Httm/Import/Contracts/HttmImportDtos.cs`. */

export interface HttmImportRowDto {
  rowNumber: number;
  name: string | null;
  httmType: string | null;
  status: string | null;
  provinceCode: string | null;
  districtCode: string | null;
  wardCode: string | null;
  addressDetail: string | null;
  lat: number | null;
  lng: number | null;
  gpsAccuracy: string | null;
  landArea: number | null;
  floorArea: number | null;
  floors: number | null;
  stallCount: number | null;
  avgStallArea: number | null;
  parkingSlots: number | null;
  yearEstablished: number | null;
  yearRenovated: number | null;
  ownerName: string | null;
  operatorName: string | null;
  fillRate: number | null;
  vendorCount: number | null;
  avgRentPrice: number | null;
  annualRevenue: number | null;
  hasBackupPower: boolean | null;
  hasFireProtection: boolean | null;
  buildingQuality: string | null;
  notes: string | null;
}

export interface HttmImportRowError {
  rowNumber: number;
  column: string | null;
  message: string;
}

export interface HttmImportValidateResponse {
  sessionToken: string;
  totalRows: number;
  validCount: number;
  errorCount: number;
  skippedDuplicateCount: number;
  validRowsPreview: HttmImportRowDto[];
  errors: HttmImportRowError[];
}

export interface HttmImportConfirmRequest {
  sessionToken: string;
  skipErrors: boolean;
}

export interface HttmImportConfirmResponse {
  created: number;
  skippedDuplicates: number;
  skippedErrors: number;
  perRowErrors: HttmImportRowError[];
}
