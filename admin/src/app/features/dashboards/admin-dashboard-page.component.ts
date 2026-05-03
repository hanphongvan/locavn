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
import { StorePricesApiService } from '../store-prices/services/store-prices-api.service';
import { StoresApiService } from '../stores/services/stores-api.service';
import type { DashMetric } from './dashboard-ui.util';
import { dashErr } from './dashboard-ui.util';

const COUNT_TAKE = 1;
const INV_PREVIEW = 8;
const STORES_CAP = 200;

export interface AdminDashboardModel {
  storesTotal: DashMetric;
  currentPriceRowsTotal: DashMetric;
  inventoryTransactionsTotal: DashMetric;
  inventoryCurrent: { kind: 'ok'; total: number; preview: StoreAdminInventoryCurrentLineDto[] } | { kind: 'error'; message: string };
  storeLabel: (id: number) => string;
}

@Component({
  selector: 'app-admin-dashboard-page',
  standalone: true,
  imports: [
    CommonModule,
    RouterLink,
    PageHeaderComponent,
    StatCardComponent,
    SectionCardComponent,
    TableWrapperComponent,
  ],
  templateUrl: './admin-dashboard-page.component.html',
  styleUrl: './admin-dashboard-page.component.scss',
})
export class AdminDashboardPageComponent {
  readonly invPreviewTake = INV_PREVIEW;

  private readonly storesApi = inject(StoresApiService);
  private readonly pricesApi = inject(StorePricesApiService);
  private readonly invTxApi = inject(InventoryTransactionsApiService);
  private readonly inventoriesApi = inject(InventoriesApiService);
  readonly model = signal<AdminDashboardModel | null>(null);

  constructor() {
    forkJoin({
      stores: this.storesApi.list({ skip: 0, take: STORES_CAP }).pipe(
        map((p) => ({ ok: true as const, total: p.totalCount, items: p.items })),
        catchError((err: unknown) =>
          of({
            ok: false as const,
            message: dashErr(err, 'Không tải được danh sách cửa hàng.'),
            total: 0,
            items: [],
          }),
        ),
      ),
      currentPrices: this.pricesApi.list({ skip: 0, take: COUNT_TAKE, isCurrent: true }).pipe(
        map((p) => ({ kind: 'ok' as const, total: p.totalCount })),
        catchError((err: unknown) => of({ kind: 'error' as const, message: dashErr(err, 'Không tải được giá.') })),
      ),
      inventoryTransactions: this.invTxApi.list({ skip: 0, take: COUNT_TAKE }).pipe(
        map((p) => ({ kind: 'ok' as const, total: p.totalCount })),
        catchError((err: unknown) =>
          of({ kind: 'error' as const, message: dashErr(err, 'Không tải được giao dịch kho.') })),
      ),
      inventoryCurrent: this.inventoriesApi.listCurrent({ skip: 0, take: INV_PREVIEW }).pipe(
        map((p) => ({ kind: 'ok' as const, total: p.totalCount, preview: p.items })),
        catchError((err: unknown) =>
          of({ kind: 'error' as const, message: dashErr(err, 'Không tải được tồn kho hiện tại.') })),
      ),
    }).subscribe({
      next: ({ stores, currentPrices, inventoryTransactions, inventoryCurrent }) => {
        const labelMap = new Map(stores.items.map((s) => [s.id, `${s.ma} — ${s.ten}`]));
        const storeLabel = (id: number) => labelMap.get(id) ?? `Cửa hàng #${id}`;

        const storesTotal: DashMetric = stores.ok
          ? { kind: 'ok', total: stores.total }
          : { kind: 'error', message: stores.message };

        this.model.set({
          storesTotal,
          currentPriceRowsTotal: currentPrices,
          inventoryTransactionsTotal: inventoryTransactions,
          inventoryCurrent,
          storeLabel,
        });
      },
    });
  }

  readonly formatUnit = formatInventoryCurrentLineUnitLabel;
}
