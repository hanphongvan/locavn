import { HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';

import { ApiHttpService } from '../../../core/http/api-http.service';
import { handleApiError } from '../../../core/http/api-request-error';
import type { HttmCatalogItemDto, DistrictOptionDto, ProvinceOptionDto, WardOptionDto } from '../models/httm-facility.model';

@Injectable({ providedIn: 'root' })
export class HttmCatalogService {
  private readonly api = inject(ApiHttpService);

  getByType(type: string, activeOnly = true) {
    const p = new HttpParams().set('activeOnly', String(activeOnly));
    return this.api.get<HttmCatalogItemDto[]>(`/api/catalogs/${encodeURIComponent(type)}`, p).pipe(handleApiError());
  }

  provinces() {
    return this.api.get<ProvinceOptionDto[]>('/api/catalogs/provinces').pipe(handleApiError());
  }

  districts(provinceCode: string) {
    const p = new HttpParams().set('provinceCode', provinceCode);
    return this.api.get<DistrictOptionDto[]>('/api/catalogs/districts', p).pipe(handleApiError());
  }

  wards(districtCode: string) {
    const p = new HttpParams().set('districtCode', districtCode);
    return this.api.get<WardOptionDto[]>('/api/catalogs/wards', p).pipe(handleApiError());
  }
}
