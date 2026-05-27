import { HttpErrorResponse } from '@angular/common/http';
import { Component, inject, OnInit, signal } from '@angular/core';
import { NonNullableFormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { RouterLink } from '@angular/router';
import { ActivatedRoute, Router } from '@angular/router';

import { AdminAuthService } from '../../core/auth/admin-auth.service';
import { formatAuthHttpError, readProblemDetailsDetail } from '../../core/auth/oauth-http-error.util';
import { isPortalRoleUnauthorizedError } from '../../core/auth/portal-role-unauthorized.error';
import { LoginVietnamMapComponent } from './components/login-vietnam-map.component';
import { DmsLogoComponent } from './components/dms-logo.component';

const REMEMBER_USERNAME_KEY = 'httm-admin-login-remember-username';

@Component({
  selector: 'app-login-page',
  standalone: true,
  imports: [
    ReactiveFormsModule,
    RouterLink,
    MatSnackBarModule,
    DmsLogoComponent,
    LoginVietnamMapComponent,
  ],
  templateUrl: './login-page.component.html',
  styleUrl: './login-page.component.scss',
})
export class LoginPageComponent implements OnInit {
  private readonly fb = inject(NonNullableFormBuilder);
  private readonly auth = inject(AdminAuthService);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);
  private readonly snack = inject(MatSnackBar);

  readonly systemVersion = 'v1.0.0';

  readonly form = this.fb.group({
    username: this.fb.control('', { validators: [Validators.required] }),
    password: this.fb.control('', { validators: [Validators.required] }),
    rememberMe: this.fb.control(false),
  });

  readonly loading = signal(false);
  readonly passwordVisible = signal(false);
  readonly loginError = signal<string | null>(null);
  readonly accessDenied = signal<string | null>(null);
  readonly registeredNotice = signal<string | null>(null);

  readonly legendItems = [
    { label: 'Chợ', color: '#3b82f6' },
    { label: 'Siêu thị', color: '#22c55e' },
    { label: 'Trung tâm thương mại', color: '#a855f7' },
    { label: 'Trung tâm logistics', color: '#f97316' },
    { label: 'Cửa hàng tiện lợi', color: '#14b8a6' },
    { label: 'Cửa hàng OCOP', color: '#eab308' },
    { label: 'Cửa hàng xăng dầu', color: '#ec4899' },
  ] as const;

  constructor() {
    const name = this.route.snapshot.queryParamMap.get('registered');
    if (name?.trim()) {
      this.registeredNotice.set(name.trim());
    }
  }

  ngOnInit(): void {
    const saved = localStorage.getItem(REMEMBER_USERNAME_KEY);
    if (saved) {
      this.form.patchValue({ username: saved, rememberMe: true });
    }
  }

  togglePasswordVisible(): void {
    this.passwordVisible.update((v) => !v);
  }

  onForgotPassword(event: Event): void {
    event.preventDefault();
    this.snack.open('Vui lòng liên hệ quản trị hệ thống để được hỗ trợ đặt lại mật khẩu.', 'Đóng', {
      duration: 6000,
    });
  }

  onAiSupport(): void {
    this.snack.open('Trợ lý AI đang được triển khai. Vui lòng quay lại sau.', 'Đóng', { duration: 5000 });
  }

  submit(): void {
    this.loginError.set(null);
    this.accessDenied.set(null);
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    const { username, password, rememberMe } = this.form.getRawValue();
    if (rememberMe) {
      localStorage.setItem(REMEMBER_USERNAME_KEY, username);
    } else {
      localStorage.removeItem(REMEMBER_USERNAME_KEY);
    }
    this.loading.set(true);
    this.auth.login(username, password).subscribe({
      next: () => {
        this.loading.set(false);
        const returnUrl = this.route.snapshot.queryParamMap.get('returnUrl');
        void this.router.navigateByUrl(this.auth.resolvePostLoginNavigationTarget(returnUrl));
      },
      error: (err: unknown) => {
        this.loading.set(false);
        if (isPortalRoleUnauthorizedError(err)) {
          return;
        }
        if (err instanceof HttpErrorResponse && err.status === 403) {
          this.accessDenied.set(
            readProblemDetailsDetail(err) ?? 'Tài khoản không đủ điều kiện quản trị cửa hàng.',
          );
          return;
        }
        this.loginError.set(formatAuthHttpError(err));
      },
    });
  }
}
