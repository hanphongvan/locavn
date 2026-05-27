import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';

import { ApiHttpService } from '../../../core/http/api-http.service';
import { handleApiError } from '../../../core/http/api-request-error';
import { API_BASE_URL } from '../../../core/tokens/api-base-url.token';
import type {
  HttmImportConfirmRequest,
  HttmImportConfirmResponse,
  HttmImportValidateResponse,
} from '../models/httm-import.model';

@Injectable({ providedIn: 'root' })
export class HttmImportService {
  private readonly api = inject(ApiHttpService);
  /** Cho 2 endpoint cần riêng: multipart upload và blob download — `ApiHttpService` không cover. */
  private readonly rawHttp = inject(HttpClient);
  private readonly baseUrl = inject(API_BASE_URL).replace(/\/$/, '');

  /** Tải file Excel mẫu (.xlsx) dạng Blob để FE save-as. */
  downloadTemplate() {
    return this.rawHttp.get(`${this.baseUrl}/api/httm/import/template`, {
      responseType: 'blob',
      observe: 'response',
    });
  }

  /** Upload file Excel → server parse + validate, trả về sessionToken + preview. */
  validate(file: File) {
    const form = new FormData();
    form.append('file', file);
    return this.rawHttp
      .post<HttmImportValidateResponse>(`${this.baseUrl}/api/httm/import/validate`, form)
      .pipe(handleApiError());
  }

  /** Confirm session — server insert các dòng hợp lệ, skip duplicate. */
  confirm(body: HttmImportConfirmRequest) {
    return this.api.post<HttmImportConfirmResponse>('/api/httm/import/confirm', body).pipe(handleApiError());
  }
}
