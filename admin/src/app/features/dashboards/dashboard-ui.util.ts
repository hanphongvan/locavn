import { ApiRequestError } from '../../core/http/api-request-error';

export type DashMetric = { kind: 'ok'; total: number } | { kind: 'error'; message: string };

export function dashErr(err: unknown, fallback: string): string {
  return err instanceof ApiRequestError ? err.message : fallback;
}
