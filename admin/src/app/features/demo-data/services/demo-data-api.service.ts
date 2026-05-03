import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';

import { ApiHttpService } from '../../../core/http/api-http.service';
import { handleApiError } from '../../../core/http/api-request-error';

const basePath = '/api/admin/demo-data';

/** Mirrors backend `DemoDataCommandRequest`. */
export interface DemoDataCommandBody {
  readonly tinh: number;
  readonly days: number;
  readonly clearOldData: boolean;
}

/** Mirrors backend `DemoDataOperationResponse`. */
export interface DemoDataOperationResult {
  readonly success: boolean;
  readonly message: string | null;
  readonly utcCompleted: string;
}

@Injectable({ providedIn: 'root' })
export class DemoDataApiService {
  private readonly api = inject(ApiHttpService);

  clear(body: DemoDataCommandBody): Observable<DemoDataOperationResult> {
    return this.api
      .post<DemoDataOperationResult>(`${basePath}/clear`, body)
      .pipe(handleApiError<DemoDataOperationResult>());
  }

  generatePrices(body: DemoDataCommandBody): Observable<DemoDataOperationResult> {
    return this.api
      .post<DemoDataOperationResult>(`${basePath}/generate-prices`, body)
      .pipe(handleApiError<DemoDataOperationResult>());
  }

  generateInventory(body: DemoDataCommandBody): Observable<DemoDataOperationResult> {
    return this.api
      .post<DemoDataOperationResult>(`${basePath}/generate-inventory`, body)
      .pipe(handleApiError<DemoDataOperationResult>());
  }

  generateAll(body: DemoDataCommandBody): Observable<DemoDataOperationResult> {
    return this.api
      .post<DemoDataOperationResult>(`${basePath}/generate-all`, body)
      .pipe(handleApiError<DemoDataOperationResult>());
  }
}
