import { CommonModule } from '@angular/common';
import { Component, OnDestroy, OnInit, computed, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatSelectModule } from '@angular/material/select';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import {
  Subject,
  catchError,
  distinctUntilChanged,
  finalize,
  forkJoin,
  of,
  switchMap,
  takeUntil,
} from 'rxjs';

import {
  PORTAL_LOAI_ADMIN,
  PORTAL_LOAI_SO_STAFF,
  PORTAL_LOAI_STORE,
  PORTAL_LOAI_TRADER,
} from '../../core/auth/portal-loai-role';
import type { DonViOptionDto, RoleOptionDto, UserDetailDto } from './user-management.models';
import { UserManagementService } from './user-management.service';

@Component({
  selector: 'app-user-management-form',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    RouterLink,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatButtonModule,
    MatProgressSpinnerModule,
    MatSnackBarModule,
  ],
  templateUrl: './user-management-form.component.html',
})
export class UserManagementFormComponent implements OnInit, OnDestroy {
  private readonly fb = inject(FormBuilder);
  private readonly api = inject(UserManagementService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly snack = inject(MatSnackBar);

  private readonly destroy$ = new Subject<void>();
  private readonly donViLoaiRequest$ = new Subject<number | null>();

  readonly mode = computed(() => (this.route.snapshot.data['mode'] as 'create' | 'edit') ?? 'create');
  readonly loading = signal(false);
  readonly donViLoading = signal(false);
  readonly roleOptions = signal<RoleOptionDto[]>([]);
  readonly donViOptions = signal<DonViOptionDto[]>([]);
  readonly donViListFilter = signal('');

  readonly filteredDonVi = computed(() => {
    const q = this.donViListFilter().trim().toLowerCase();
    const rows = this.donViOptions();
    if (!q) {
      return rows;
    }
    return rows.filter((d) => d.ma.toLowerCase().includes(q) || d.ten.toLowerCase().includes(q));
  });

  readonly form = this.fb.group({
    userName: this.fb.nonNullable.control('', { validators: [Validators.required] }),
    displayName: this.fb.control<string | null>(null),
    fullName: this.fb.control<string | null>(null),
    email: this.fb.control<string | null>(null, { validators: [Validators.email] }),
    phone: this.fb.control<string | null>(null),
    address: this.fb.control<string | null>(null),
    description: this.fb.control<string | null>(null),
    password: this.fb.control<string | null>(null),
    loai: this.fb.control<number | null>(null),
    donViId: this.fb.control<number | null>(null),
    roleIds: this.fb.nonNullable.control<string[]>([]),
    donViIds: this.fb.nonNullable.control<number[]>([]),
  });

  ngOnInit(): void {
    const m = this.mode();
    if (m === 'create') {
      this.form.controls.password.setValidators([Validators.required]);
      this.form.controls.password.updateValueAndValidity();
    }

    this.donViLoaiRequest$
      .pipe(
        takeUntil(this.destroy$),
        distinctUntilChanged((a, b) => a === b),
        switchMap((loai) => {
          if (!this.isFormLoaiForDonVi(loai)) {
            this.donViOptions.set([]);
            this.donViListFilter.set('');
            return of<DonViOptionDto[]>([]);
          }
          this.donViLoading.set(true);
          return this.api.donVi(loai!).pipe(
            catchError(() => {
              this.snack.open('Không tải được danh sách đơn vị.', 'Đóng');
              return of<DonViOptionDto[]>([]);
            }),
            finalize(() => this.donViLoading.set(false)),
          );
        }),
      )
      .subscribe((rows) => {
        this.donViOptions.set(rows);
        this.donViListFilter.set('');
      });

    this.form.controls.loai.valueChanges
      .pipe(takeUntil(this.destroy$), distinctUntilChanged())
      .subscribe((loai) => {
        this.form.patchValue({ donViId: null, donViIds: [] }, { emitEvent: false });
        this.donViLoaiRequest$.next(loai);
      });

    this.loading.set(true);
    const id = this.route.snapshot.paramMap.get('id');
    forkJoin({ roles: this.api.roles() })
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: ({ roles }) => {
          this.roleOptions.set(roles);
          if (m === 'edit' && id) {
            this.api
              .getById(id)
              .pipe(takeUntil(this.destroy$))
              .subscribe({
                next: (d) => this.patchFromDetail(d),
                error: () => {
                  this.loading.set(false);
                  this.snack.open('Không tải được chi tiết người dùng.', 'Đóng');
                  void this.router.navigate(['/users']);
                },
              });
          } else {
            this.loading.set(false);
          }
        },
        error: () => {
          this.loading.set(false);
          this.snack.open('Không tải danh sách roles.', 'Đóng');
        },
      });
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  isFormLoaiForDonVi(loai: number | null | undefined): boolean {
    return (
      loai === PORTAL_LOAI_ADMIN ||
      loai === PORTAL_LOAI_TRADER ||
      loai === PORTAL_LOAI_STORE ||
      loai === PORTAL_LOAI_SO_STAFF
    );
  }

  onDonViListFilterInput(ev: Event): void {
    const v = (ev.target as HTMLInputElement | null)?.value ?? '';
    this.donViListFilter.set(v);
  }

  private patchFromDetail(d: UserDetailDto): void {
    this.form.patchValue(
      {
        userName: d.userName,
        displayName: d.displayName,
        fullName: d.fullName,
        email: d.email,
        phone: d.phone,
        address: d.address,
        description: d.description,
        loai: d.loai,
        donViId: d.donViId,
        roleIds: d.roles.map((r) => r.roleId),
        donViIds: d.donVis.map((x) => x.donViId),
      },
      { emitEvent: false },
    );
    this.form.controls.userName.disable();
    this.donViLoaiRequest$.next(d.loai ?? null);
    this.loading.set(false);
  }

  submit(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    const loai = this.form.controls.loai.value;
    const donViId = this.form.controls.donViId.value;
    if (
      (loai === PORTAL_LOAI_TRADER || loai === PORTAL_LOAI_STORE) &&
      (donViId === null || donViId === undefined)
    ) {
      this.snack.open('Đơn vị bắt buộc với Loai 3 (Trader) hoặc 4 (Store).', 'OK');
      return;
    }

    if (this.mode() === 'create') {
      const v = this.form.getRawValue();
      this.api
        .create({
          userName: v.userName,
          displayName: v.displayName,
          fullName: v.fullName,
          email: v.email,
          phone: v.phone,
          address: v.address,
          description: v.description,
          password: v.password ?? '',
          donViId: v.donViId,
          loai: v.loai,
          roleIds: v.roleIds,
          donViIds: v.donViIds,
        })
        .pipe(takeUntil(this.destroy$))
        .subscribe({
          next: (r) => {
            this.snack.open('Đã tạo người dùng.', 'OK');
            void this.router.navigate(['/users', r.id]);
          },
          error: () => this.snack.open('Tạo thất bại.', 'Đóng'),
        });
    } else {
      const id = this.route.snapshot.paramMap.get('id');
      if (!id) {
        return;
      }
      const v = this.form.getRawValue();
      this.api
        .update(id, {
          displayName: v.displayName,
          fullName: v.fullName,
          email: v.email,
          phone: v.phone,
          address: v.address,
          description: v.description,
          password: v.password?.trim() ? v.password : undefined,
          donViId: v.donViId,
          loai: v.loai,
          roleIds: v.roleIds,
          donViIds: v.donViIds,
        })
        .pipe(takeUntil(this.destroy$))
        .subscribe({
          next: () => {
            this.snack.open('Đã cập nhật.', 'OK');
            void this.router.navigate(['/users']);
          },
          error: () => this.snack.open('Cập nhật thất bại.', 'Đóng'),
        });
    }
  }

  cancel(): void {
    void this.router.navigate(['/users']);
  }

  /** TODO: map từ API quyền quyen_them / quyen_sua / quyen_xoa khi backend cung cấp. */
  readonly permissionsNote =
    'Phân quyền chi tiết (quyen_them / quyen_sua / quyen_xoa) chưa nối API — hiện route đã giới hạn Admin.';
}
