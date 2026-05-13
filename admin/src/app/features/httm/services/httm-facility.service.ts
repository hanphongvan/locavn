import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';

import { ApiHttpService } from '../../../core/http/api-http.service';
import { handleApiError } from '../../../core/http/api-request-error';
import { API_BASE_URL } from '../../../core/tokens/api-base-url.token';
import type {
  HttmAuditLogsPageDto,
  HttmFacilityCreateRequest,
  HttmFacilityDto,
  HttmFacilityLicenseDto,
  HttmFacilityLicenseUpsertRequest,
  HttmFacilitySearchPageDto,
  HttmFacilitySearchQuery,
  HttmFacilityUpdateRequest,
} from '../models/httm-facility.model';
import type { HttmMapFeatureCollectionResponse } from '../models/httm-map.model';

function appendParams(params: HttpParams, key: string, value: string | number | null | undefined): HttpParams {
  if (value === null || value === undefined || value === '') {
    return params;
  }
  return params.set(key, String(value));
}

function searchToParams(query: HttmFacilitySearchQuery): HttpParams {
  let p = new HttpParams();
  p = appendParams(p, 'q', query.q ?? undefined);
  p = appendParams(p, 'httmType', query.httmType ?? undefined);
  p = appendParams(p, 'provinceCode', query.provinceCode ?? undefined);
  p = appendParams(p, 'districtCode', query.districtCode ?? undefined);
  p = appendParams(p, 'wardCode', query.wardCode ?? undefined);
  p = appendParams(p, 'status', query.status ?? undefined);
  p = appendParams(p, 'areaMin', query.areaMin ?? undefined);
  p = appendParams(p, 'areaMax', query.areaMax ?? undefined);
  p = appendParams(p, 'stallMin', query.stallMin ?? undefined);
  p = appendParams(p, 'stallMax', query.stallMax ?? undefined);
  p = appendParams(p, 'yearFrom', query.yearFrom ?? undefined);
  p = appendParams(p, 'yearTo', query.yearTo ?? undefined);
  p = appendParams(p, 'page', query.page ?? 1);
  p = appendParams(p, 'pageSize', query.pageSize ?? 20);
  return p;
}

@Injectable({ providedIn: 'root' })
export class HttmFacilityService {
  private readonly api = inject(ApiHttpService);
  private readonly rawHttp = inject(HttpClient);
  private readonly baseUrl = inject(API_BASE_URL).replace(/\/$/, '');

  search(query: HttmFacilitySearchQuery) {
    return this.api.get<HttmFacilitySearchPageDto>('/api/httm', searchToParams(query)).pipe(handleApiError());
  }

  getById(id: string) {
    return this.api.get<HttmFacilityDto>(`/api/httm/${id}`).pipe(handleApiError());
  }

  create(body: HttmFacilityCreateRequest) {
    return this.api.post<{ id: string }>('/api/httm', body).pipe(handleApiError());
  }

  put(id: string, body: HttmFacilityCreateRequest) {
    return this.api.put<void>(`/api/httm/${id}`, body).pipe(handleApiError());
  }

  patch(id: string, body: HttmFacilityUpdateRequest) {
    return this.api.patch<void>(`/api/httm/${id}`, body).pipe(handleApiError());
  }

  delete(id: string) {
    return this.api.delete<void>(`/api/httm/${id}`).pipe(handleApiError());
  }

  createFromApprovedSurvey(surveyId: string) {
    return this.api.post<{ id: string }>(`/api/httm/from-survey/${surveyId}`, {}).pipe(handleApiError());
  }

  getMapData(args: {
    west: number;
    south: number;
    east: number;
    north: number;
    types?: string | null;
    provinceCode?: string | null;
    maxRows?: number | null;
  }) {
    let p = new HttpParams()
      .set('west', String(args.west))
      .set('south', String(args.south))
      .set('east', String(args.east))
      .set('north', String(args.north));
    p = appendParams(p, 'types', args.types ?? undefined);
    p = appendParams(p, 'provinceCode', args.provinceCode ?? undefined);
    p = appendParams(p, 'maxRows', args.maxRows ?? undefined);
    return this.api.get<HttmMapFeatureCollectionResponse>('/api/httm/map-data', p).pipe(handleApiError());
  }

  getAuditLogs(facilityId: string, page = 1, pageSize = 20) {
    const p = new HttpParams().set('page', String(page)).set('pageSize', String(pageSize));
    return this.api.get<HttmAuditLogsPageDto>(`/api/httm/${facilityId}/audit-logs`, p).pipe(handleApiError());
  }

  listLicenses(facilityId: string) {
    return this.api.get<HttmFacilityLicenseDto[]>(`/api/httm/${facilityId}/licenses`).pipe(handleApiError());
  }

  upsertLicense(facilityId: string, body: HttmFacilityLicenseUpsertRequest) {
    return this.api.post<{ id: string }>(`/api/httm/${facilityId}/licenses`, body).pipe(handleApiError());
  }

  deleteLicense(facilityId: string, licenseId: string) {
    return this.api.delete<void>(`/api/httm/${facilityId}/licenses/${licenseId}`).pipe(handleApiError());
  }

  uploadImage(
    facilityId: string,
    file: File,
    imageType: string,
    caption?: string | null,
    takenDate?: string | null,
    sortOrder = 0,
  ) {
    const fd = new FormData();
    fd.append('file', file);
    fd.append('imageType', imageType);
    if (caption) {
      fd.append('caption', caption);
    }
    if (takenDate) {
      fd.append('takenDate', takenDate);
    }
    fd.append('sortOrder', String(sortOrder));
    const url = `${this.baseUrl}/api/httm/${facilityId}/images`;
    return this.rawHttp.post<{ id: string }>(url, fd).pipe(handleApiError());
  }

  deleteImage(facilityId: string, imageId: string) {
    return this.api.delete<void>(`/api/httm/${facilityId}/images/${imageId}`).pipe(handleApiError());
  }
}
