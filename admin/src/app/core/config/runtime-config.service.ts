import { Injectable } from '@angular/core';

import { environment } from '../../../environments/environment';

/**
 * Cấu hình runtime được load từ `assets/runtime-config.json` lúc app khởi động
 * (qua `APP_INITIALIZER`). Sửa giá trị trên server sau khi deploy, F5 trình duyệt
 * là có hiệu lực — không cần build lại Angular.
 *
 * KHÔNG đặt secret thật (DB password, JWT signing key…) vào file này vì
 * client tải về được — coi như public.
 */
export interface RuntimeConfig {
  /** Gốc API backend, không dấu `/` cuối. */
  apiBaseUrl: string;
  /**
   * Khớp `Admin:ApiKey` trên backend; chỉ dùng cho các call không có Bearer (ví dụ
   * trang công khai). Đã ở client → coi như public, không phải bí mật mạnh.
   */
  adminApiKey: string;
}

@Injectable({ providedIn: 'root' })
export class RuntimeConfigService {
  /** Giá trị fallback dùng khi fetch fail (lỗi mạng / file thiếu) — match `environment.ts`. */
  private static readonly FALLBACK: RuntimeConfig = {
    apiBaseUrl: environment.apiBaseUrl,
    adminApiKey: environment.adminApiKey,
  };

  private config: RuntimeConfig = RuntimeConfigService.FALLBACK;

  /** Gọi qua `APP_INITIALIZER` trong `app.config.ts`. */
  async load(): Promise<void> {
    try {
      // `cache: 'no-store'` + `web.config` đặt no-cache → admin sửa file là client thấy ngay khi F5.
      const res = await fetch('assets/runtime-config.json', { cache: 'no-store' });
      if (!res.ok) {
        console.warn(
          `[RuntimeConfig] HTTP ${res.status} khi tải runtime-config.json — dùng giá trị fallback từ environment.ts.`,
        );
        return;
      }
      const parsed = (await res.json()) as Partial<RuntimeConfig>;
      this.config = {
        apiBaseUrl: (parsed.apiBaseUrl ?? RuntimeConfigService.FALLBACK.apiBaseUrl).trim(),
        adminApiKey: (parsed.adminApiKey ?? RuntimeConfigService.FALLBACK.adminApiKey).trim(),
      };
    } catch (err) {
      console.warn('[RuntimeConfig] Lỗi khi đọc runtime-config.json — dùng fallback.', err);
    }
  }

  /** Gốc API đã chuẩn hóa (bỏ `/` cuối). */
  get apiBaseUrl(): string {
    return this.config.apiBaseUrl.replace(/\/$/, '');
  }

  get adminApiKey(): string {
    return this.config.adminApiKey;
  }
}
