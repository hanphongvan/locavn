/**
 * Cấu hình môi trường phát triển.
 * Đổi `apiBaseUrl` tại đây (hoặc trong `environment.production.ts` khi build production) — không dấu `/` cuối.
 */
export const environment = {
  production: false,
  /** Gốc API backend (ví dụ máy local ASP.NET). */
  apiBaseUrl: 'http://localhost:5111',
  /**
   * Khớp `Admin:ApiKey` trên API (Development: `appsettings.Development.json`).
   * Production: đặt qua CI / thay thế file môi trường, không commit bí mật thật.
   */
  adminApiKey: 'local-dev-admin-key',
};
