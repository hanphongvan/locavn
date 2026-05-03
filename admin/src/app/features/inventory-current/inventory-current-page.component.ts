import { CommonModule } from '@angular/common';
import { Component, computed, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule } from '@angular/forms';
import { Subject, of } from 'rxjs';
import { catchError, finalize, map, switchMap, tap } from 'rxjs/operators';

import { CurrentUserContextService } from '../../core/auth/current-user-context.service';
import { ApiRequestError } from '../../core/http/api-request-error';
import { retailPinnedDonViIdForStoreRole } from '../retail/retail-scope.util';
import type { StoreAdminFuelProductListItemDto } from '../fuel-products/models/store-admin-fuel-product.models';
import { FuelProductsApiService } from '../fuel-products/services/fuel-products-api.service';
import { formatInventoryCurrentLineUnitLabel } from '../inventories/inventory-current-line.util';
import type { StoreAdminInventoryCurrentLineDto } from '../inventories/models/store-admin-inventory-current.models';
import { InventoriesApiService } from '../inventories/services/inventories-api.service';
import type { StoreAdminStoreDto } from '../stores/models/store-admin-store.models';
import { StoresApiService } from '../stores/services/stores-api.service';
import {
  INVENTORY_CURRENT_DEFAULT_TAKE,
  INVENTORY_CURRENT_FILTER_LIST_TAKE,
  INVENTORY_CURRENT_MAX_TAKE,
} from './inventory-current.constants';

export interface InventoryCurrentStoreGroup {
  donViId: number;
  lines: StoreAdminInventoryCurrentLineDto[];
}

function buildStoreGroups(lines: StoreAdminInventoryCurrentLineDto[]): InventoryCurrentStoreGroup[] {
  const map = new Map<number, StoreAdminInventoryCurrentLineDto[]>();
  for (const row of lines) {
    const list = map.get(row.donViId) ?? [];
    list.push(row);
    map.set(row.donViId, list);
  }
  return [...map.entries()]
    .sort(([a], [b]) => a - b)
    .map(([donViId, groupLines]) => ({
      donViId,
      lines: groupLines.sort((x, y) => x.productId - y.productId),
    }));
}

@Component({
  selector: 'app-inventory-current-page',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './inventory-current-page.component.html',
  styleUrl: './inventory-current-page.component.scss',
})
export class InventoryCurrentPageComponent {
  /** Exposed for template (bulk grouped cap). */
  readonly maxBulkTake = INVENTORY_CURRENT_MAX_TAKE;

  private readonly fb = inject(FormBuilder);
  private readonly inventories = inject(InventoriesApiService);
  private readonly storesApi = inject(StoresApiService);
  private readonly fuelApi = inject(FuelProductsApiService);
  private readonly userContext = inject(CurrentUserContextService);
  private readonly refresh$ = new Subject<void>();

  readonly stores = signal<StoreAdminStoreDto[]>([]);
  readonly products = signal<StoreAdminFuelProductListItemDto[]>([]);

  readonly filterForm = this.fb.group({
    viewMode: this.fb.nonNullable.control<'flat' | 'grouped'>('flat'),
    donViId: this.fb.control<number | null>(null),
    productId: this.fb.control<number | null>(null),
  });

  readonly flatItems = signal<StoreAdminInventoryCurrentLineDto[]>([]);
  readonly flatTotal = signal(0);
  readonly flatSkip = signal(0);
  readonly flatTake = signal(INVENTORY_CURRENT_DEFAULT_TAKE);
  readonly groupedSections = signal<InventoryCurrentStoreGroup[]>([]);
  readonly groupedMeta = signal<{
    source: 'by-store' | 'bulk';
    serverTotalCount: number;
    rowCount: number;
    capped: boolean;
  } | null>(null);

  readonly loading = signal(false);
  readonly errorMessage = signal<string | null>(null);

  readonly takeOptions = [100, 200, 300, 500] as const;

  readonly storeLabel = computed(() => {
    const m = new Map(this.stores().map((s) => [s.id, `${s.ma} — ${s.ten}`]));
    return (id: number) => m.get(id) ?? `Cửa hàng #${id}`;
  });

  readonly productLabel = computed(() => {
    const m = new Map(this.products().map((p) => [p.id, `${p.code} — ${p.name}`]));
    return (id: number) => m.get(id) ?? `Mặt hàng #${id}`;
  });

  constructor() {
    const pin = retailPinnedDonViIdForStoreRole(this.userContext);
    if (pin !== null) {
      this.filterForm.patchValue({ donViId: pin }, { emitEvent: false });
      this.filterForm.controls.donViId.disable({ emitEvent: false });
    }

    this.storesApi
      .list({ skip: 0, take: INVENTORY_CURRENT_FILTER_LIST_TAKE })
      .pipe(takeUntilDestroyed())
      .subscribe({
        next: (p) => this.stores.set(p.items),
        error: () => this.stores.set([]),
      });

    this.fuelApi
      .list({ skip: 0, take: INVENTORY_CURRENT_FILTER_LIST_TAKE })
      .pipe(takeUntilDestroyed())
      .subscribe({
        next: (p) => this.products.set(p.items),
        error: () => this.products.set([]),
      });

    this.refresh$
      .pipe(
        tap(() => {
          this.loading.set(true);
          this.errorMessage.set(null);
        }),
        switchMap(() => {
          const f = this.filterForm.getRawValue();
          if (f.viewMode === 'flat') {
            return this.inventories
              .listCurrent({
                skip: this.flatSkip(),
                take: this.flatTake(),
                donViId: f.donViId ?? undefined,
                productId: f.productId ?? undefined,
              })
              .pipe(
                tap((page) => {
                  this.groupedSections.set([]);
                  this.groupedMeta.set(null);
                  this.flatItems.set(page.items);
                  this.flatTotal.set(page.totalCount);
                  this.flatSkip.set(page.skip);
                  this.flatTake.set(page.take);
                }),
                catchError((err: unknown) => {
                  this.errorMessage.set(
                    err instanceof ApiRequestError ? err.message : 'Không tải được tồn kho hiện tại.',
                  );
                  this.flatItems.set([]);
                  this.flatTotal.set(0);
                  return of(null);
                }),
                finalize(() => this.loading.set(false)),
              );
          }

          const donViId = f.donViId;
          const productId = f.productId;

          if (donViId !== null && donViId !== undefined) {
            return this.inventories.listCurrentByStore(donViId).pipe(
              map((items) =>
                items.filter((row) => productId === null || productId === undefined || row.productId === productId),
              ),
              tap((items) => {
                this.flatItems.set([]);
                this.flatTotal.set(0);
                this.groupedSections.set(buildStoreGroups(items));
                this.groupedMeta.set({
                  source: 'by-store',
                  serverTotalCount: items.length,
                  rowCount: items.length,
                  capped: false,
                });
              }),
              catchError((err: unknown) => {
                this.errorMessage.set(
                  err instanceof ApiRequestError ? err.message : 'Không tải được tồn kho theo cửa hàng.',
                );
                this.groupedSections.set([]);
                this.groupedMeta.set(null);
                return of(null);
              }),
              finalize(() => this.loading.set(false)),
            );
          }

          return this.inventories
            .listCurrent({
              skip: 0,
              take: INVENTORY_CURRENT_MAX_TAKE,
              productId: productId ?? undefined,
            })
            .pipe(
              tap((page) => {
                this.flatItems.set([]);
                this.flatTotal.set(0);
                this.groupedSections.set(buildStoreGroups(page.items));
                const capped = page.totalCount > page.items.length;
                this.groupedMeta.set({
                  source: 'bulk',
                  serverTotalCount: page.totalCount,
                  rowCount: page.items.length,
                  capped,
                });
              }),
              catchError((err: unknown) => {
                this.errorMessage.set(
                  err instanceof ApiRequestError ? err.message : 'Không tải được tồn kho hiện tại.',
                );
                this.groupedSections.set([]);
                this.groupedMeta.set(null);
                return of(null);
              }),
              finalize(() => this.loading.set(false)),
            );
        }),
        takeUntilDestroyed(),
      )
      .subscribe();

    queueMicrotask(() => this.refresh$.next());
  }

  applyFilters(): void {
    this.filterForm.markAllAsTouched();
    this.flatSkip.set(0);
    this.refresh$.next();
  }

  setFlatTake(n: number): void {
    const v = Math.min(Math.max(1, n), INVENTORY_CURRENT_MAX_TAKE);
    this.flatTake.set(v);
    this.flatSkip.set(0);
    this.refresh$.next();
  }

  prevFlatPage(): void {
    if (this.filterForm.controls.viewMode.value !== 'flat') {
      return;
    }
    const next = Math.max(0, this.flatSkip() - this.flatTake());
    this.flatSkip.set(next);
    this.refresh$.next();
  }

  nextFlatPage(): void {
    if (this.filterForm.controls.viewMode.value !== 'flat') {
      return;
    }
    const next = this.flatSkip() + this.flatTake();
    if (next < this.flatTotal()) {
      this.flatSkip.set(next);
      this.refresh$.next();
    }
  }

  flatRangeLabel(): string {
    const total = this.flatTotal();
    if (total === 0) {
      return 'Không có dòng';
    }
    const from = this.flatSkip() + 1;
    const to = Math.min(this.flatSkip() + this.flatItems().length, total);
    return `${from}–${to} / ${total}`;
  }

  groupSubtotal(lines: StoreAdminInventoryCurrentLineDto[]): number {
    return lines.reduce((s, r) => s + Number(r.currentQuantity), 0);
  }

  unitLabel(row: StoreAdminInventoryCurrentLineDto): string {
    return formatInventoryCurrentLineUnitLabel(row);
  }

  isFlat(): boolean {
    return this.filterForm.controls.viewMode.value === 'flat';
  }
}
