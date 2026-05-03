import { CommonModule } from '@angular/common';
import { Component, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';

import {
  PageHeaderComponent,
  SectionCardComponent,
  StatCardComponent,
  TableWrapperComponent,
} from '../../shared/ui';
import { forkJoin, of } from 'rxjs';
import { catchError, map } from 'rxjs/operators';

import { InventoriesApiService } from '../inventories/services/inventories-api.service';
import type { StoreAdminInventoryCurrentLineDto } from '../inventories/models/store-admin-inventory-current.models';
import { formatInventoryCurrentLineUnitLabel } from '../inventories/inventory-current-line.util';
import { InventoryTransactionsApiService } from '../inventory-transactions/services/inventory-transactions-api.service';
import type { StoreAdminStorePriceListItemDto } from '../store-prices/models/store-admin-store-price.models';
import { StorePricesApiService } from '../store-prices/services/store-prices-api.service';
import type { StoreAdminStoreDto } from '../stores/models/store-admin-store.models';
import { StoresApiService } from '../stores/services/stores-api.service';
import type { DashMetric } from './dashboard-ui.util';
import { dashErr } from './dashboard-ui.util';

const STORES_TAKE = 120;
const PRICES_TAKE = 100;
const INV_PREVIEW = 12;
const COUNT_TAKE = 1;

export interface TraderDashboardModel {
  stores: { kind: 'ok'; items: StoreAdminStoreDto[]; total: number } | { kind: 'error'; message: string };
  prices: { kind: 'ok'; items: StoreAdminStorePriceListItemDto[]; total: number } | { kind: 'error'; message: string };
  inventoryCurrent: { kind: 'ok'; total: number; preview: StoreAdminInventoryCurrentLineDto[] } | { kind: 'error'; message: string };
  inventoryTransactionsTotal: DashMetric;
  storeLabel: (id: number) => string;
}

@Component({
  selector: 'app-trader-dashboard-page',
  standalone: true,
  imports: [
    CommonModule,
    RouterLink,
    PageHeaderComponent,
    StatCardComponent,
    SectionCardComponent,
    TableWrapperComponent,
  ],
  templateUrl: './trader-dashboard-page.component.html',
  styleUrl: './trader-dashboard-page.component.scss',
})
export class TraderDashboardPageComponent {
  private readonly storesApi = inject(StoresApiService);
  private readonly pricesApi = inject(StorePricesApiService);
  private readonly inventoriesApi = inject(InventoriesApiService);
  private readonly invTxApi = inject(InventoryTransactionsApiService);

  readonly model = signal<TraderDashboardModel | null>(null);

  constructor() {
    forkJoin({
      stores: this.storesApi.list({ skip: 0, take: STORES_TAKE }).pipe(
        map((p) => ({ kind: 'ok' as const, items: p.items, total: p.totalCount })),
        catchError((err: unknown) => of({ kind: 'error' as const, message: dashErr(err, 'Không tải được cửa hàng.') })),
      ),
      prices: this.pricesApi.list({ skip: 0, take: PRICES_TAKE, isCurrent: true }).pipe(
        map((p) => ({ kind: 'ok' as const, items: p.items, total: p.totalCount })),
        catchError((err: unknown) => of({ kind: 'error' as const, message: dashErr(err, 'Không tải được giá.') })),
      ),
      inventoryCurrent: this.inventoriesApi.listCurrent({ skip: 0, take: INV_PREVIEW }).pipe(
        map((p) => ({ kind: 'ok' as const, total: p.totalCount, preview: p.items })),
        catchError((err: unknown) =>
          of({ kind: 'error' as const, message: dashErr(err, 'Không tải được tồn kho.') })),
      ),
      inventoryTransactions: this.invTxApi.list({ skip: 0, take: COUNT_TAKE }).pipe(
        map((p) => ({ kind: 'ok' as const, total: p.totalCount })),
        catchError((err: unknown) =>
          of({ kind: 'error' as const, message: dashErr(err, 'Không tải được giao dịch kho.') })),
      ),
    }).subscribe({
      next: ({ stores, prices, inventoryCurrent, inventoryTransactions }) => {
        const items = stores.kind === 'ok' ? stores.items : [];
        const labelMap = new Map(items.map((s) => [s.id, `${s.ma} — ${s.ten}`]));
        const storeLabel = (id: number) => labelMap.get(id) ?? `CH #${id}`;

        this.model.set({
          stores,
          prices,
          inventoryCurrent,
          inventoryTransactionsTotal: inventoryTransactions,
          storeLabel,
        });
      },
    });
  }

  readonly formatUnit = formatInventoryCurrentLineUnitLabel;
}
