import { HttpParams } from '@angular/common/http';

/** Values allowed as query-string parameters for admin list endpoints. */
export type HttpQueryParamValue = string | number | boolean | Date | null | undefined;

/**
 * Builds {@link HttpParams} from a plain object; omits null/undefined.
 * Dates are sent as ISO-8601 strings (ASP.NET query model binding).
 */
export function toHttpParams(record: object): HttpParams {
  let params = new HttpParams();
  for (const [key, value] of Object.entries(record)) {
    if (value === null || value === undefined) {
      continue;
    }
    if (value instanceof Date) {
      params = params.set(key, value.toISOString());
      continue;
    }
    if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') {
      params = params.set(key, String(value));
    }
  }
  return params;
}
