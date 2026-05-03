import { CommonModule } from '@angular/common';
import { Component, computed, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { Subject, switchMap, tap } from 'rxjs';
import { finalize } from 'rxjs/operators';

import { AdminAuthService } from '../../core/auth/admin-auth.service';
import { ApiRequestError } from '../../core/http/api-request-error';
import {
  FilterPanelComponent,
  PageHeaderComponent,
  SectionCardComponent,
  StatusBadgeComponent,
  TableWrapperComponent,
} from '../../shared/ui';
import type { StoreAdminStoreDto, StoreAdminStoreListQuery } from './models/store-admin-store.models';
import { StoresApiService } from './services/stores-api.service';
import { STORE_LIST_DEFAULT_TAKE, STORE_LIST_MAX_TAKE, STORE_FIELD_MAX } from './store-form.constants';

@Component({
  selector: 'app-store-list-page',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    RouterLink,
    PageHeaderComponent,
    FilterPanelComponent,
    SectionCardComponent,
    TableWrapperComponent,
    StatusBadgeComponent,
  ],
  templateUrl: './store-list-page.component.html',
  styleUrl: './store-list-page.component.scss',
})
export class StoreListPageComponent {
  readonly STORE_FIELD_MAX = STORE_FIELD_MAX;

  private readonly fb = inject(FormBuilder);
  private readonly api = inject(StoresApiService);
  private readonly auth = inject(AdminAuthService);
  private readonly refresh$ = new Subject<void>();

  /** Chỉ ADMIN được tạo cửa hàng mới (đồng bộ với API và route `stores/new`). */
  readonly showCreateStore = computed(() => this.auth.portalRole() === 'ADMIN');

  readonly items = signal<StoreAdminStoreDto[]>([]);
  readonly totalCount = signal(0);
  readonly skip = signal(0);
  readonly take = signal(STORE_LIST_DEFAULT_TAKE);
  readonly loading = signal(false);
  readonly errorMessage = signal<string | null>(null);

  readonly filterForm = this.fb.nonNullable.group({
    ma: ['', [Validators.maxLength(STORE_FIELD_MAX.ma)]],
    ten: ['', [Validators.maxLength(STORE_FIELD_MAX.ten)]],
    tinh: this.fb.control<number | null>(null),
    trangThai: this.fb.control<'any' | 'true' | 'false'>('any'),
  });

  readonly takeOptions = [25, 50, 100, 200] as const;

  constructor() {
    this.refresh$
      .pipe(
        tap(() => {
          this.loading.set(true);
          this.errorMessage.set(null);
        }),
        switchMap(() =>
          this.api.list(this.buildQuery()).pipe(finalize(() => this.loading.set(false))),
        ),
        takeUntilDestroyed(),
      )
      .subscribe({
        next: (page) => {
          this.items.set(page.items);
          this.totalCount.set(page.totalCount);
          this.skip.set(page.skip);
          this.take.set(page.take);
        },
        error: (err: unknown) => {
          this.items.set([]);
          this.errorMessage.set(err instanceof ApiRequestError ? err.message : 'Không tải được danh sách cửa hàng.');
        },
      });

    queueMicrotask(() => this.refresh$.next());
  }

  applyFilters(): void {
    this.skip.set(0);
    this.refresh$.next();
  }

  clearFilters(): void {
    this.filterForm.reset({
      ma: '',
      ten: '',
      tinh: null,
      trangThai: 'any',
    });
    this.skip.set(0);
    this.refresh$.next();
  }

  setTake(n: number): void {
    const v = Math.min(Math.max(1, n), STORE_LIST_MAX_TAKE);
    this.take.set(v);
    this.skip.set(0);
    this.refresh$.next();
  }

  prevPage(): void {
    const next = Math.max(0, this.skip() - this.take());
    this.skip.set(next);
    this.refresh$.next();
  }

  nextPage(): void {
    const next = this.skip() + this.take();
    if (next < this.totalCount()) {
      this.skip.set(next);
      this.refresh$.next();
    }
  }

  rangeLabel(): string {
    const total = this.totalCount();
    if (total === 0) {
      return 'Không có dòng';
    }
    const from = this.skip() + 1;
    const to = Math.min(this.skip() + this.items().length, total);
    return `${from}–${to} / ${total}`;
  }

  private buildQuery(): StoreAdminStoreListQuery {
    const f = this.filterForm.getRawValue();
    const q: StoreAdminStoreListQuery = {
      skip: this.skip(),
      take: this.take(),
    };
    const ma = f.ma?.trim();
    const ten = f.ten?.trim();
    if (ma) {
      q.ma = ma;
    }
    if (ten) {
      q.ten = ten;
    }
    if (f.tinh !== null && f.tinh !== undefined && !Number.isNaN(Number(f.tinh))) {
      q.tinh = Number(f.tinh);
    }
    if (f.trangThai === 'true') {
      q.trangThai = true;
    } else if (f.trangThai === 'false') {
      q.trangThai = false;
    }
    return q;
  }
}
