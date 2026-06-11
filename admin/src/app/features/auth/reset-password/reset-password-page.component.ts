import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { Component, OnInit, inject, signal } from '@angular/core';
import { NonNullableFormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { ActivatedRoute, RouterLink } from '@angular/router';

import { API_BASE_URL } from '../../../core/tokens/api-base-url.token';
import { DmsLogoComponent } from '../components/dms-logo.component';

interface ResetPasswordMessageResponse {
  message: string;
}

/**
 * Trang web (anonymous) đặt lại mật khẩu từ link email — đích của
 * `PasswordReset:WebResetPasswordBaseUrl` (`/reset-password?token=...`).
 * Đọc `token` từ query, POST `api/auth/reset-password` với mật khẩu mới.
 */
@Component({
  selector: 'app-reset-password-page',
  standalone: true,
  imports: [
    ReactiveFormsModule,
    RouterLink,
    MatCardModule,
    MatFormFieldModule,
    MatInputModule,
    MatButtonModule,
    MatIconModule,
    MatProgressSpinnerModule,
    DmsLogoComponent,
  ],
  templateUrl: './reset-password-page.component.html',
  styleUrl: './reset-password-page.component.scss',
})
export class ResetPasswordPageComponent implements OnInit {
  private readonly fb = inject(NonNullableFormBuilder);
  private readonly http = inject(HttpClient);
  private readonly route = inject(ActivatedRoute);
  private readonly apiBase = inject(API_BASE_URL).replace(/\/$/, '');

  /** Token lấy từ `?token=` của link email. Rỗng → hiển thị trạng thái link không hợp lệ. */
  private token = '';

  readonly missingToken = signal(false);
  readonly submitting = signal(false);
  readonly succeeded = signal(false);
  readonly errorMessage = signal<string | null>(null);
  readonly newPasswordVisible = signal(false);
  readonly confirmPasswordVisible = signal(false);

  readonly form = this.fb.group({
    newPassword: this.fb.control('', {
      validators: [Validators.required, Validators.minLength(6)],
    }),
    confirmPassword: this.fb.control('', { validators: [Validators.required] }),
  });

  ngOnInit(): void {
    this.token = this.route.snapshot.queryParamMap.get('token')?.trim() ?? '';
    this.missingToken.set(this.token.length === 0);
  }

  toggleNewPasswordVisible(): void {
    this.newPasswordVisible.update((v) => !v);
  }

  toggleConfirmPasswordVisible(): void {
    this.confirmPasswordVisible.update((v) => !v);
  }

  /** True khi 2 ô đã nhập nhưng không khớp — để hiện lỗi inline (server cũng kiểm tra lại). */
  get passwordMismatch(): boolean {
    const { newPassword, confirmPassword } = this.form.getRawValue();
    return confirmPassword.length > 0 && newPassword !== confirmPassword;
  }

  submit(): void {
    this.errorMessage.set(null);
    if (this.missingToken()) {
      return;
    }
    if (this.form.invalid || this.passwordMismatch) {
      this.form.markAllAsTouched();
      return;
    }

    const { newPassword, confirmPassword } = this.form.getRawValue();
    this.submitting.set(true);
    this.http
      .post<ResetPasswordMessageResponse>(`${this.apiBase}/api/auth/reset-password`, {
        token: this.token,
        newPassword,
        confirmPassword,
      })
      .subscribe({
        next: () => {
          this.succeeded.set(true);
        },
        error: (err: unknown) => {
          this.submitting.set(false);
          const fallback = 'Đặt lại mật khẩu thất bại. Link có thể đã hết hạn hoặc đã được dùng.';
          if (err instanceof HttpErrorResponse) {
            const body = err.error as ResetPasswordMessageResponse | string | null;
            const msg = typeof body === 'object' && body ? body.message : null;
            this.errorMessage.set(msg || fallback);
          } else {
            this.errorMessage.set(fallback);
          }
        },
        complete: () => this.submitting.set(false),
      });
  }
}
