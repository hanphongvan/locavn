import { HttpErrorResponse } from '@angular/common/http';

import type { ApiProblemDetails } from '../http/api-problem-details.model';
import type { OAuthTokenErrorResponse } from './models/oauth-token-error-response.model';

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null;
}

function isOAuthTokenErrorBody(body: unknown): body is OAuthTokenErrorResponse {
  return isRecord(body) && typeof body['error'] === 'string';
}

/** RFC 7807 / ASP.NET `ProblemDetails.detail` when present. */
export function readProblemDetailsDetail(err: HttpErrorResponse): string | null {
  const body = err.error;
  if (!isRecord(body)) {
    return null;
  }
  const p = body as ApiProblemDetails;
  return typeof p.detail === 'string' && p.detail.trim() !== '' ? p.detail.trim() : null;
}

/**
 * Human-readable message for failed login / profile calls (OAuth JSON, ProblemDetails, or transport).
 */
export function formatAuthHttpError(err: unknown): string {
  if (err instanceof HttpErrorResponse) {
    const body = err.error;
    if (isOAuthTokenErrorBody(body)) {
      const oauth = body;
      const desc =
        typeof oauth.error_description === 'string' ? oauth.error_description.trim() : '';
      if (desc) {
        return desc;
      }
      const code = oauth.error.trim();
      if (code) {
        return code;
      }
    }
    const prob = readProblemDetailsDetail(err);
    if (prob) {
      return prob;
    }
    if (err.status === 0) {
      return 'Không kết nối được máy chủ. Kiểm tra API đang chạy và `apiBaseUrl`.';
    }
    return err.message || `Lỗi ${err.status}`;
  }
  if (err instanceof Error) {
    return err.message;
  }
  return 'Đăng nhập thất bại.';
}
