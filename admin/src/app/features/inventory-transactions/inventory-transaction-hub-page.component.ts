import { CommonModule } from '@angular/common';
import { Component, computed, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import {
  AbstractControl,
  FormBuilder,
  ReactiveFormsModule,
  ValidationErrors,
  ValidatorFn,
} from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { Subject, of } from 'rxjs';
import { catchError, finalize, switchMap, tap } from 'rxjs/operators';

import { CurrentUserContextService } from '../../core/auth/current-user-context.service';
import { ApiRequestError } from '../../core/http/api-request-error';
import { retailPinnedDonViIdForStoreRole } from '../retail/retail-scope.util';
import type { StoreAdminFuelProductListItemDto } from '../fuel-products/models/store-admin-fuel-product.models';
import { FuelProductsApiService } from '../fuel-products/services/fuel-products-api.service';
import type { StoreAdminStoreDto } from '../stores/models/store-admin-store.models';
import { StoresApiService } from '../stores/services/stores-api.service';
import type { StoreAdminInventoryTransactionHeaderListItemDto } from './models/store-admin-inventory-transaction.models';
import { InventoryTransactionsApiService } from './services/inventory-transactions-api.service';
import {
  INVENTORY_TX_LIST_DEFAULT_TAKE,
  INVENTORY_TX_LIST_MAX_TAKE,
} from './inventory-transaction.constants';

function pad2(n: number): string {
  return String(n).padStart(2, '0');
}

/** `dd/MM/yyyy` (chuỗi rỗng = không lọc). */
function parseDdMmYyyyParts(raw: string): { d: number; m: number; y: number } | null {
  const t = raw.trim();
  if (t === '') {
    return null;
  }
  const m = /^(\d{1,2})\/(\d{1,2})\/(\d{4})$/.exec(t);
  if (!m) {
    return null;
  }
  const d = Number(m[1]);
  const mo = Number(m[2]);
  const y = Number(m[3]);
  if (mo < 1 || mo > 12 || d < 1 || d > 31) {
    return null;
  }
  const dt = new Date(y, mo - 1, d);
  if (dt.getFullYear() !== y || dt.getMonth() !== mo - 1 || dt.getDate() !== d) {
    return null;
  }
  return { d, m: mo, y };
}

/** Gửi API: nửa đầu ngày theo lịch (không `Z` / không `toISOString()` → tránh lệch +7h so với DB `datetime`). */
function vnDayStartApiString(parts: { d: number; m: number; y: number }): string {
  return `${parts.y}-${pad2(parts.m)}-${pad2(parts.d)}T00:00:00`;
}

/** Cuối ngày (lọc `<=` trên SQL). */
function vnDayEndApiString(parts: { d: number; m: number; y: number }): string {
  return `${parts.y}-${pad2(parts.m)}-${pad2(parts.d)}T23:59:59`;
}

function vnOptionalDdMmYyyyValidator(): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    const v = String(control.value ?? '').trim();
    if (v === '') {
      return null;
    }
    return parseDdMmYyyyParts(v) ? null : { vnDateFormat: true };
  };
}

function inventoryListDateRangeValidator(group: AbstractControl): ValidationErrors | null {
  const from = String(group.get('transactionDateFrom')?.value ?? '').trim();
  const to = String(group.get('transactionDateTo')?.value ?? '').trim();
  if (from === '' || to === '') {
    return null;
  }
  const pf = parseDdMmYyyyParts(from);
  const pt = parseDdMmYyyyParts(to);
  if (!pf || !pt) {
    return null;
  }
  const df = new Date(pf.y, pf.m - 1, pf.d).getTime();
  const dt = new Date(pt.y, pt.m - 1, pt.d).getTime();
  return df > dt ? { dateRangeOrder: true } : null;
}

function transactionDateFilterQueryParam(raw: string, endOfDay: boolean): string | undefined {
  const parts = parseDdMmYyyyParts(raw);
  if (!parts) {
    return undefined;
  }
  return endOfDay ? vnDayEndApiString(parts) : vnDayStartApiString(parts);
}

@Component({
  selector: 'app-inventory-transaction-hub-page',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: './inventory-transaction-hub-page.component.html',
  styleUrl: './inventory-transaction-hub-page.component.scss',
})
export class InventoryTransactionHubPageComponent {
  private readonly fb = inject(FormBuilder);
  private readonly txApi = inject(InventoryTransactionsApiService);
  private readonly storesApi = inject(StoresApiService);
  private readonly fuelApi = inject(FuelProductsApiService);
  private readonly userContext = inject(CurrentUserContextService);
  private readonly router = inject(Router);
  private readonly refresh$ = new Subject<void>();

  readonly stores = signal<StoreAdminStoreDto[]>([]);
  readonly products = signal<StoreAdminFuelProductListItemDto[]>([]);

  readonly filterForm = this.fb.group(
    {
      donViId: this.fb.control<number | null>(null),
      productId: this.fb.control<number | null>(null),
      transactionType: this.fb.control<number | null>(null),
      transactionDateFrom: ['', [vnOptionalDdMmYyyyValidator()]],
      transactionDateTo: ['', [vnOptionalDdMmYyyyValidator()]],
    },
    { validators: [inventoryListDateRangeValidator] },
  );

  readonly pagedItems = signal<StoreAdminInventoryTransactionHeaderListItemDto[]>([]);
  readonly pagedTotal = signal(0);
  readonly listSkip = signal(0);
  readonly listTake = signal(INVENTORY_TX_LIST_DEFAULT_TAKE);
  readonly pagedLoading = signal(false);
  readonly pagedError = signal<string | null>(null);

  readonly takeOptions = [25, 50, 100, 200] as const;

  readonly storeLabel = computed(() => {
    const m = new Map(this.stores().map((s) => [s.id, `${s.ma} — ${s.ten}`]));
    return (id: number) => m.get(id) ?? `Cửa hàng #${id}`;
  });

  constructor() {
    const pin = retailPinnedDonViIdForStoreRole(this.userContext);
    if (pin !== null) {
      this.filterForm.patchValue({ donViId: pin }, { emitEvent: false });
      this.filterForm.controls.donViId.disable({ emitEvent: false });
    }

    this.storesApi
      .list({ skip: 0, take: INVENTORY_TX_LIST_MAX_TAKE })
      .pipe(takeUntilDestroyed())
      .subscribe({
        next: (p) => this.stores.set(p.items),
        error: () => this.stores.set([]),
      });

    this.fuelApi
      .list({ skip: 0, take: INVENTORY_TX_LIST_MAX_TAKE })
      .pipe(takeUntilDestroyed())
      .subscribe({
        next: (p) => this.products.set(p.items),
        error: () => this.products.set([]),
      });

    this.refresh$
      .pipe(
        tap(() => {
          this.pagedLoading.set(true);
          this.pagedError.set(null);
        }),
        switchMap(() => {
          const skip = this.listSkip();
          const take = this.listTake();
          const emptyPage = {
            items: [] as StoreAdminInventoryTransactionHeaderListItemDto[],
            totalCount: 0,
            skip,
            take,
          };

          return this.txApi.list(this.buildPagedQuery()).pipe(
            tap((paged) => {
              this.pagedItems.set(paged.items);
              this.pagedTotal.set(paged.totalCount);
              this.listSkip.set(paged.skip);
              this.listTake.set(paged.take);
            }),
            catchError((err: unknown) => {
              const msg = err instanceof ApiRequestError ? err.message : 'Không tải được danh sách phân trang.';
              this.pagedError.set(msg);
              this.pagedItems.set([]);
              this.pagedTotal.set(0);
              return of(emptyPage);
            }),
            finalize(() => {
              this.pagedLoading.set(false);
            }),
          );
        }),
        takeUntilDestroyed(),
      )
      .subscribe();

    queueMicrotask(() => this.refresh$.next());
  }

  applyFilters(): void {
    this.filterForm.markAllAsTouched();
    if (this.filterForm.invalid) {
      return;
    }
    this.listSkip.set(0);
    this.refresh$.next();
  }

  setListTake(n: number): void {
    const v = Math.min(Math.max(1, n), INVENTORY_TX_LIST_MAX_TAKE);
    this.listTake.set(v);
    this.listSkip.set(0);
    this.refresh$.next();
  }

  prevPage(): void {
    const next = Math.max(0, this.listSkip() - this.listTake());
    this.listSkip.set(next);
    this.refresh$.next();
  }

  nextPage(): void {
    const next = this.listSkip() + this.listTake();
    if (next < this.pagedTotal()) {
      this.listSkip.set(next);
      this.refresh$.next();
    }
  }

  rangeLabel(): string {
    const total = this.pagedTotal();
    if (total === 0) {
      return 'Không có dòng';
    }
    const from = this.listSkip() + 1;
    const to = Math.min(this.listSkip() + this.pagedItems().length, total);
    return `${from}–${to} / ${total}`;
  }

  goToNewInventoryTransaction(): void {
    const f = this.filterForm.getRawValue();
    this.userContext.prepareInventoryTransactionCreatePrefill(f.donViId, f.productId);
    void this.router.navigate(['/inventory-transactions/new']);
  }

  transactionTypeLabel(tt: number): string {
    if (tt === 1) {
      return 'Nhập kho';
    }
    if (tt === -1) {
      return 'Xuất kho';
    }
    return `Loại ${tt}`;
  }

  private buildPagedQuery(): {
    donViId?: number;
    productId?: number;
    transactionType?: number;
    transactionDateFrom?: string;
    transactionDateTo?: string;
    skip: number;
    take: number;
  } {
    const f = this.filterForm.getRawValue();
    const q: {
      donViId?: number;
      productId?: number;
      transactionType?: number;
      transactionDateFrom?: string;
      transactionDateTo?: string;
      skip: number;
      take: number;
    } = {
      skip: this.listSkip(),
      take: this.listTake(),
    };
    if (f.donViId !== null && f.donViId !== undefined) {
      q.donViId = f.donViId;
    }
    if (f.productId !== null && f.productId !== undefined) {
      q.productId = f.productId;
    }
    if (f.transactionType !== null && f.transactionType !== undefined) {
      q.transactionType = f.transactionType;
    }
    const fromParam = transactionDateFilterQueryParam(String(f.transactionDateFrom ?? ''), false);
    const toParam = transactionDateFilterQueryParam(String(f.transactionDateTo ?? ''), true);
    if (fromParam !== undefined) {
      q.transactionDateFrom = fromParam;
    }
    if (toParam !== undefined) {
      q.transactionDateTo = toParam;
    }
    return q;
  }
}
