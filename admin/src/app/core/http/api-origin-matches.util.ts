/**
 * True when `requestUrl` targets the same origin (protocol + host + port) as `apiBaseUrl`.
 * Avoids missing headers when `req.url` differs only by host casing or minor string form.
 */
export function isRequestToApiBase(requestUrl: string, apiBaseUrl: string): boolean {
  const base = apiBaseUrl?.replace(/\/$/, '').trim() ?? '';
  if (!base) {
    return false;
  }
  try {
    const req = new URL(requestUrl);
    const root = new URL(base);
    return (
      req.protocol === root.protocol &&
      req.hostname.toLowerCase() === root.hostname.toLowerCase() &&
      req.port === root.port
    );
  } catch {
    return requestUrl.toLowerCase().startsWith(base.toLowerCase());
  }
}
