import { HttpErrorResponse } from '@angular/common/http';
import { catchError, MonoTypeOperatorFunction, throwError } from 'rxjs';

import type { ApiProblemDetails } from './api-problem-details.model';

/** Normalized failure from an admin API call (includes parsed problem body when present). */
export class ApiRequestError extends Error {
  override readonly name = 'ApiRequestError';

  constructor(
    message: string,
    readonly httpStatus: number,
    readonly problem: ApiProblemDetails | null,
    readonly original: unknown,
  ) {
    super(message);
  }
}

function tryParseProblemDetails(body: unknown): ApiProblemDetails | null {
  if (!body || typeof body !== 'object') {
    return null;
  }
  const o = body as Record<string, unknown>;
  if ('detail' in o || 'title' in o || 'status' in o || 'type' in o) {
    return body as ApiProblemDetails;
  }
  return null;
}

export function toApiRequestError(err: unknown): ApiRequestError {
  if (err instanceof HttpErrorResponse) {
    const problem = tryParseProblemDetails(err.error);
    const message =
      (typeof problem?.detail === 'string' && problem.detail.trim() !== ''
        ? problem.detail
        : err.message) ?? 'Request failed';
    return new ApiRequestError(message, err.status, problem, err);
  }
  if (err instanceof Error) {
    return new ApiRequestError(err.message, 0, null, err);
  }
  return new ApiRequestError('Unknown error', 0, null, err);
}

/** RxJS operator: failures become {@link ApiRequestError}; preserves success type `T`. */
export function handleApiError<T>(): MonoTypeOperatorFunction<T> {
  return catchError((err: unknown) => throwError(() => toApiRequestError(err)));
}
