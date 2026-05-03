import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';

import { ApiHttpService } from '../../../core/http/api-http.service';
import { handleApiError } from '../../../core/http/api-request-error';
import { toHttpParams } from '../../../core/http/http-params.util';
import type {
  StoreAdminFuelProductDetailDto,
  StoreAdminFuelProductListPageDto,
  StoreAdminFuelProductListQuery,
  StoreAdminFuelProductTreeNodeDto,
  StoreAdminFuelProductUpsertRequest,
} from '../models/store-admin-fuel-product.models';

const basePath = '/api/admin/fuel-products';

@Injectable({ providedIn: 'root' })
export class FuelProductsApiService {
  private readonly api = inject(ApiHttpService);

  list(query: StoreAdminFuelProductListQuery = {}): Observable<StoreAdminFuelProductListPageDto> {
    return this.api.get<StoreAdminFuelProductListPageDto>(basePath, toHttpParams(query)).pipe(handleApiError<StoreAdminFuelProductListPageDto>());
  }

  getTree(): Observable<StoreAdminFuelProductTreeNodeDto[]> {
    return this.api.get<StoreAdminFuelProductTreeNodeDto[]>(`${basePath}/tree`).pipe(handleApiError<StoreAdminFuelProductTreeNodeDto[]>());
  }

  getById(id: number): Observable<StoreAdminFuelProductDetailDto> {
    return this.api.get<StoreAdminFuelProductDetailDto>(`${basePath}/${id}`).pipe(handleApiError<StoreAdminFuelProductDetailDto>());
  }

  create(body: StoreAdminFuelProductUpsertRequest): Observable<StoreAdminFuelProductDetailDto> {
    return this.api.post<StoreAdminFuelProductDetailDto>(basePath, body).pipe(handleApiError<StoreAdminFuelProductDetailDto>());
  }

  update(id: number, body: StoreAdminFuelProductUpsertRequest): Observable<StoreAdminFuelProductDetailDto> {
    return this.api.put<StoreAdminFuelProductDetailDto>(`${basePath}/${id}`, body).pipe(handleApiError<StoreAdminFuelProductDetailDto>());
  }
}
