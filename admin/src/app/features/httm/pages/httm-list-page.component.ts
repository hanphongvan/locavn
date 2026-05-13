import { CommonModule } from '@angular/common';
import { Component, computed, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { Subject, switchMap, tap } from 'rxjs';
import { finalize } from 'rxjs/operators';

import { AdminAuthService } from '../../../core/auth/admin-auth.service';
import { HTTM_PORTAL_ROLES } from '../../../core/auth/portal-route-roles.config';
import { ApiRequestError } from '../../../core/http/api-request-error';
import { PageHeaderComponent, SectionCardComponent } from '../../../shared/ui';
import type { HttmCatalogItemDto, HttmFacilityListItemDto, HttmFacilitySearchQuery, ProvinceOptionDto } from '../models/httm-facility.model';
import { HttmCatalogService } from '../services/httm-catalog.service';
import { HttmFacilityService } from '../services/httm-facility.service';
import { HttmFilterBarComponent } from '../components/httm-filter-bar.component';
import { HttmTypeBadgeComponent } from '../components/httm-type-badge.component';
import { HttmStatusBadgeComponent } from '../components/httm-status-badge.component';

@Component({
  selector: 'app-httm-list-page',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    RouterLink,
    PageHeaderComponent,
    HttmFilterBarComponent,
    SectionCardComponent,
    HttmTypeBadgeComponent,
    HttmStatusBadgeComponent,
  ],
  templateUrl: './httm-list-page.component.html',
  styleUrl: './httm-list-page.component.scss',
})
export class HttmListPageComponent {
  private readonly fb = inject(FormBuilder);
  private readonly api = inject(HttmFacilityService);
  private readonly catalogs = inject(HttmCatalogService);
  private readonly auth = inject(AdminAuthService);

  readonly canOpenCreate = computed(() => {
    const r = this.auth.portalRole();
    return !!r && (HTTM_PORTAL_ROLES as readonly string[]).includes(r);
  });

  readonly items = signal<HttmFacilityListItemDto[]>([]);
  readonly totalCount = signal(0);
  readonly page = signal(1);
  readonly pageSize = signal(20);
  readonly loading = signal(false);
  readonly errorMessage = signal<string | null>(null);
  readonly provinces = signal<ProvinceOptionDto[]>([]);
  readonly typeItems = signal<HttmCatalogItemDto[]>([]);
  readonly statusItems = signal<HttmCatalogItemDto[]>([]);

  readonly filterForm = this.fb.nonNullable.group({
    q: [''],
    httmType: [''],
    provinceCode: [''],
    status: [''],
  });

  private readonly refresh$ = new Subject<void>();

  constructor() {
    this.catalogs
      .provinces()
      .pipe(takeUntilDestroyed())
      .subscribe({
        next: (rows) => this.provinces.set(rows),
        error: () => this.provinces.set([]),
      });

    this.catalogs
      .getByType('httm_types')
      .pipe(takeUntilDestroyed())
      .subscribe({
        next: (rows) => this.typeItems.set(rows),
        error: () => this.typeItems.set([]),
      });

    this.catalogs
      .getByType('operation_statuses')
      .pipe(takeUntilDestroyed())
      .subscribe({
        next: (rows) => this.statusItems.set(rows),
        error: () => this.statusItems.set([]),
      });

    this.refresh$
      .pipe(
        tap(() => {
          this.loading.set(true);
          this.errorMessage.set(null);
        }),
        switchMap(() =>
          this.api.search(this.buildQuery()).pipe(finalize(() => this.loading.set(false))),
        ),
        takeUntilDestroyed(),
      )
      .subscribe({
        next: (page) => {
          this.items.set(page.items);
          this.totalCount.set(page.totalCount);
        },
        error: (err: unknown) => {
          this.items.set([]);
          this.errorMessage.set(
            err instanceof ApiRequestError ? err.message : 'Không tải được danh sách HTTM.',
          );
        },
      });

    queueMicrotask(() => this.refresh$.next());
  }

  applyFilters(): void {
    this.page.set(1);
    this.refresh$.next();
  }

  clearFilters(): void {
    this.filterForm.reset({ q: '', httmType: '', provinceCode: '', status: '' });
    this.page.set(1);
    this.refresh$.next();
  }

  setPage(n: number): void {
    const next = Math.max(1, n);
    this.page.set(next);
    this.refresh$.next();
  }

  typeName(code: string): string {
    return this.typeItems().find((x) => x.code === code)?.name ?? code;
  }

  statusName(code: string): string {
    return this.statusItems().find((x) => x.code === code)?.name ?? code;
  }

  totalPages(): number {
    return Math.max(1, Math.ceil(this.totalCount() / this.pageSize()));
  }

  private buildQuery(): HttmFacilitySearchQuery {
    const v = this.filterForm.getRawValue();
    return {
      q: v.q.trim() || undefined,
      httmType: v.httmType || undefined,
      provinceCode: v.provinceCode || undefined,
      status: v.status || undefined,
      page: this.page(),
      pageSize: this.pageSize(),
    };
  }
}
