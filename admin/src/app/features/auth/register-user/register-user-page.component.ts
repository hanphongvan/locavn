import { HttpErrorResponse } from '@angular/common/http';
import { Component, OnInit, inject, signal } from '@angular/core';
import {
  AbstractControl,
  NonNullableFormBuilder,
  ReactiveFormsModule,
  ValidationErrors,
  ValidatorFn,
  Validators,
} from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatCheckboxModule } from '@angular/material/checkbox';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatSelectModule } from '@angular/material/select';
import { Router, RouterLink } from '@angular/router';
import { forkJoin } from 'rxjs';

import { readProblemDetailsDetail } from '../../../core/auth/oauth-http-error.util';
import { SectionCardComponent } from '../../../shared/ui';
import { RegisterUserApiService } from './register-user-api.service';
import type { RegisterDonViOptionDto, RegisterRoleOptionDto } from './register-user.models';

function optionalEmail(): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    const v = (control.value as string | null | undefined)?.trim();
    if (!v) {
      return null;
    }
    return Validators.email(control);
  };
}

@Component({
  selector: 'app-register-user-page',
  standalone: true,
  imports: [
    ReactiveFormsModule,
    RouterLink,
    SectionCardComponent,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatCheckboxModule,
    MatButtonModule,
    MatProgressSpinnerModule,
  ],
  templateUrl: './register-user-page.component.html',
  styleUrl: './register-user-page.component.scss',
})
export class RegisterUserPageComponent implements OnInit {
  private readonly fb = inject(NonNullableFormBuilder);
  private readonly api = inject(RegisterUserApiService);
  private readonly router = inject(Router);

  readonly loaiOptions = [
    { value: 5, label: 'Mặc định (Loại 5)' },
    { value: 3, label: 'Loại 3 — bắt buộc đơn vị' },
    { value: 4, label: 'Loại 4 — bắt buộc đơn vị' },
  ] as const;

  readonly form = this.fb.group({
    userName: this.fb.control('', { validators: [Validators.required] }),
    displayName: this.fb.control('', { validators: [Validators.required] }),
    password: this.fb.control('', { validators: [Validators.required, Validators.minLength(6)] }),
    confirmPassword: this.fb.control('', {
      validators: [Validators.required, RegisterUserPageComponent.sameAsPassword],
    }),
    email: this.fb.control<string>('', { validators: [optionalEmail()] }),
    phone: this.fb.control<string>(''),
    address: this.fb.control<string>(''),
    loai: this.fb.control<number>(5, { validators: [Validators.required] }),
    donViId: this.fb.control<number | null>(null),
    /** Legacy: maps to AspNetUsers.LockoutEnabled — checked = tài khoản bị khóa. */
    isActived: this.fb.control(false),
  });

  readonly rolesOptions = signal<RegisterRoleOptionDto[]>([]);
  readonly donViOptions = signal<RegisterDonViOptionDto[]>([]);
  /** Role Id → checked */
  readonly roleChecked = signal<Record<string, boolean>>({});
  /** DonVi Id → checked */
  readonly dvChecked = signal<Record<number, boolean>>({});

  readonly loadError = signal<string | null>(null);
  readonly submitError = signal<string | null>(null);
  readonly loading = signal(false);
  readonly submitting = signal(false);
  readonly usernameTaken = signal<boolean | null>(null);

  ngOnInit(): void {
    this.loading.set(true);
    forkJoin({ roles: this.api.getRoles(), donVis: this.api.getDonVis() }).subscribe({
      next: ({ roles, donVis }) => {
        this.rolesOptions.set(roles);
        const rc: Record<string, boolean> = {};
        for (const r of roles) {
          rc[r.id] = false;
        }
        this.roleChecked.set(rc);

        this.donViOptions.set(donVis);
        const dc: Record<number, boolean> = {};
        for (const d of donVis) {
          dc[d.id] = false;
        }
        this.dvChecked.set(dc);

        this.loading.set(false);
      },
      error: () => {
        this.loadError.set('Không tải được danh sách vai trò / đơn vị. Vui lòng thử lại sau.');
        this.loading.set(false);
      },
    });

    this.form.controls.loai.valueChanges.subscribe((loai) => {
      const c = this.form.controls.donViId;
      if (loai === 3 || loai === 4) {
        c.setValidators([Validators.required]);
      } else {
        c.clearValidators();
      }
      c.updateValueAndValidity({ emitEvent: false });
    });

    this.form.controls.password.valueChanges.subscribe(() => {
      this.form.controls.confirmPassword.updateValueAndValidity({ emitEvent: false });
    });
  }

  private static sameAsPassword(control: AbstractControl): ValidationErrors | null {
    const parent = control.parent;
    const pw = parent?.get('password')?.value as string | undefined;
    const cp = control.value as string | undefined;
    if (!pw || !cp || pw === cp) {
      return null;
    }
    return { confirmMismatch: true };
  }

  onUsernameBlur(): void {
    const u = this.form.controls.userName.value?.trim();
    this.usernameTaken.set(null);
    if (!u) {
      return;
    }
    this.api.checkUsername(u).subscribe({
      next: (r) => this.usernameTaken.set(r.taken),
      error: () => this.usernameTaken.set(null),
    });
  }

  toggleRole(roleId: string, checked: boolean): void {
    this.roleChecked.update((m) => ({ ...m, [roleId]: checked }));
  }

  toggleDv(donViId: number, checked: boolean): void {
    this.dvChecked.update((m) => ({ ...m, [donViId]: checked }));
  }

  submit(): void {
    this.submitError.set(null);
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    const loai = this.form.controls.loai.value;
    const donViId = this.form.controls.donViId.value;
    if ((loai === 3 || loai === 4) && (donViId == null || donViId <= 0)) {
      this.form.controls.donViId.markAsTouched();
      return;
    }

    const userName = this.form.controls.userName.value.trim();
    if (this.usernameTaken() === true) {
      this.submitError.set('Tên đã tồn tại.');
      return;
    }

    const roles = this.rolesOptions().map((r) => ({
      id: r.id,
      name: r.name,
      checked: this.roleChecked()[r.id] === true,
    }));

    const dVs = this.donViOptions().map((d) => ({
      id: d.id,
      name: d.name,
      checked: this.dvChecked()[d.id] === true,
    }));

    const raw = this.form.getRawValue();
    const body = {
      userName,
      displayName: raw.displayName.trim(),
      password: raw.password,
      confirmPassword: raw.confirmPassword,
      email: raw.email?.trim() ? raw.email.trim() : null,
      phone: raw.phone?.trim() ? raw.phone.trim() : null,
      address: raw.address?.trim() ? raw.address.trim() : null,
      isActived: raw.isActived,
      loai,
      donViId: loai === 3 || loai === 4 ? donViId : null,
      roles,
      dVs,
    };

    this.submitting.set(true);
    this.api.register(body).subscribe({
      next: (res) => {
        this.submitting.set(false);
        void this.router.navigate(['/login'], {
          queryParams: { registered: res.userName },
        });
      },
      error: (err: unknown) => {
        this.submitting.set(false);
        if (err instanceof HttpErrorResponse && err.status === 400) {
          this.submitError.set(readProblemDetailsDetail(err) ?? 'Đăng ký không thành công.');
          return;
        }
        this.submitError.set('Lỗi máy chủ. Vui lòng thử lại.');
      },
    });
  }
}
