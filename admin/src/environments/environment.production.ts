/**
 * Production build (Angular `fileReplacements` thay `environment.ts` bằng file này).
 *
 * ⚠ Từ khi chuyển sang runtime config, giá trị dưới đây CHỈ là **fallback** khi
 * `assets/runtime-config.json` fetch fail (lỗi mạng / file thiếu). Giá trị thật
 * dùng trên server được đọc từ `runtime-config.json` lúc app khởi động —
 * sửa file đó, F5 trình duyệt, không cần build lại.
 *
 * Xem `assets/runtime-config.example.production.json` để biết shape cần đặt
 * trên IIS sau khi deploy.
 */
export const environment = {
  production: true,
  /** Fallback nếu runtime-config.json không load được. */
  apiBaseUrl: 'https://xd.dms.gov.vn',
  /** Để rỗng — admin API key phải đặt qua runtime-config.json trên server. */
  adminApiKey: '',
};
