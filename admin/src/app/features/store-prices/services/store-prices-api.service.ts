import { HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';

import { ApiHttpService } from '../../../core/http/api-http.service';
import { handleApiError } from '../../../core/http/api-request-error';
import { toHttpParams } from '../../../core/http/http-params.util';
import type {
  StoreAdminDonViTinhLookupDto,
  StoreAdminFuelProductLookupDto,
  StoreAdminStationPriceBoardDetailDto,
  StoreAdminStationPriceBoardEditorResponseDto,
  StoreAdminStationPriceBoardEditorSaveRequest,
  StoreAdminStationPriceBoardListPageDto,
  StoreAdminStationPriceBoardListQuery,
  StoreAdminStationPriceBoardUpdateRequest,
  StoreAdminStorePriceBatchCreateRequest,
  StoreAdminStorePriceBatchCreateResponseDto,
  StoreAdminStorePriceDetailDto,
  StoreAdminStorePriceLatestSubmissionRowDto,
  StoreAdminStorePriceListItemDto,
  StoreAdminStorePriceListPageDto,
  StoreAdminStorePriceListQuery,
  StoreAdminStorePriceProductsQuery,
  StoreAdminStorePriceUpsertRequest,
} from '../models/store-admin-store-price.models';

const basePath = '/api/admin/store-prices';

@Injectable({ providedIn: 'root' })
export class StorePricesApiService {
  private readonly api = inject(ApiHttpService);

  list(query: StoreAdminStorePriceListQuery = {}): Observable<StoreAdminStorePriceListPageDto> {
    return this.api.get<StoreAdminStorePriceListPageDto>(basePath, toHttpParams(query)).pipe(handleApiError<StoreAdminStorePriceListPageDto>());
  }

  listByStore(donViId: number, productId?: number | null): Observable<StoreAdminStorePriceListItemDto[]> {
    const q =
      productId !== null && productId !== undefined ? toHttpParams({ productId }) : new HttpParams();
    return this.api
      .get<StoreAdminStorePriceListItemDto[]>(`${basePath}/by-store/${donViId}`, q)
      .pipe(handleApiError<StoreAdminStorePriceListItemDto[]>());
  }

  listPriceBoards(query: StoreAdminStationPriceBoardListQuery = {}): Observable<StoreAdminStationPriceBoardListPageDto> {
    return this.api
      .get<StoreAdminStationPriceBoardListPageDto>(`${basePath}/price-boards`, toHttpParams(query))
      .pipe(handleApiError<StoreAdminStationPriceBoardListPageDto>());
  }

  getPriceBoard(id: number): Observable<StoreAdminStationPriceBoardDetailDto> {
    return this.api
      .get<StoreAdminStationPriceBoardDetailDto>(`${basePath}/price-boards/${id}`)
      .pipe(handleApiError<StoreAdminStationPriceBoardDetailDto>());
  }

  updatePriceBoard(id: number, body: StoreAdminStationPriceBoardUpdateRequest): Observable<StoreAdminStationPriceBoardDetailDto> {
    return this.api
      .put<StoreAdminStationPriceBoardDetailDto>(`${basePath}/price-boards/${id}`, body)
      .pipe(handleApiError<StoreAdminStationPriceBoardDetailDto>());
  }

  deletePriceBoard(id: number): Observable<void> {
    return this.api.delete<void>(`${basePath}/price-boards/${id}`).pipe(handleApiError<void>());
  }

  getPriceBoardEditor(id: number): Observable<StoreAdminStationPriceBoardEditorResponseDto> {
    return this.api
      .get<StoreAdminStationPriceBoardEditorResponseDto>(`${basePath}/price-boards/${id}/editor`)
      .pipe(handleApiError<StoreAdminStationPriceBoardEditorResponseDto>());
  }

  savePriceBoardEditor(id: number, body: StoreAdminStationPriceBoardEditorSaveRequest): Observable<StoreAdminStationPriceBoardEditorResponseDto> {
    return this.api
      .put<StoreAdminStationPriceBoardEditorResponseDto>(`${basePath}/price-boards/${id}/editor`, body)
      .pipe(handleApiError<StoreAdminStationPriceBoardEditorResponseDto>());
  }

  listCurrentByStore(donViId: number): Observable<StoreAdminStorePriceListItemDto[]> {
    return this.api
      .get<StoreAdminStorePriceListItemDto[]>(`${basePath}/current/by-store/${donViId}`)
      .pipe(handleApiError<StoreAdminStorePriceListItemDto[]>());
  }

  getById(id: number): Observable<StoreAdminStorePriceDetailDto> {
    return this.api.get<StoreAdminStorePriceDetailDto>(`${basePath}/${id}`).pipe(handleApiError<StoreAdminStorePriceDetailDto>());
  }

  create(body: StoreAdminStorePriceUpsertRequest): Observable<StoreAdminStorePriceDetailDto> {
    return this.api.post<StoreAdminStorePriceDetailDto>(basePath, body).pipe(handleApiError<StoreAdminStorePriceDetailDto>());
  }

  update(id: number, body: StoreAdminStorePriceUpsertRequest): Observable<StoreAdminStorePriceDetailDto> {
    return this.api.put<StoreAdminStorePriceDetailDto>(`${basePath}/${id}`, body).pipe(handleApiError<StoreAdminStorePriceDetailDto>());
  }

  listProducts(query: StoreAdminStorePriceProductsQuery = {}): Observable<StoreAdminFuelProductLookupDto[]> {
    return this.api
      .get<StoreAdminFuelProductLookupDto[]>(`${basePath}/products`, toHttpParams(query))
      .pipe(handleApiError<StoreAdminFuelProductLookupDto[]>());
  }

  listDonViTinh(): Observable<StoreAdminDonViTinhLookupDto[]> {
    return this.api
      .get<StoreAdminDonViTinhLookupDto[]>(`${basePath}/don-vi-tinh`)
      .pipe(handleApiError<StoreAdminDonViTinhLookupDto[]>());
  }

  latestSubmission(donViId: number): Observable<StoreAdminStorePriceLatestSubmissionRowDto[]> {
    return this.api
      .get<StoreAdminStorePriceLatestSubmissionRowDto[]>(`${basePath}/latest-submission`, toHttpParams({ donViId }))
      .pipe(handleApiError<StoreAdminStorePriceLatestSubmissionRowDto[]>());
  }

  batchCreate(body: StoreAdminStorePriceBatchCreateRequest): Observable<StoreAdminStorePriceBatchCreateResponseDto> {
    return this.api
      .post<StoreAdminStorePriceBatchCreateResponseDto>(`${basePath}/batch`, body)
      .pipe(handleApiError<StoreAdminStorePriceBatchCreateResponseDto>());
  }
}
