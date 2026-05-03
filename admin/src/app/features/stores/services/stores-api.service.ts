import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';

import { ApiHttpService } from '../../../core/http/api-http.service';
import { handleApiError } from '../../../core/http/api-request-error';
import { toHttpParams } from '../../../core/http/http-params.util';
import type {
  StoreAdminStoreDto,
  StoreAdminStoreListPageDto,
  StoreAdminStoreListQuery,
  StoreAdminStoreUpsertRequest,
} from '../models/store-admin-store.models';

const basePath = '/api/admin/stores';

@Injectable({ providedIn: 'root' })
export class StoresApiService {
  private readonly api = inject(ApiHttpService);

  list(query: StoreAdminStoreListQuery = {}): Observable<StoreAdminStoreListPageDto> {
    return this.api.get<StoreAdminStoreListPageDto>(basePath, toHttpParams(query)).pipe(handleApiError<StoreAdminStoreListPageDto>());
  }

  getById(id: number): Observable<StoreAdminStoreDto> {
    return this.api.get<StoreAdminStoreDto>(`${basePath}/${id}`).pipe(handleApiError<StoreAdminStoreDto>());
  }

  create(body: StoreAdminStoreUpsertRequest): Observable<StoreAdminStoreDto> {
    return this.api.post<StoreAdminStoreDto>(basePath, body).pipe(handleApiError<StoreAdminStoreDto>());
  }

  update(id: number, body: StoreAdminStoreUpsertRequest): Observable<StoreAdminStoreDto> {
    return this.api.put<StoreAdminStoreDto>(`${basePath}/${id}`, body).pipe(handleApiError<StoreAdminStoreDto>());
  }
}
