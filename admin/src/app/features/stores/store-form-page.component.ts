import { CommonModule } from '@angular/common';
import { Component, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { EMPTY, of } from 'rxjs';
import { catchError, distinctUntilChanged, finalize, map, switchMap, tap } from 'rxjs/operators';

import { ApiRequestError } from '../../core/http/api-request-error';
import type { StoreAdminStoreDto, StoreAdminStoreUpsertRequest } from './models/store-admin-store.models';
import { StoresApiService } from './services/stores-api.service';
import { STORE_FIELD_MAX } from './store-form.constants';
import { optionalEmail, optionalLatitude, optionalLongitude } from './store-validators';

/** Empty string → `null` so JSON clears nullable backend fields. */
function strOrNull(s: string | null | undefined): string | null {
  if (s === null || s === undefined) {
    return null;
  }
  const t = String(s).trim();
  return t === '' ? null : t;
}

/** Backend `TimeOnly` — send `HH:mm:ss` when user picked a time. */
function normalizeTimeForApi(v: string | null | undefined): string | null {
  if (v === null || v === undefined || v === '') {
    return null;
  }
  const s = String(v).trim();
  if (s.length === 5 && s[2] === ':') {
    return `${s}:00`;
  }
  return s;
}

function toTimeInputValue(api: string | null | undefined): string | null {
  if (!api) {
    return null;
  }
  const s = String(api).trim();
  return s.length >= 5 ? s.slice(0, 5) : s;
}

function parseNullableInt(v: unknown): number | null {
  if (v === null || v === undefined || v === '') {
    return null;
  }
  const n = typeof v === 'number' ? v : Number(v);
  return Number.isFinite(n) ? n : null;
}

function parseNullableDecimal(v: unknown): number | null {
  if (v === null || v === undefined || v === '') {
    return null;
  }
  const n = typeof v === 'number' ? v : Number(v);
  return Number.isFinite(n) ? n : null;
}

@Component({
  selector: 'app-store-form-page',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: './store-form-page.component.html',
})
export class StoreFormPageComponent {
  private readonly fb = inject(FormBuilder);
  private readonly api = inject(StoresApiService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);

  readonly STORE_FIELD_MAX = STORE_FIELD_MAX;

  readonly loading = signal(false);
  readonly saving = signal(false);
  readonly errorMessage = signal<string | null>(null);
  readonly storeId = signal<number | null>(null);

  readonly form = this.fb.group({
    ma: ['', [Validators.required, Validators.maxLength(STORE_FIELD_MAX.ma)]],
    ten: ['', [Validators.required, Validators.maxLength(STORE_FIELD_MAX.ten)]],
    dienThoai: ['', [Validators.maxLength(STORE_FIELD_MAX.dienThoai)]],
    diaChi: ['', [Validators.maxLength(STORE_FIELD_MAX.diaChi)]],
    email: ['', [Validators.maxLength(STORE_FIELD_MAX.email), optionalEmail()]],
    trangThai: this.fb.control<boolean | null>(null),
    tinh: this.fb.control<number | null>(null),
    xa: this.fb.control<number | null>(null),
    diaChiChiTiet: ['', [Validators.maxLength(STORE_FIELD_MAX.diaChiChiTiet)]],
    viDo: this.fb.control<number | null>(null, { validators: [optionalLatitude()] }),
    kinhDo: this.fb.control<number | null>(null, { validators: [optionalLongitude()] }),
    openTime: [''],
    closeTime: [''],
  });

  constructor() {
    this.route.paramMap
      .pipe(
        map((pm) => pm.get('id')),
        map((idStr) => {
          if (idStr === null || idStr === '') {
            return null;
          }
          const n = Number(idStr);
          return Number.isFinite(n) ? n : null;
        }),
        distinctUntilChanged(),
        tap(() => {
          this.errorMessage.set(null);
        }),
        switchMap((id) => {
          if (id === null) {
            this.storeId.set(null);
            this.resetForCreate();
            return of(null);
          }
          this.storeId.set(id);
          this.loading.set(true);
          return this.api.getById(id).pipe(
            tap((dto) => this.patchFromDto(dto)),
            catchError((err: unknown) => {
              this.errorMessage.set(
                err instanceof ApiRequestError ? err.message : 'Không tải được cửa hàng.',
              );
              return EMPTY;
            }),
            finalize(() => this.loading.set(false)),
          );
        }),
        takeUntilDestroyed(),
      )
      .subscribe();
  }

  isEditMode(): boolean {
    return this.storeId() !== null;
  }

  pageTitle(): string {
    return this.isEditMode() ? 'Sửa cửa hàng' : 'Thêm cửa hàng';
  }

  submit(): void {
    this.form.markAllAsTouched();
    if (this.form.invalid) {
      return;
    }
    const body = this.buildUpsertRequest();
    this.saving.set(true);
    this.errorMessage.set(null);
    const id = this.storeId();
    const req$ = id !== null ? this.api.update(id, body) : this.api.create(body);
    req$.pipe(finalize(() => this.saving.set(false))).subscribe({
      next: () => void this.router.navigateByUrl('/stores'),
      error: (err: unknown) => {
        this.errorMessage.set(err instanceof ApiRequestError ? err.message : 'Lưu thất bại.');
      },
    });
  }

  cancel(): void {
    void this.router.navigateByUrl('/stores');
  }

  private resetForCreate(): void {
    this.form.reset({
      ma: '',
      ten: '',
      dienThoai: '',
      diaChi: '',
      email: '',
      trangThai: null,
      tinh: null,
      xa: null,
      diaChiChiTiet: '',
      viDo: null,
      kinhDo: null,
      openTime: '',
      closeTime: '',
    });
  }

  private patchFromDto(d: StoreAdminStoreDto): void {
    this.form.patchValue({
      ma: d.ma,
      ten: d.ten,
      dienThoai: d.dienThoai ?? '',
      diaChi: d.diaChi ?? '',
      email: d.email ?? '',
      trangThai: d.trangThai,
      tinh: d.tinh,
      xa: d.xa,
      diaChiChiTiet: d.diaChiChiTiet ?? '',
      viDo: d.viDo,
      kinhDo: d.kinhDo,
      openTime: toTimeInputValue(d.openTime) ?? '',
      closeTime: toTimeInputValue(d.closeTime) ?? '',
    });
  }

  private buildUpsertRequest(): StoreAdminStoreUpsertRequest {
    const v = this.form.getRawValue();
    return {
      ma: (v.ma ?? '').trim(),
      ten: (v.ten ?? '').trim(),
      dienThoai: strOrNull(v.dienThoai),
      diaChi: strOrNull(v.diaChi),
      email: strOrNull(v.email),
      trangThai: v.trangThai,
      tinh: parseNullableInt(v.tinh),
      xa: parseNullableInt(v.xa),
      diaChiChiTiet: strOrNull(v.diaChiChiTiet),
      viDo: parseNullableDecimal(v.viDo),
      kinhDo: parseNullableDecimal(v.kinhDo),
      openTime: normalizeTimeForApi(v.openTime),
      closeTime: normalizeTimeForApi(v.closeTime),
    };
  }
}
