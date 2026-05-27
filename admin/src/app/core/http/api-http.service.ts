import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { API_BASE_URL } from '../tokens/api-base-url.token';

/**
 * Thin HTTP wrapper: all paths are relative to {@link API_BASE_URL}.
 * Feature services should call the backend through this (or dedicated services that use it).
 */
@Injectable({ providedIn: 'root' })
export class ApiHttpService {
  private readonly http = inject(HttpClient);
  private readonly baseUrl = inject(API_BASE_URL).replace(/\/$/, '');

  get<T>(path: string, params?: HttpParams) {
    const url = this.join(path);
    return params ? this.http.get<T>(url, { params }) : this.http.get<T>(url);
  }

  post<T>(path: string, body: unknown) {
    return this.http.post<T>(this.join(path), body);
  }

  put<T>(path: string, body: unknown) {
    return this.http.put<T>(this.join(path), body);
  }

  patch<T>(path: string, body: unknown) {
    return this.http.patch<T>(this.join(path), body);
  }

  delete<T>(path: string) {
    return this.http.delete<T>(this.join(path));
  }

  private join(path: string): string {
    const p = path.startsWith('/') ? path : `/${path}`;
    return `${this.baseUrl}${p}`;
  }
}
