import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';

import { ApiHttpService } from '../../../core/http/api-http.service';
import { handleApiError } from '../../../core/http/api-request-error';

/** Mirrors backend `ProvinceResponseDto` (`GET /api/geography/provinces`). */
export interface GeographyProvinceDto {
  readonly id: number;
  readonly code: string;
  readonly name: string;
  readonly sapXep: number | null;
  readonly vungMien: number | null;
}

@Injectable({ providedIn: 'root' })
export class GeographyApiService {
  private readonly api = inject(ApiHttpService);

  listProvinces(): Observable<GeographyProvinceDto[]> {
    return this.api.get<GeographyProvinceDto[]>('/api/geography/provinces').pipe(handleApiError<GeographyProvinceDto[]>());
  }
}
