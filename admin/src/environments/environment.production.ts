/**
 * Production: file này thay thế `environment.ts` theo `angular.json` → `fileReplacements`.
 * Admin IIS: **xangdau.tpg.vn** — `apiBaseUrl` trỏ API (không dấu `/` cuối).
 */
export const environment = {
  production: true,
  /** API: xdapi.tpg.vn — CORS production: `appsettings.Production.json` → Cors:AllowedOrigins. */
  apiBaseUrl: 'http://xdapi.tpg.vn',
  /** Bắt buộc cho `/api/admin/*`; khớp biến môi trường `Admin__ApiKey` trên server. */
  adminApiKey: '',
};
