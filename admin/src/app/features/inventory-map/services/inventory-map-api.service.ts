import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';

import { ApiHttpService } from '../../../core/http/api-http.service';
import { handleApiError } from '../../../core/http/api-request-error';
import { toHttpParams } from '../../../core/http/http-params.util';
import type {
  StoreAdminInventoryMapListQuery,
  StoreAdminInventoryMapResponseDto,
} from '../models/store-admin-inventory-map.models';

const basePath = '/api/admin/inventory-map';

@Injectable({ providedIn: 'root' })
export class InventoryMapApiService {
  private readonly api = inject(ApiHttpService);

  list(query: StoreAdminInventoryMapListQuery): Observable<StoreAdminInventoryMapResponseDto> {
    return this.api
      .get<StoreAdminInventoryMapResponseDto>(basePath, toHttpParams(query))
      .pipe(handleApiError<StoreAdminInventoryMapResponseDto>());
  }
}
