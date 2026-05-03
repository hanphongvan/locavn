import { Component, inject } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { map } from 'rxjs/operators';

import { AdminAuthService } from '../../core/auth/admin-auth.service';

@Component({
  selector: 'app-access-denied-page',
  standalone: true,
  imports: [RouterLink],
  templateUrl: './access-denied-page.component.html',
  styleUrl: './access-denied-page.component.scss',
})
export class AccessDeniedPageComponent {
  private readonly auth = inject(AdminAuthService);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);

  /** From {@link portalRoleGuard} when the user’s role may not open the target route. */
  readonly returnUrl = toSignal(
    this.route.queryParamMap.pipe(map((q) => q.get('returnUrl'))),
    { initialValue: this.route.snapshot.queryParamMap.get('returnUrl') },
  );

  /** From login flow when `Loai` is not 1, 3, or 4 (see {@link AdminAuthService#login}). */
  readonly denyReason = toSignal(
    this.route.queryParamMap.pipe(map((q) => q.get('reason'))),
    { initialValue: this.route.snapshot.queryParamMap.get('reason') },
  );

  /** Kết thúc phiên và chuyển về đăng nhập. */
  logout(): void {
    this.auth.logout();
  }

  /** Xóa token và mở trang đăng nhập (đổi tài khoản / đăng nhập lại). */
  goToLogin(): void {
    this.auth.clearCredentials();
    void this.router.navigate(['/login']);
  }

  /** Dùng với `routerLink="/login"`: xóa phiên trước khi Router điều hướng. */
  clearTokenBeforeLoginNav(): void {
    this.auth.clearCredentials();
  }

  /** Rút gọn URL dài cho hiển thị an toàn. */
  displayReturnUrl(raw: string | null): string {
    if (!raw) {
      return '';
    }
    const t = raw.trim();
    if (t.length <= 72) {
      return t;
    }
    return `${t.slice(0, 36)}…${t.slice(-28)}`;
  }
}
