import { CommonModule } from '@angular/common';
import { Component, computed, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { MatAutocompleteModule, MatAutocompleteSelectedEvent } from '@angular/material/autocomplete';
import { MatInputModule } from '@angular/material/input';
import { FormBuilder, ReactiveFormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { Subject, forkJoin, of } from 'rxjs';
import { catchError, finalize, switchMap, tap } from 'rxjs/operators';

/** Chuỗi ISO từ API → hiển thị theo múi giờ Việt Nam (tránh lệch +7 so với giờ địa phương). */
function formatDateTimeHcm(iso: string | null | undefined, compact: boolean): string {
  if (!iso) {
    return '—';
  }
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) {
    return iso;
  }
  return new Intl.DateTimeFormat('vi-VN', {
    dateStyle: compact ? 'short' : 'medium',
    timeStyle: compact ? 'short' : 'medium',
    timeZone: 'Asia/Ho_Chi_Minh',
    hour12: false,
  }).format(d);
}

/** Cột Hiệu lực (Giá hiện hành / Lịch sử): `HH:mm dd/MM/yy` theo Asia/Ho_Chi_Minh. */
function formatEffectiveDateTimeHcm(iso: string | null | undefined): string {
  if (!iso) {
    return '—';
  }
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) {
    return iso;
  }
  const parts = new Intl.DateTimeFormat('en-GB', {
    timeZone: 'Asia/Ho_Chi_Minh',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  }).formatToParts(d);
  const v = (t: Intl.DateTimeFormatPart['type']) => parts.find((p) => p.type === t)?.value ?? '';
  const yy = v('year').slice(-2);
  return `${v('hour')}:${v('minute')} ${v('day')}/${v('month')}/${yy}`;
}

import { CurrentUserContextService } from '../../core/auth/current-user-context.service';
import { ApiRequestError } from '../../core/http/api-request-error';
import { retailPinnedDonViIdForStoreRole } from '../retail/retail-scope.util';
import type { StoreAdminFuelProductListItemDto } from '../fuel-products/models/store-admin-fuel-product.models';
import { FuelProductsApiService } from '../fuel-products/services/fuel-products-api.service';
import type { StoreAdminStoreDto } from '../stores/models/store-admin-store.models';
import { StoresApiService } from '../stores/services/stores-api.service';
import type {
  StoreAdminStationPriceBoardListItemDto,
  StoreAdminStorePriceListItemDto,
} from './models/store-admin-store-price.models';
import { StorePricesApiService } from './services/store-prices-api.service';
import { STORE_PRICE_LIST_DEFAULT_TAKE, STORE_PRICE_LIST_MAX_TAKE } from './store-price.constants';

function filterByProductId(
  rows: StoreAdminStorePriceListItemDto[],
  productId: number | null,
): StoreAdminStorePriceListItemDto[] {
  if (productId === null || productId === undefined) {
    return rows;
  }
  return rows.filter((r) => r.productId === productId);
}

/** Giá trị `mat-option` để xóa chọn cửa hàng (so sánh tham chiếu). */
const CLEAR_STORE_FILTER = Object.freeze({ kind: 'clear' as const });

@Component({
  selector: 'app-store-price-hub-page',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, MatAutocompleteModule, MatInputModule],
  templateUrl: './store-price-hub-page.component.html',
  styleUrl: './store-price-hub-page.component.scss',
})
export class StorePriceHubPageComponent {
  /** Option “Chưa chọn” trong autocomplete cửa hàng. */
  readonly clearStoreFilter = CLEAR_STORE_FILTER;
  private readonly fb = inject(FormBuilder);
  private readonly prices = inject(StorePricesApiService);
  private readonly storesApi = inject(StoresApiService);
  private readonly fuelApi = inject(FuelProductsApiService);
  private readonly userContext = inject(CurrentUserContextService);
  private readonly router = inject(Router);
  private readonly refresh$ = new Subject<void>();

  readonly stores = signal<StoreAdminStoreDto[]>([]);
  readonly products = signal<StoreAdminFuelProductListItemDto[]>([]);

  readonly filterForm = this.fb.group({
    donViId: this.fb.control<number | null>(null),
    /** Chuỗi hiển thị / gõ tìm cửa hàng (đồng bộ với `donViId` khi chọn từ gợi ý). */
    storeSearch: this.fb.control<string>('', { nonNullable: true }),
    productId: this.fb.control<number | null>(null),
    boardIsActive: this.fb.control<'any' | 'true' | 'false'>('any'),
  });

  /** Lọc lịch sử theo mặt hàng khi bấm một dòng ở bảng Giá hiện hành (ưu tiên hơn ô Mặt hàng). */
  readonly historyFocusProductId = signal<number | null>(null);

  readonly currentRows = signal<StoreAdminStorePriceListItemDto[]>([]);
  readonly historyRows = signal<StoreAdminStorePriceListItemDto[]>([]);
  readonly storeScopeLoading = signal(false);
  readonly storeScopeError = signal<string | null>(null);

  readonly boardRows = signal<StoreAdminStationPriceBoardListItemDto[]>([]);
  readonly boardTotal = signal(0);
  readonly boardSkip = signal(0);
  readonly boardTake = signal(STORE_PRICE_LIST_DEFAULT_TAKE);
  readonly boardLoading = signal(false);
  readonly boardError = signal<string | null>(null);
  readonly boardDeletingId = signal<number | null>(null);

  readonly takeOptions = [25, 50, 100, 200] as const;

  readonly storeLabel = computed(() => {
    const m = new Map(this.stores().map((s) => [s.id, `${s.ma} — ${s.ten}`]));
    return (id: number) => m.get(id) ?? `Cửa hàng #${id}`;
  });

  readonly productLabel = computed(() => {
    const m = new Map(this.products().map((p) => [p.id, ` ${p.name}`]));
    return (id: number) => m.get(id) ?? `Mặt hàng #${id}`;
  });

  constructor() {
    const pin = retailPinnedDonViIdForStoreRole(this.userContext);
    if (pin !== null) {
      this.filterForm.patchValue({ donViId: pin }, { emitEvent: false });
      this.filterForm.controls.donViId.disable({ emitEvent: false });
      this.filterForm.controls.storeSearch.disable({ emitEvent: false });
    }

    this.storesApi
      .list({ skip: 0, take: STORE_PRICE_LIST_MAX_TAKE })
      .pipe(takeUntilDestroyed())
      .subscribe({
        next: (p) => {
          this.stores.set(p.items);
          this.syncStoreSearchFromDonViId();
        },
        error: () => this.stores.set([]),
      });

    this.fuelApi
      .list({ skip: 0, take: STORE_PRICE_LIST_MAX_TAKE })
      .pipe(takeUntilDestroyed())
      .subscribe({
        next: (p) => this.products.set(p.items),
        error: () => this.products.set([]),
      });

    this.refresh$
      .pipe(
        tap(() => {
          this.storeScopeLoading.set(true);
          this.storeScopeError.set(null);
          this.boardLoading.set(true);
          this.boardError.set(null);
        }),
        switchMap(() => {
          const f = this.filterForm.getRawValue();
          const donViId = f.donViId;
          const productId = f.productId;
          const histPid = this.historyFocusProductId() ?? f.productId ?? null;

          const store$ =
            donViId === null || donViId === undefined
              ? of<{ cur: StoreAdminStorePriceListItemDto[]; hist: StoreAdminStorePriceListItemDto[] }>({
                  cur: [],
                  hist: [],
                })
              : forkJoin({
                  cur: this.prices.listCurrentByStore(donViId),
                  hist: this.prices.listByStore(donViId, histPid),
                });

          return forkJoin({
            store: store$,
            boards: this.prices.listPriceBoards(this.buildBoardListQuery()),
          }).pipe(
            tap(({ store, boards }) => {
              this.currentRows.set(filterByProductId(store.cur, productId));
              this.historyRows.set(store.hist);
              this.boardRows.set(boards.items);
              this.boardTotal.set(boards.totalCount);
              this.boardSkip.set(boards.skip);
              this.boardTake.set(boards.take);
            }),
            catchError((err: unknown) => {
              const msg = err instanceof ApiRequestError ? err.message : 'Không tải được giá.';
              this.storeScopeError.set(msg);
              this.boardError.set(msg);
              this.currentRows.set([]);
              this.historyRows.set([]);
              this.boardRows.set([]);
              return of(null);
            }),
            finalize(() => {
              this.storeScopeLoading.set(false);
              this.boardLoading.set(false);
            }),
          );
        }),
        takeUntilDestroyed(),
      )
      .subscribe();

    queueMicrotask(() => this.refresh$.next());
  }

  applyFilters(): void {
    this.boardSkip.set(0);
    this.refresh$.next();
  }

  storeLine(s: StoreAdminStoreDto): string {
    const ma = s.ma?.trim() ?? '';
    const ten = s.ten?.trim() ?? '';
    if (ma && ten) {
      return `${ma} — ${ten}`;
    }
    if (ma) {
      return ma;
    }
    if (ten) {
      return ten;
    }
    return `Cửa hàng #${s.id}`;
  }

  /** Gợi ý cửa hàng theo chuỗi gõ (mã, tên, id). */
  storeMatches(raw: string | null | undefined): StoreAdminStoreDto[] {
    const q = String(raw ?? '')
      .trim()
      .toLowerCase();
    const list = this.stores();
    if (!q) {
      return list;
    }
    return list.filter((s) => {
      const idStr = String(s.id);
      return (
        s.ma.toLowerCase().includes(q) ||
        s.ten.toLowerCase().includes(q) ||
        idStr.includes(q) ||
        this.storeLine(s).toLowerCase().includes(q)
      );
    });
  }

  onStorePicked(event: MatAutocompleteSelectedEvent): void {
    const v = event.option.value;
    if (v === CLEAR_STORE_FILTER) {
      if (!this.filterForm.controls.donViId.disabled) {
        this.filterForm.patchValue({ donViId: null, storeSearch: '' });
      }
      return;
    }
    const s = v as StoreAdminStoreDto;
    this.filterForm.patchValue({ donViId: s.id, storeSearch: this.storeLine(s) });
  }

  onStoreSearchBlur(): void {
    if (this.filterForm.controls.storeSearch.disabled) {
      return;
    }
    const raw = this.filterForm.controls.storeSearch.value.trim();
    const id = this.filterForm.getRawValue().donViId;
    if (id == null) {
      if (raw !== '') {
        this.filterForm.patchValue({ storeSearch: '' }, { emitEvent: false });
      }
      return;
    }
    const s = this.stores().find((x) => x.id === id);
    const expected = s ? this.storeLine(s) : this.storeLabel()(id).trim();
    if (raw === expected) {
      return;
    }
    const match = this.stores().find((x) => this.storeLine(x) === raw);
    if (match?.id === id) {
      return;
    }
    this.syncStoreSearchFromDonViId();
  }

  /**
   * `matAutocomplete` gọi sau khi chọn: lúc đó `storeSearch` đã là chuỗi (`patchValue` trong `onStorePicked`),
   * không còn là object — phải trả về chuỗi nguyên, tránh ép kiểu DTO → `undefined — undefined`.
   */
  displayStoreAutocomplete = (
    value: StoreAdminStoreDto | typeof CLEAR_STORE_FILTER | string | null | undefined,
  ): string => {
    if (value == null) {
      return '';
    }
    if (typeof value === 'string') {
      return value;
    }
    if (typeof value === 'object' && 'kind' in value && value.kind === 'clear') {
      return '';
    }
    return this.storeLine(value as StoreAdminStoreDto);
  };

  private syncStoreSearchFromDonViId(): void {
    const id = this.filterForm.getRawValue().donViId;
    if (id == null) {
      this.filterForm.patchValue({ storeSearch: '' }, { emitEvent: false });
      return;
    }
    const s = this.stores().find((x) => x.id === id);
    this.filterForm.patchValue({ storeSearch: s ? this.storeLine(s) : this.storeLabel()(id) }, { emitEvent: false });
  }

  onCurrentRowClick(row: StoreAdminStorePriceListItemDto): void {
    this.historyFocusProductId.set(row.productId);
    this.refresh$.next();
  }

  clearHistoryProductFilter(): void {
    this.historyFocusProductId.set(null);
    this.refresh$.next();
  }

  setBoardTake(n: number): void {
    const v = Math.min(Math.max(1, n), STORE_PRICE_LIST_MAX_TAKE);
    this.boardTake.set(v);
    this.boardSkip.set(0);
    this.refresh$.next();
  }

  prevBoardPage(): void {
    const next = Math.max(0, this.boardSkip() - this.boardTake());
    this.boardSkip.set(next);
    this.refresh$.next();
  }

  nextBoardPage(): void {
    const next = this.boardSkip() + this.boardTake();
    if (next < this.boardTotal()) {
      this.boardSkip.set(next);
      this.refresh$.next();
    }
  }

  boardRangeLabel(): string {
    const total = this.boardTotal();
    if (total === 0) {
      return 'Không có dòng';
    }
    const from = this.boardSkip() + 1;
    const to = Math.min(this.boardSkip() + this.boardRows().length, total);
    return `${from}–${to} / ${total}`;
  }

  goToNewStorePrice(): void {
    const f = this.filterForm.getRawValue();
    this.userContext.prepareStorePriceCreatePrefill(f.donViId, f.productId);
    void this.router.navigate(['/store-prices/new']);
  }

  goToEditBoard(id: number): void {
    void this.router.navigate(['/store-prices/price-boards', id, 'edit']);
  }

  formatBoardDate(iso: string | null | undefined): string {
    return formatDateTimeHcm(iso, false);
  }

  formatBoardAudit(iso: string | null | undefined): string {
    return formatDateTimeHcm(iso, true);
  }

  formatPriceEffective(iso: string | null | undefined): string {
    return formatEffectiveDateTimeHcm(iso);
  }

  confirmDeleteBoard(id: number): void {
    if (!confirm('Xóa bảng giá này? Tất cả dòng giá theo mặt hàng thuộc bảng sẽ bị xóa theo.')) {
      return;
    }
    this.boardError.set(null);
    this.boardDeletingId.set(id);
    this.prices
      .deletePriceBoard(id)
      .pipe(finalize(() => this.boardDeletingId.set(null)))
      .subscribe({
        next: () => this.refresh$.next(),
        error: (err: unknown) => {
          this.boardError.set(err instanceof ApiRequestError ? err.message : 'Không xóa được bảng giá.');
        },
      });
  }

  private buildBoardListQuery(): {
    donViId?: number;
    isActive?: boolean;
    skip: number;
    take: number;
  } {
    const f = this.filterForm.getRawValue();
    const q: {
      donViId?: number;
      isActive?: boolean;
      skip: number;
      take: number;
    } = {
      skip: this.boardSkip(),
      take: this.boardTake(),
    };
    if (f.donViId !== null && f.donViId !== undefined) {
      q.donViId = f.donViId;
    }
    if (f.boardIsActive === 'true') {
      q.isActive = true;
    } else if (f.boardIsActive === 'false') {
      q.isActive = false;
    }
    return q;
  }
}
