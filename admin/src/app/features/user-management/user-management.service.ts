import { HttpClient, HttpParams } from '@angular/common/http';
import { inject, Injectable } from '@angular/core';
import { Observable } from 'rxjs';

import { API_BASE_URL } from '../../core/tokens/api-base-url.token';
import type {
  DonViOptionDto,
  RoleOptionDto,
  UserBulkIdsRequest,
  UserCreateRequest,
  UserDetailDto,
  UserListPageDto,
  UserLockUnlockResultDto,
  UserSyncResultDto,
  UserUpdateRequest,
} from './user-management.models';

export interface UserListQuery {
  keyword?: string | null;
  donViId?: number | null;
  loai?: number | null;
  locked?: boolean | null;
  skip?: number;
  take?: number;
}

@Injectable({ providedIn: 'root' })
export class UserManagementService {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL).replace(/\/$/, '') + '/api/users';

  list(q: UserListQuery): Observable<UserListPageDto> {
    let p = new HttpParams();
    if (q.keyword) {
      p = p.set('keyword', q.keyword);
    }
    if (q.donViId != null) {
      p = p.set('donViId', String(q.donViId));
    }
    if (q.loai != null) {
      p = p.set('loai', String(q.loai));
    }
    if (q.locked !== undefined && q.locked !== null) {
      p = p.set('locked', String(q.locked));
    }
    p = p.set('skip', String(q.skip ?? 0));
    p = p.set('take', String(q.take ?? 20));
    return this.http.get<UserListPageDto>(this.base, { params: p });
  }

  exportCsvBlob(q: Omit<UserListQuery, 'skip' | 'take'>): Observable<Blob> {
    let p = new HttpParams();
    if (q.keyword) {
      p = p.set('keyword', q.keyword);
    }
    if (q.donViId != null) {
      p = p.set('donViId', String(q.donViId));
    }
    if (q.loai != null) {
      p = p.set('loai', String(q.loai));
    }
    if (q.locked !== undefined && q.locked !== null) {
      p = p.set('locked', String(q.locked));
    }
    return this.http.get(`${this.base}/export`, { params: p, responseType: 'blob' });
  }

  getById(id: string): Observable<UserDetailDto> {
    return this.http.get<UserDetailDto>(`${this.base}/${encodeURIComponent(id)}`);
  }

  create(body: UserCreateRequest): Observable<{ id: string }> {
    return this.http.post<{ id: string }>(this.base, body);
  }

  update(id: string, body: UserUpdateRequest): Observable<void> {
    return this.http.put<void>(`${this.base}/${encodeURIComponent(id)}`, body);
  }

  delete(id: string): Observable<void> {
    return this.http.delete<void>(`${this.base}/${encodeURIComponent(id)}`);
  }

  lock(body: UserBulkIdsRequest): Observable<UserLockUnlockResultDto> {
    return this.http.post<UserLockUnlockResultDto>(`${this.base}/lock`, body);
  }

  unlock(body: UserBulkIdsRequest): Observable<UserLockUnlockResultDto> {
    return this.http.post<UserLockUnlockResultDto>(`${this.base}/unlock`, body);
  }

  sync(): Observable<UserSyncResultDto> {
    return this.http.post<UserSyncResultDto>(`${this.base}/sync`, {});
  }

  roles(): Observable<RoleOptionDto[]> {
    return this.http.get<RoleOptionDto[]>(`${this.base}/roles`);
  }

  /**
   * @param forLoai Khi truyền 1, 3 hoặc 4: nguồn đơn vị theo form user; bỏ qua: toàn bộ DM_DonVi (lọc danh sách).
   */
  donVi(forLoai?: number | null): Observable<DonViOptionDto[]> {
    let p = new HttpParams();
    if (forLoai != null) {
      p = p.set('loai', String(forLoai));
    }
    return this.http.get<DonViOptionDto[]>(`${this.base}/don-vi`, { params: p });
  }
}
