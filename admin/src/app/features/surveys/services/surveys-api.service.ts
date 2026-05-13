import { HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';

import { ApiHttpService } from '../../../core/http/api-http.service';
import { handleApiError } from '../../../core/http/api-request-error';
import type {
  HttmSurveyCreateRequest,
  HttmSurveyDto,
  HttmSurveyHistoryDto,
  HttmSurveyPatchRequest,
  HttmSurveySearchPageDto,
  HttmSurveySearchQuery,
} from '../models/survey.models';

function appendParams(params: HttpParams, key: string, value: string | number | null | undefined): HttpParams {
  if (value === null || value === undefined || value === '') {
    return params;
  }
  return params.set(key, String(value));
}

function searchToParams(query: HttmSurveySearchQuery): HttpParams {
  let p = new HttpParams();
  p = appendParams(p, 'q', query.q ?? undefined);
  p = appendParams(p, 'status', query.status ?? undefined);
  p = appendParams(p, 'provinceCode', query.provinceCode ?? undefined);
  p = appendParams(p, 'httmType', query.httmType ?? undefined);
  p = appendParams(p, 'page', query.page ?? 1);
  p = appendParams(p, 'pageSize', query.pageSize ?? 20);
  return p;
}

@Injectable({ providedIn: 'root' })
export class SurveysApiService {
  private readonly api = inject(ApiHttpService);

  search(query: HttmSurveySearchQuery) {
    return this.api.get<HttmSurveySearchPageDto>('/api/surveys', searchToParams(query)).pipe(handleApiError());
  }

  getById(id: string) {
    return this.api.get<HttmSurveyDto>(`/api/surveys/${id}`).pipe(handleApiError());
  }

  create(body: HttmSurveyCreateRequest) {
    return this.api.post<{ id: string }>('/api/surveys', body).pipe(handleApiError());
  }

  patch(id: string, body: HttmSurveyPatchRequest) {
    return this.api.patch<void>(`/api/surveys/${id}`, body).pipe(handleApiError());
  }

  delete(id: string) {
    return this.api.delete<void>(`/api/surveys/${id}`).pipe(handleApiError());
  }

  submit(id: string) {
    return this.api.post<void>(`/api/surveys/${id}/submit`, {}).pipe(handleApiError());
  }

  startReview(id: string) {
    return this.api.post<void>(`/api/surveys/${id}/review`, {}).pipe(handleApiError());
  }

  approve(id: string, notes?: string | null) {
    return this.api.post<void>(`/api/surveys/${id}/approve`, { notes: notes ?? null }).pipe(handleApiError());
  }

  reject(id: string, reason: string) {
    return this.api.post<void>(`/api/surveys/${id}/reject`, { reason }).pipe(handleApiError());
  }

  history(id: string) {
    return this.api.get<HttmSurveyHistoryDto[]>(`/api/surveys/${id}/history`).pipe(handleApiError());
  }
}
