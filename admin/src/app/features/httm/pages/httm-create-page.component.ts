import { CommonModule } from '@angular/common';
import { Component, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { take } from 'rxjs';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';

import { ApiRequestError } from '../../../core/http/api-request-error';
import { PageHeaderComponent, SectionCardComponent } from '../../../shared/ui';
import type { HttmCatalogItemDto, ProvinceOptionDto } from '../models/httm-facility.model';
import { HttmCatalogService } from '../services/httm-catalog.service';
import { HttmFacilityService } from '../services/httm-facility.service';

@Component({
  selector: 'app-httm-create-page',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink, PageHeaderComponent, SectionCardComponent],
  templateUrl: './httm-create-page.component.html',
})
export class HttmCreatePageComponent {
  private readonly fb = inject(FormBuilder);
  private readonly api = inject(HttmFacilityService);
  private readonly catalogs = inject(HttmCatalogService);
  private readonly router = inject(Router);

  readonly provinces = signal<ProvinceOptionDto[]>([]);
  readonly typeItems = signal<HttmCatalogItemDto[]>([]);
  readonly statusItems = signal<HttmCatalogItemDto[]>([]);
  readonly saving = signal(false);
  readonly errorMessage = signal<string | null>(null);

  readonly form = this.fb.nonNullable.group({
    name: ['', [Validators.required, Validators.maxLength(500)]],
    httmType: ['', Validators.required],
    status: ['', Validators.required],
    provinceCode: ['', Validators.required],
    addressDetail: [''],
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
  }

  submit(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    const v = this.form.getRawValue();
    this.saving.set(true);
    this.errorMessage.set(null);
    this.api
      .create({
        name: v.name.trim(),
        httmType: v.httmType,
        status: v.status,
        provinceCode: v.provinceCode,
        addressDetail: v.addressDetail.trim() || undefined,
        notes: v.notes.trim() || undefined,
      })
      .pipe(take(1))
      .subscribe({
        next: (res) => {
          this.saving.set(false);
          void this.router.navigate(['/httm', res.id]);
        },
        error: (err: unknown) => {
          this.saving.set(false);
          this.errorMessage.set(err instanceof ApiRequestError ? err.message : 'Không tạo được hồ sơ.');
        },
      });
  }
}
