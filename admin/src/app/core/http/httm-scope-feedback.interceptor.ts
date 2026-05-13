import { HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { MatSnackBar } from '@angular/material/snack-bar';
import { throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';

import { environment } from '../../../environments/environment';
import { isRequestToApiBase } from './api-origin-matches.util';

/**
 * 403 từ API HTTM khi vượt phạm vi tỉnh — hiển thị toast tiếng Việt (backend trả ProblemDetails.detail).
 */
export const httmScopeFeedbackInterceptor: HttpInterceptorFn = (req, next) => {
  const base = environment.apiBaseUrl.replace(/\/$/, '').trim();
  const snack = inject(MatSnackBar);

  return next(req).pipe(
    catchError((err: unknown) => {
      if (!(err instanceof HttpErrorResponse) || err.status !== 403) {
        return throwError(() => err);
      }
      if (!base || !isRequestToApiBase(req.url, base)) {
        return throwError(() => err);
      }
      if (!req.url.includes('/api/httm')) {
        return throwError(() => err);
      }
      const problem = err.error as { detail?: unknown } | null;
      const detail = typeof problem?.detail === 'string' ? problem.detail : '';
      if (detail.includes('SCOPE') || detail.includes('phạm vi')) {
        snack.open('Không có quyền truy cập dữ liệu ngoài phạm vi được giao.', 'Đóng', {
          duration: 7000,
        });
      }
      return throwError(() => err);
    }),
  );
};
