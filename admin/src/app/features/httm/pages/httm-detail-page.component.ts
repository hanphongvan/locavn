import { CommonModule } from '@angular/common';
import { Component, computed, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { MatTabsModule } from '@angular/material/tabs';
import { EMPTY, switchMap, take } from 'rxjs';

import { AdminAuthService } from '../../../core/auth/admin-auth.service';
import { ApiRequestError } from '../../../core/http/api-request-error';
import { PageHeaderComponent } from '../../../shared/ui';
import type {
  HttmAuditLogDto,
  HttmCatalogItemDto,
  HttmFacilityDto,
  HttmFacilityLicenseDto,
  HttmFacilityLicenseUpsertRequest,
  ProvinceOptionDto,
} from '../models/httm-facility.model';
import { HttmImageGalleryComponent } from '../components/httm-image-gallery.component';
import { HttmLicenseCardComponent } from '../components/httm-license-card.component';
import { HttmCatalogService } from '../services/httm-catalog.service';
import { HttmFacilityService } from '../services/httm-facility.service';

@Component({
  selector: 'app-httm-detail-page',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    RouterLink,
    MatTabsModule,
    MatSnackBarModule,
    PageHeaderComponent,
    HttmImageGalleryComponent,
    HttmLicenseCardComponent,
  ],
  templateUrl: './httm-detail-page.component.html',
  styleUrl: './httm-detail-page.component.scss',
})
export class HttmDetailPageComponent {
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly api = inject(HttmFacilityService);
  private readonly catalogs = inject(HttmCatalogService);
  private readonly auth = inject(AdminAuthService);
  private readonly fb = inject(FormBuilder);
  private readonly snack = inject(MatSnackBar);

  readonly facility = signal<HttmFacilityDto | null>(null);
  readonly licenses = signal<HttmFacilityLicenseDto[]>([]);
  readonly auditItems = signal<HttmAuditLogDto[]>([]);
  readonly auditTotal = signal(0);
  readonly loading = signal(true);
  readonly errorMessage = signal<string | null>(null);
  readonly savingGeneral = signal(false);
  readonly savingLicense = signal(false);

  readonly provinces = signal<ProvinceOptionDto[]>([]);
  readonly typeItems = signal<HttmCatalogItemDto[]>([]);
  readonly statusItems = signal<HttmCatalogItemDto[]>([]);

  readonly canDelete = computed(() => {
    const r = this.auth.portalRole();
    return r === 'ADMIN' || r === 'HTTM_ADMIN';
  });

  readonly generalForm = this.fb.nonNullable.group({
    name: ['', [Validators.required, Validators.maxLength(500)]],
    httmType: ['', Validators.required],
    status: ['', Validators.required],
    provinceCode: ['', Validators.required],
    addressDetail: [''],
    notes: [''],
  });

  readonly licenseForm = this.fb.nonNullable.group({
    licenseType: ['', Validators.required],
    licenseNumber: [''],
    issuedDate: [''],
    expiryDate: [''],
    issuedBy: [''],
    fileUrl: [''],
    notes: [''],
  });

  constructor() {
    this.catalogs
      .provinces()
      .pipe(takeUntilDestroyed())
      .subscribe({ next: (r) => this.provinces.set(r), error: () => this.provinces.set([]) });
    this.catalogs
      .getByType('httm_types')
      .pipe(takeUntilDestroyed())
      .subscribe({ next: (r) => this.typeItems.set(r), error: () => this.typeItems.set([]) });
    this.catalogs
      .getByType('operation_statuses')
      .pipe(takeUntilDestroyed())
      .subscribe({ next: (r) => this.statusItems.set(r), error: () => this.statusItems.set([]) });

    this.route.paramMap
      .pipe(
        switchMap((pm) => {
          const id = pm.get('id');
          if (!id) {
            this.errorMessage.set('Thiếu mã hồ sơ.');
            this.loading.set(false);
            return EMPTY;
          }
          this.loading.set(true);
          this.errorMessage.set(null);
          return this.api.getById(id).pipe(take(1));
        }),
        takeUntilDestroyed(),
      )
      .subscribe({
        next: (f) => {
          this.facility.set(f);
          this.patchGeneralForm(f);
          this.loading.set(false);
          this.reloadSideData(f.id);
        },
        error: (err: unknown) => {
          this.loading.set(false);
          this.errorMessage.set(err instanceof ApiRequestError ? err.message : 'Không tải được hồ sơ.');
        },
      });
  }

  saveGeneral(): void {
    const f = this.facility();
    if (!f || this.generalForm.invalid) {
      this.generalForm.markAllAsTouched();
      return;
    }
    const v = this.generalForm.getRawValue();
    this.savingGeneral.set(true);
    this.api
      .patch(f.id, {
        name: v.name.trim(),
        httmType: v.httmType,
        status: v.status,
        provinceCode: v.provinceCode,
        addressDetail: v.addressDetail.trim() || null,
        notes: v.notes.trim() || null,
      })
      .pipe(take(1))
      .subscribe({
        next: () => {
          this.savingGeneral.set(false);
          this.snack.open('Đã lưu thông tin chung.', 'Đóng', { duration: 4000 });
          this.api
            .getById(f.id)
            .pipe(take(1))
            .subscribe({
              next: (nf) => {
                this.facility.set(nf);
                this.patchGeneralForm(nf);
              },
            });
        },
        error: (err: unknown) => {
          this.savingGeneral.set(false);
          this.snack.open(
            err instanceof ApiRequestError ? err.message : 'Lưu thất bại.',
            'Đóng',
            { duration: 6000 },
          );
        },
      });
  }

  addLicense(): void {
    const f = this.facility();
    if (!f || this.licenseForm.invalid) {
      this.licenseForm.markAllAsTouched();
      return;
    }
    const v = this.licenseForm.getRawValue();
    const body: HttmFacilityLicenseUpsertRequest = {
      licenseType: v.licenseType,
      licenseNumber: v.licenseNumber.trim() || undefined,
      issuedDate: v.issuedDate || undefined,
      expiryDate: v.expiryDate || undefined,
      issuedBy: v.issuedBy.trim() || undefined,
      fileUrl: v.fileUrl.trim() || undefined,
      notes: v.notes.trim() || undefined,
    };
    this.savingLicense.set(true);
    this.api
      .upsertLicense(f.id, body)
      .pipe(take(1))
      .subscribe({
        next: () => {
          this.savingLicense.set(false);
          this.licenseForm.reset({ licenseType: '', licenseNumber: '', issuedDate: '', expiryDate: '', issuedBy: '', fileUrl: '', notes: '' });
          this.snack.open('Đã thêm / cập nhật giấy phép.', 'Đóng', { duration: 4000 });
          this.reloadLicenses(f.id);
        },
        error: (err: unknown) => {
          this.savingLicense.set(false);
          this.snack.open(
            err instanceof ApiRequestError ? err.message : 'Không lưu được giấy phép.',
            'Đóng',
            { duration: 6000 },
          );
        },
      });
  }

  removeLicense(licenseId: string): void {
    const f = this.facility();
    if (!f) {
      return;
    }
    this.api
      .deleteLicense(f.id, licenseId)
      .pipe(take(1))
      .subscribe({
        next: () => {
          this.snack.open('Đã xoá giấy phép.', 'Đóng', { duration: 4000 });
          this.reloadLicenses(f.id);
        },
        error: (err: unknown) => {
          this.snack.open(
            err instanceof ApiRequestError ? err.message : 'Không xoá được.',
            'Đóng',
            { duration: 6000 },
          );
        },
      });
  }

  onImageSelected(ev: Event): void {
    const f = this.facility();
    const input = ev.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!f || !file) {
      return;
    }
    this.api
      .uploadImage(f.id, file, 'exterior', null, null, 0)
      .pipe(take(1))
      .subscribe({
        next: () => {
          this.snack.open('Đã tải ảnh lên.', 'Đóng', { duration: 4000 });
          input.value = '';
        },
        error: (err: unknown) => {
          this.snack.open(
            err instanceof ApiRequestError ? err.message : 'Tải ảnh thất bại.',
            'Đóng',
            { duration: 6000 },
          );
        },
      });
  }

  deleteFacility(): void {
    const f = this.facility();
    if (!f || !this.canDelete()) {
      return;
    }
    if (!globalThis.confirm('Xoá vĩnh viễn hồ sơ này?')) {
      return;
    }
    this.api
      .delete(f.id)
      .pipe(take(1))
      .subscribe({
        next: () => {
          void this.router.navigate(['/httm']);
        },
        error: (err: unknown) => {
          this.snack.open(
            err instanceof ApiRequestError ? err.message : 'Không xoá được.',
            'Đóng',
            { duration: 6000 },
          );
        },
      });
  }

  private patchGeneralForm(f: HttmFacilityDto): void {
    this.generalForm.patchValue({
      name: f.name,
      httmType: f.httmType,
      status: f.status,
      provinceCode: f.provinceCode,
      addressDetail: f.addressDetail ?? '',
      notes: f.notes ?? '',
    });
  }

  private reloadSideData(id: string): void {
    this.reloadLicenses(id);
    this.reloadAudit(id);
  }

  private reloadLicenses(id: string): void {
    this.api
      .listLicenses(id)
      .pipe(take(1))
      .subscribe({
        next: (rows) => this.licenses.set(rows),
        error: () => this.licenses.set([]),
      });
  }

  private reloadAudit(id: string): void {
    this.api
      .getAuditLogs(id, 1, 50)
      .pipe(take(1))
      .subscribe({
        next: (p) => {
          this.auditItems.set(p.items);
          this.auditTotal.set(p.totalCount);
        },
        error: () => {
          this.auditItems.set([]);
          this.auditTotal.set(0);
        },
      });
  }
}
