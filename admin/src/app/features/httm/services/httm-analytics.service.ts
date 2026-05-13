import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';

import { ApiHttpService } from '../../../core/http/api-http.service';
import { handleApiError } from '../../../core/http/api-request-error';
import { API_BASE_URL } from '../../../core/tokens/api-base-url.token';
import { AuthSessionStorage } from '../../../core/auth/auth-session.storage';

export interface TypeCountRow {
  httmType: string;
  count: number;
}

export interface StatusCountRow {
  status: string;
  count: number;
}

export interface ProvinceCountRow {
  provinceCode: string;
  count: number;
}

export interface MonthCountRow {
  month: string;
  count: number;
}

export interface AnalyticsSummaryRow {
  facilityCount: number;
  surveyCount: number;
  surveysPendingReview: number;
}

@Injectable({ providedIn: 'root' })
export class HttmAnalyticsService {
  private readonly api = inject(ApiHttpService);
  private readonly raw = inject(HttpClient);
  private readonly baseUrl = inject(API_BASE_URL).replace(/\/$/, '');
  private readonly session = inject(AuthSessionStorage);

  facilitiesByType() {
    return this.api.get<TypeCountRow[]>('/api/httm-analytics/charts/facilities-by-type').pipe(handleApiError());
  }

  facilitiesByProvince(top = 12) {
    const p = new HttpParams().set('top', String(top));
    return this.api.get<ProvinceCountRow[]>('/api/httm-analytics/charts/facilities-by-province', p).pipe(handleApiError());
  }

  surveysByStatus() {
    return this.api.get<StatusCountRow[]>('/api/httm-analytics/charts/surveys-by-status').pipe(handleApiError());
  }

  facilityCreatedByMonth(months = 6) {
    const p = new HttpParams().set('months', String(months));
    return this.api.get<MonthCountRow[]>('/api/httm-analytics/charts/facility-created-by-month', p).pipe(handleApiError());
  }

  surveySubmittedByMonth(months = 6) {
    const p = new HttpParams().set('months', String(months));
    return this.api.get<MonthCountRow[]>('/api/httm-analytics/charts/survey-submitted-by-month', p).pipe(handleApiError());
  }

  summary() {
    return this.api.get<AnalyticsSummaryRow>('/api/httm-analytics/summary').pipe(handleApiError());
  }

  downloadSummaryCsv(): void {
    const token = this.session.getAccessToken();
    const url = `${this.baseUrl}/api/httm-analytics/export/summary.csv`;
    const headers: Record<string, string> = {};
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }
    this.raw.get(url, { headers, responseType: 'blob' }).subscribe({
      next: (blob) => {
        const a = document.createElement('a');
        a.href = URL.createObjectURL(blob);
        a.download = 'httm-analytics-summary.csv';
        a.click();
        URL.revokeObjectURL(a.href);
      },
    });
  }
}
