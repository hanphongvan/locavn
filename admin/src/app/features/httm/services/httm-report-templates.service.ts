import { HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';

import { ApiHttpService } from '../../../core/http/api-http.service';
import { handleApiError } from '../../../core/http/api-request-error';

export interface HttmReportTemplateDto {
  id: string;
  code: string;
  name: string;
  description: string | null;
  reminderIntervalDays: number;
  lastReminderAt: string | null;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface HttmReportTemplateUpsertRequest {
  id?: string | null;
  code: string;
  name: string;
  description?: string | null;
  reminderIntervalDays: number;
  isActive: boolean;
}

@Injectable({ providedIn: 'root' })
export class HttmReportTemplatesService {
  private readonly api = inject(ApiHttpService);

  list(includeInactive = false) {
    const p = new HttpParams().set('includeInactive', includeInactive ? 'true' : 'false');
    return this.api.get<HttmReportTemplateDto[]>('/api/httm-report-templates', p).pipe(handleApiError());
  }

  getById(id: string) {
    return this.api.get<HttmReportTemplateDto>(`/api/httm-report-templates/${id}`).pipe(handleApiError());
  }

  upsert(body: HttmReportTemplateUpsertRequest) {
    return this.api.post<{ id: string }>('/api/httm-report-templates', body).pipe(handleApiError());
  }

  delete(id: string) {
    return this.api.delete<void>(`/api/httm-report-templates/${id}`).pipe(handleApiError());
  }
}
