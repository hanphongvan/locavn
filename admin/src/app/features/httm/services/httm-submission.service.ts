import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';

import { ApiHttpService } from '../../../core/http/api-http.service';
import { handleApiError } from '../../../core/http/api-request-error';
import { API_BASE_URL } from '../../../core/tokens/api-base-url.token';
import type { HttmFacilityDto } from '../models/httm-facility.model';
import type {
  HttmPublicFacilityRow,
  HttmSubmissionApproveRequest,
  HttmSubmissionCreateRequest,
  HttmSubmissionDetail,
  HttmSubmissionListPage,
  HttmSubmissionRejectRequest,
  HttmSubmissionReviewResult,
} from '../models/httm-submission.model';

/**
 * Service cho cả 2 flow: public submit (no auth) + admin review (Bearer).
 * Public endpoints gọi qua `rawHttp` để bypass auth interceptor không gắn header thừa.
 */
@Injectable({ providedIn: 'root' })
export class HttmSubmissionService {
  private readonly api = inject(ApiHttpService);
  private readonly rawHttp = inject(HttpClient);
  private readonly baseUrl = inject(API_BASE_URL).replace(/\/$/, '');

  // ============= PUBLIC =============

  /** 63 tỉnh — dùng cho dropdown trên form public. */
  listPublicProvinces() {
    return this.rawHttp
      .get<{ id: number; code: string; name: string; sapXep: number | null; vungMien: number | null }[]>(
        `${this.baseUrl}/api/public/geography/provinces`,
      )
      .pipe(handleApiError());
  }

  /** Xã của tỉnh theo mã ĐVHCVN. */
  listPublicWardsByProvince(provinceCode: string) {
    return this.rawHttp
      .get<{ code: string; name: string; tinhId: number | null; quanHuyenId: number | null }[]>(
        `${this.baseUrl}/api/public/geography/wards`,
        { params: { provinceCode } },
      )
      .pipe(handleApiError());
  }

  /** Upload ảnh hạ tầng — multipart, max 10MB, ext jpg/jpeg/png/webp. */
  uploadImage(file: File) {
    const form = new FormData();
    form.append('file', file);
    return this.rawHttp
      .post<{ url: string; fileName: string; sizeBytes: number }>(
        `${this.baseUrl}/api/public/httm/upload/image`,
        form,
      )
      .pipe(handleApiError());
  }

  /** Upload giấy tờ pháp lý — max 20MB, pdf hoặc ảnh scan. */
  uploadDocument(file: File) {
    const form = new FormData();
    form.append('file', file);
    return this.rawHttp
      .post<{ url: string; fileName: string; sizeBytes: number }>(
        `${this.baseUrl}/api/public/httm/upload/document`,
        form,
      )
      .pipe(handleApiError());
  }

  searchPublicFacilities(opts: { q?: string; provinceCode?: string; wardCode?: string; limit?: number }) {
    let p = new HttpParams();
    if (opts.q) p = p.set('q', opts.q);
    if (opts.provinceCode) p = p.set('provinceCode', opts.provinceCode);
    if (opts.wardCode) p = p.set('wardCode', opts.wardCode);
    if (opts.limit) p = p.set('limit', String(opts.limit));
    return this.rawHttp
      .get<HttmPublicFacilityRow[]>(`${this.baseUrl}/api/public/httm/facility-search`, { params: p })
      .pipe(handleApiError());
  }

  getPublicSnapshot(id: string) {
    return this.rawHttp
      .get<HttmFacilityDto>(`${this.baseUrl}/api/public/httm/facility-snapshot/${id}`)
      .pipe(handleApiError());
  }

  submit(body: HttmSubmissionCreateRequest) {
    return this.rawHttp
      .post<{ submissionId: string }>(`${this.baseUrl}/api/public/httm/facility-submissions`, body)
      .pipe(handleApiError());
  }

  // ============= ADMIN =============

  listAdmin(opts: {
    status?: string;
    provinceCode?: string;
    submissionType?: string;
    q?: string;
    page?: number;
    pageSize?: number;
  }) {
    let p = new HttpParams();
    if (opts.status) p = p.set('status', opts.status);
    if (opts.provinceCode) p = p.set('provinceCode', opts.provinceCode);
    if (opts.submissionType) p = p.set('submissionType', opts.submissionType);
    if (opts.q) p = p.set('q', opts.q);
    p = p.set('page', String(opts.page ?? 1));
    p = p.set('pageSize', String(opts.pageSize ?? 20));
    return this.api.get<HttmSubmissionListPage>('/api/admin/httm/submissions', p).pipe(handleApiError());
  }

  countPending() {
    return this.api
      .get<{ pendingCount: number }>('/api/admin/httm/submissions/count-pending')
      .pipe(handleApiError());
  }

  getAdminDetail(id: string) {
    return this.api.get<HttmSubmissionDetail>(`/api/admin/httm/submissions/${id}`).pipe(handleApiError());
  }

  approve(id: string, body: HttmSubmissionApproveRequest) {
    return this.api
      .post<HttmSubmissionReviewResult>(`/api/admin/httm/submissions/${id}/approve`, body)
      .pipe(handleApiError());
  }

  reject(id: string, body: HttmSubmissionRejectRequest) {
    return this.api
      .post<HttmSubmissionReviewResult>(`/api/admin/httm/submissions/${id}/reject`, body)
      .pipe(handleApiError());
  }
}
