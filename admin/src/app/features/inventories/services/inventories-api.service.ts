import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';

import { ApiHttpService } from '../../../core/http/api-http.service';
import { handleApiError } from '../../../core/http/api-request-error';
import { toHttpParams } from '../../../core/http/http-params.util';
import type {
  StoreAdminInventoryCurrentLineDto,
  StoreAdminInventoryCurrentListQuery,
  StoreAdminInventoryCurrentPageDto,
} from '../models/store-admin-inventory-current.models';

const basePath = '/api/admin/inventories';

@Injectable({ providedIn: 'root' })
export class InventoriesApiService {
  private readonly api = inject(ApiHttpService);

  listCurrent(query: StoreAdminInventoryCurrentListQuery = {}): Observable<StoreAdminInventoryCurrentPageDto> {
    return this.api
      .get<StoreAdminInventoryCurrentPageDto>(`${basePath}/current`, toHttpParams(query))
      .pipe(handleApiError<StoreAdminInventoryCurrentPageDto>());
  }

  listCurrentByStore(donViId: number): Observable<StoreAdminInventoryCurrentLineDto[]> {
    return this.api
      .get<StoreAdminInventoryCurrentLineDto[]>(`${basePath}/current/by-store/${donViId}`)
      .pipe(handleApiError<StoreAdminInventoryCurrentLineDto[]>());
  }
}
