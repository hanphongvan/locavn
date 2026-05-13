import { CommonModule } from '@angular/common';
import { Component, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { MatDialog, MatDialogModule } from '@angular/material/dialog';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { Subject, switchMap, tap } from 'rxjs';
import { finalize } from 'rxjs/operators';

import { ApiRequestError } from '../../../core/http/api-request-error';
import { PageHeaderComponent, SectionCardComponent } from '../../../shared/ui';
import type { HttmCatalogItemDto, ProvinceOptionDto } from '../../httm/models/httm-facility.model';
import { HttmCatalogService } from '../../httm/services/httm-catalog.service';
import type { HttmSurveyListItemDto, HttmSurveySearchQuery } from '../models/survey.models';
import { SurveysApiService } from '../services/surveys-api.service';
import { SurveyCreateDialogComponent } from '../dialogs/survey-create-dialog.component';

@Component({
  selector: 'app-survey-list-page',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    RouterLink,
    MatDialogModule,
    MatSnackBarModule,
    PageHeaderComponent,
    SectionCardComponent,
  ],
  templateUrl: './survey-list-page.component.html',
  styleUrl: './survey-list-page.component.scss',
})
export class SurveyListPageComponent {
  private readonly fb = inject(FormBuilder);
  private readonly api = inject(SurveysApiService);
  private readonly catalogs = inject(HttmCatalogService);
  private readonly dialog = inject(MatDialog);
  private readonly snack = inject(MatSnackBar);
  private readonly router = inject(Router);

  readonly rows = signal<HttmSurveyListItemDto[]>([]);
  readonly totalCount = signal(0);
  readonly page = signal(1);
  readonly pageSize = signal(20);
  readonly loading = signal(false);
  readonly errorMessage = signal<string | null>(null);
  readonly provinces = signal<ProvinceOptionDto[]>([]);
  readonly typeItems = signal<HttmCatalogItemDto[]>([]);

  readonly filterForm = this.fb.nonNullable.group({
    q: [''],
    status: [''],
    provinceCode: [''],
    httmType: [''],
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

    this.refresh$
      .pipe(
        tap(() => this.loading.set(true)),
        switchMap(() => {
          const f = this.filterForm.getRawValue();
          const q: HttmSurveySearchQuery = {
            q: f.q || undefined,
            status: f.status || undefined,
            provinceCode: f.provinceCode || undefined,
            httmType: f.httmType || undefined,
            page: this.page(),
            pageSize: this.pageSize(),
          };
          return this.api.search(q).pipe(finalize(() => this.loading.set(false)));
        }),
        takeUntilDestroyed(),
      )
      .subscribe({
        next: (p) => {
          this.rows.set(p.items);
          this.totalCount.set(p.totalCount);
          this.errorMessage.set(null);
        },
        error: (e: unknown) => {
          this.rows.set([]);
          this.errorMessage.set(e instanceof ApiRequestError ? e.message : 'Không tải được danh sách.');
        },
      });

    queueMicrotask(() => this.refresh$.next());
  }

  applyFilters(): void {
    this.page.set(1);
    this.refresh$.next();
  }

  clearFilters(): void {
    this.filterForm.reset({ q: '', status: '', provinceCode: '', httmType: '' });
    this.page.set(1);
    this.refresh$.next();
  }

  prevPage(): void {
    if (this.page() <= 1) {
      return;
    }
    this.page.update((p) => p - 1);
    this.refresh$.next();
  }

  nextPage(): void {
    const maxPage = Math.max(1, Math.ceil(this.totalCount() / this.pageSize()));
    if (this.page() >= maxPage) {
      return;
    }
    this.page.update((p) => p + 1);
    this.refresh$.next();
  }

  totalPages(): number {
    return Math.max(1, Math.ceil(this.totalCount() / this.pageSize()));
  }

  openCreate(): void {
    const ref = this.dialog.open(SurveyCreateDialogComponent, {
      width: '420px',
      data: { provinces: this.provinces(), types: this.typeItems() },
    });
    ref.afterClosed().subscribe((v: { provinceCode: string; httmType: string } | undefined) => {
      if (!v) {
        return;
      }
      this.api.create({ provinceCode: v.provinceCode, httmType: v.httmType }).subscribe({
        next: (r) => {
          this.snack.open('Đã tạo phiếu nháp', 'Đóng', { duration: 3000 });
          void this.refresh$.next();
          void this.router.navigate(['/surveys', r.id]);
        },
        error: (e: unknown) =>
          this.snack.open(e instanceof ApiRequestError ? e.message : 'Lỗi tạo phiếu', 'Đóng', { duration: 5000 }),
      });
    });
  }
}
