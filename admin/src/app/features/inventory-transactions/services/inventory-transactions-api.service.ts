import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';

import { ApiHttpService } from '../../../core/http/api-http.service';
import { handleApiError } from '../../../core/http/api-request-error';
import { toHttpParams } from '../../../core/http/http-params.util';
import type {
  StoreAdminInventoryTransactionBundleDto,
  StoreAdminInventoryTransactionByStoreQuery,
  StoreAdminInventoryTransactionHeaderListItemDto,
  StoreAdminInventoryTransactionListPageDto,
  StoreAdminInventoryTransactionListQuery,
  StoreAdminInventoryTransactionSaveRequest,
} from '../models/store-admin-inventory-transaction.models';

const basePath = '/api/admin/inventory-transactions';

@Injectable({ providedIn: 'root' })
export class InventoryTransactionsApiService {
  private readonly api = inject(ApiHttpService);

  list(query: StoreAdminInventoryTransactionListQuery = {}): Observable<StoreAdminInventoryTransactionListPageDto> {
    return this.api
      .get<StoreAdminInventoryTransactionListPageDto>(basePath, toHttpParams(query))
      .pipe(handleApiError<StoreAdminInventoryTransactionListPageDto>());
  }

  listByStore(
    donViId: number,
    query: StoreAdminInventoryTransactionByStoreQuery = {},
  ): Observable<StoreAdminInventoryTransactionHeaderListItemDto[]> {
    return this.api
      .get<StoreAdminInventoryTransactionHeaderListItemDto[]>(
        `${basePath}/by-store/${donViId}`,
        toHttpParams(query),
      )
      .pipe(handleApiError<StoreAdminInventoryTransactionHeaderListItemDto[]>());
  }

  getById(id: number): Observable<StoreAdminInventoryTransactionBundleDto> {
    return this.api
      .get<StoreAdminInventoryTransactionBundleDto>(`${basePath}/${id}`)
      .pipe(handleApiError<StoreAdminInventoryTransactionBundleDto>());
  }

  /** Latest header + details for a store (`GET .../latest?donViId=`). */
  getLatest(donViId: number): Observable<StoreAdminInventoryTransactionBundleDto> {
    return this.api
      .get<StoreAdminInventoryTransactionBundleDto>(`${basePath}/latest`, toHttpParams({ donViId }))
      .pipe(handleApiError<StoreAdminInventoryTransactionBundleDto>());
  }

  create(body: StoreAdminInventoryTransactionSaveRequest): Observable<StoreAdminInventoryTransactionBundleDto> {
    return this.api
      .post<StoreAdminInventoryTransactionBundleDto>(basePath, body)
      .pipe(handleApiError<StoreAdminInventoryTransactionBundleDto>());
  }

  update(
    id: number,
    body: StoreAdminInventoryTransactionSaveRequest,
  ): Observable<StoreAdminInventoryTransactionBundleDto> {
    return this.api
      .put<StoreAdminInventoryTransactionBundleDto>(`${basePath}/${id}`, body)
      .pipe(handleApiError<StoreAdminInventoryTransactionBundleDto>());
  }
}
