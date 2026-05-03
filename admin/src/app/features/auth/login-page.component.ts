import { HttpErrorResponse } from '@angular/common/http';
import { Component, inject, signal } from '@angular/core';
import { NonNullableFormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { RouterLink } from '@angular/router';
import { ActivatedRoute, Router } from '@angular/router';

import { AdminAuthService } from '../../core/auth/admin-auth.service';
import { formatAuthHttpError, readProblemDetailsDetail } from '../../core/auth/oauth-http-error.util';
import { isPortalRoleUnauthorizedError } from '../../core/auth/portal-role-unauthorized.error';

@Component({
  selector: 'app-login-page',
  standalone: true,
  imports: [ReactiveFormsModule, RouterLink, MatButtonModule],
  templateUrl: './login-page.component.html',
  styleUrl: './login-page.component.scss',
})
export class LoginPageComponent {
  private readonly fb = inject(NonNullableFormBuilder);
  private readonly auth = inject(AdminAuthService);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);

  readonly form = this.fb.group({
    username: this.fb.control('', { validators: [Validators.required] }),
    password: this.fb.control('', { validators: [Validators.required] }),
  });

  readonly loading = signal(false);
  /** OAuth / network / server errors (excluding unsupported `Loai`). */
  readonly loginError = signal<string | null>(null);
  /** Store-admin or other HTTP 403 bodies. */
  readonly accessDenied = signal<string | null>(null);
  /** Set when redirected from `/register?registered=`. */
  readonly registeredNotice = signal<string | null>(null);

  constructor() {
    const name = this.route.snapshot.queryParamMap.get('registered');
    if (name?.trim()) {
      this.registeredNotice.set(name.trim());
    }
  }

  submit(): void {
    this.loginError.set(null);
    this.accessDenied.set(null);
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    const { username, password } = this.form.getRawValue();
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
