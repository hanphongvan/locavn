import { HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';

import { ApiHttpService } from '../../../core/http/api-http.service';
import { handleApiError } from '../../../core/http/api-request-error';
import type { AppFeedbackDetail, AppFeedbackPage } from '../models/app-feedback.model';

/** Đọc góp ý ứng dụng cho cán bộ (Bearer / Admin API key). */
@Injectable({ providedIn: 'root' })
export class AppFeedbackService {
  private readonly api = inject(ApiHttpService);

  listAdmin(opts: { skip?: number; take?: number }) {
    let p = new HttpParams();
    p = p.set('skip', String(opts.skip ?? 0));
    p = p.set('take', String(opts.take ?? 20));
    return this.api.get<AppFeedbackPage>('/api/admin/app-feedback', p).pipe(handleApiError());
  }

  getDetail(id: number) {
    return this.api.get<AppFeedbackDetail>(`/api/admin/app-feedback/${id}`).pipe(handleApiError());
  }
}
