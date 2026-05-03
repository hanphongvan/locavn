import { CommonModule } from '@angular/common';
import {
  AfterViewInit,
  Component,
  ElementRef,
  OnDestroy,
  computed,
  inject,
  signal,
  viewChild,
} from '@angular/core';
import { RouterLink } from '@angular/router';
import {
  ArcElement,
  BarController,
  BarElement,
  CategoryScale,
  Chart,
  Filler,
  Legend,
  LinearScale,
  LineController,
  LineElement,
  PointElement,
  Tooltip,
} from 'chart.js';
import { forkJoin, of } from 'rxjs';
import { catchError, map, switchMap } from 'rxjs/operators';

import { CurrentUserContextService } from '../../core/auth/current-user-context.service';
import { PageHeaderComponent, SectionCardComponent, StatCardComponent, TableWrapperComponent } from '../../shared/ui';
import { formatInventoryCurrentLineUnitLabel } from '../inventories/inventory-current-line.util';
import type { StoreAdminInventoryCurrentLineDto } from '../inventories/models/store-admin-inventory-current.models';
import { InventoriesApiService } from '../inventories/services/inventories-api.service';
import type { StoreAdminInventoryTransactionBundleDto } from '../inventory-transactions/models/store-admin-inventory-transaction.models';
import type { StoreAdminInventoryTransactionHeaderListItemDto } from '../inventory-transactions/models/store-admin-inventory-transaction.models';
import { InventoryTransactionsApiService } from '../inventory-transactions/services/inventory-transactions-api.service';
import type { StoreAdminStorePriceListItemDto } from '../store-prices/models/store-admin-store-price.models';
import { StorePricesApiService } from '../store-prices/services/store-prices-api.service';
import type { StoreAdminStoreDto } from '../stores/models/store-admin-store.models';
import { StoresApiService } from '../stores/services/stores-api.service';
import {
  STORE_DASH_CHART_DAYS,
  STORE_DASH_MAX_BUNDLES,
  STORE_DASH_TX_LOOKBACK_DAYS,
  averagePriceAsOfDay,
  buildAlerts,
  buildKpis,
  bundlesToMovements,
  chartDayKeysAscending,
  currentInventoryMap,
  priceAsOfDay,
  productLabels,
  totalStockAtEndOfDay,
} from './store-dashboard-analytics.util';
import { dashErr } from './dashboard-ui.util';

Chart.register(
  LineController,
  LineElement,
  PointElement,
  LinearScale,
  CategoryScale,
  BarController,
  BarElement,
  ArcElement,
  Tooltip,
  Legend,
  Filler,
);

const TX_PREVIEW = 15;

export type StoreDashState =
  | { kind: 'no_don_vi' }
  | { kind: 'loading' }
  | {
      kind: 'ok';
      store: StoreAdminStoreDto;
      pricesCurrent: StoreAdminStorePriceListItemDto[];
      priceHistory: StoreAdminStorePriceListItemDto[];
      inventory: StoreAdminInventoryCurrentLineDto[];
      transactionsPreview: StoreAdminInventoryTransactionHeaderListItemDto[];
      bundles: StoreAdminInventoryTransactionBundleDto[];
    }
  | { kind: 'error'; message: string };

@Component({
  selector: 'app-store-dashboard-page',
  standalone: true,
  imports: [
    CommonModule,
    RouterLink,
    PageHeaderComponent,
    SectionCardComponent,
    TableWrapperComponent,
    StatCardComponent,
  ],
  templateUrl: './store-dashboard-page.component.html',
  styleUrl: './store-dashboard-page.component.scss',
})
export class StoreDashboardPageComponent implements AfterViewInit, OnDestroy {
  /** Hiển thị trong mô tả nguồn dữ liệu (template). */
  readonly dashMaxBundles = STORE_DASH_MAX_BUNDLES;
  readonly dashTxLookbackDays = STORE_DASH_TX_LOOKBACK_DAYS;

  private readonly userContext = inject(CurrentUserContextService);
  private readonly storesApi = inject(StoresApiService);
  private readonly pricesApi = inject(StorePricesApiService);
  private readonly inventoriesApi = inject(InventoriesApiService);
  private readonly invTxApi = inject(InventoryTransactionsApiService);

  readonly state = signal<StoreDashState>({ kind: 'loading' });

  readonly okData = computed(() => {
    const s = this.state();
    return s.kind === 'ok' ? s : null;
  });

  readonly errorMessage = computed(() => {
    const s = this.state();
    return s.kind === 'error' ? s.message : '';
  });

  readonly dayKeys = chartDayKeysAscending(STORE_DASH_CHART_DAYS);

  readonly analytics = computed(() => {
    const d = this.okData();
    if (!d) {
      return null;
    }
    const movements = bundlesToMovements(d.bundles);
    const currentMap = currentInventoryMap(d.inventory);
    const productIds = [...new Set([...currentMap.keys(), ...d.inventory.map((r) => r.productId)])];
    const labels = productLabels(d.inventory);
    const kpis = buildKpis(d.inventory, d.pricesCurrent, d.priceHistory, d.bundles);
    const invTotals = this.dayKeys.map((dk) =>
      totalStockAtEndOfDay(dk, productIds, currentMap, movements),
    );
    const priceAvgs = this.dayKeys.map((dk) => averagePriceAsOfDay(dk, productIds, d.priceHistory));
    const invDelta = invTotals.map((v, i) => (i === 0 ? 0 : v - invTotals[i - 1]!));
    const priceDelta = priceAvgs.map((v, i) => {
      if (i === 0 || v == null || priceAvgs[i - 1] == null) {
        return 0;
      }
      return v - (priceAvgs[i - 1] as number);
    });
    const alerts = buildAlerts(
      d.inventory,
      this.dayKeys,
      currentMap,
      movements,
      d.priceHistory,
      productIds,
      kpis.soldTodayQty,
    );
    return {
      movements,
      currentMap,
      productIds,
      labels,
      kpis,
      invTotals,
      priceAvgs,
      invDelta,
      priceDelta,
      alerts,
    };
  });

  readonly chartInvPrice = viewChild<ElementRef<HTMLCanvasElement>>('chartInvPrice');
  readonly chartPriceLines = viewChild<ElementRef<HTMLCanvasElement>>('chartPriceLines');
  readonly chartInvBar = viewChild<ElementRef<HTMLCanvasElement>>('chartInvBar');
  readonly chartInvPie = viewChild<ElementRef<HTMLCanvasElement>>('chartInvPie');
  readonly chartInvDelta = viewChild<ElementRef<HTMLCanvasElement>>('chartInvDelta');
  readonly chartPriceDelta = viewChild<ElementRef<HTMLCanvasElement>>('chartPriceDelta');

  private charts: Chart[] = [];
  private chartScheduled = false;

  readonly formatUnit = formatInventoryCurrentLineUnitLabel;

  constructor() {
    const donViId = this.userContext.donViId();
    if (donViId == null) {
      this.state.set({ kind: 'no_don_vi' });
      return;
    }

    const from = new Date();
    from.setTime(from.getTime() - STORE_DASH_TX_LOOKBACK_DAYS * 86400000);
    const fromStr = from.toISOString();

    forkJoin({
      store: this.storesApi.getById(donViId).pipe(
        map((s) => ({ ok: true as const, store: s })),
        catchError((err: unknown) => of({ ok: false as const, message: dashErr(err, 'Không tải được cửa hàng.') })),
      ),
      pricesCurrent: this.pricesApi.listCurrentByStore(donViId).pipe(
        map((rows) => ({ ok: true as const, rows })),
        catchError((err: unknown) => of({ ok: false as const, message: dashErr(err, 'Không tải được giá hiện hành.') })),
      ),
      priceHistory: this.pricesApi.listByStore(donViId).pipe(
        map((rows) => ({ ok: true as const, rows })),
        catchError((err: unknown) => of({ ok: false as const, message: dashErr(err, 'Không tải được lịch sử giá.') })),
      ),
      inventory: this.inventoriesApi.listCurrentByStore(donViId).pipe(
        map((rows) => ({ ok: true as const, rows })),
        catchError((err: unknown) => of({ ok: false as const, message: dashErr(err, 'Không tải được tồn kho.') })),
      ),
      transactionsPreview: this.invTxApi.list({ donViId, skip: 0, take: TX_PREVIEW }).pipe(
        map((p) => ({ ok: true as const, items: p.items })),
        catchError((err: unknown) => of({ ok: false as const, message: dashErr(err, 'Không tải được giao dịch.') })),
      ),
      txHeaders: this.invTxApi
        .listByStore(donViId, { transactionDateFrom: fromStr })
        .pipe(
          map((rows) => ({ ok: true as const, rows })),
          catchError((err: unknown) => of({ ok: false as const, message: dashErr(err, 'Không tải được lịch sử phiếu.') })),
        ),
    })
      .pipe(
        switchMap(({ store: storeRes, pricesCurrent, priceHistory, inventory, transactionsPreview, txHeaders }) => {
          if (!storeRes.ok) {
            return of({ kind: 'error' as const, message: storeRes.message });
          }
          if (!pricesCurrent.ok || !priceHistory.ok || !inventory.ok || !transactionsPreview.ok || !txHeaders.ok) {
            const msg = [
              !pricesCurrent.ok && pricesCurrent.message,
              !priceHistory.ok && priceHistory.message,
              !inventory.ok && inventory.message,
              !transactionsPreview.ok && transactionsPreview.message,
              !txHeaders.ok && txHeaders.message,
            ]
              .filter(Boolean)
              .join(' ');
            return of({ kind: 'error' as const, message: msg || 'Lỗi tải dữ liệu.' });
          }
          const ids = [...new Set(txHeaders.rows.map((h) => h.id))].slice(0, STORE_DASH_MAX_BUNDLES);
          if (!ids.length) {
            return of({
              kind: 'ok' as const,
              store: storeRes.store,
              pricesCurrent: pricesCurrent.rows,
              priceHistory: priceHistory.rows,
              inventory: inventory.rows,
              transactionsPreview: transactionsPreview.items,
              bundles: [] as StoreAdminInventoryTransactionBundleDto[],
            });
          }
          return forkJoin(
            ids.map((id) =>
              this.invTxApi.getById(id).pipe(catchError(() => of(null as StoreAdminInventoryTransactionBundleDto | null))),
            ),
          ).pipe(
            map((rows) => ({
              kind: 'ok' as const,
              store: storeRes.store,
              pricesCurrent: pricesCurrent.rows,
              priceHistory: priceHistory.rows,
              inventory: inventory.rows,
              transactionsPreview: transactionsPreview.items,
              bundles: rows.filter((b): b is StoreAdminInventoryTransactionBundleDto => b != null),
            })),
            catchError((err: unknown) =>
              of({ kind: 'error' as const, message: dashErr(err, 'Không tải chi tiết phiếu kho.') }),
            ),
          );
        }),
      )
      .subscribe({
        next: (res) => {
          if (res.kind === 'error') {
            this.state.set(res);
            return;
          }
          this.state.set(res);
          this.scheduleCharts();
        },
      });
  }

  ngAfterViewInit(): void {
    this.scheduleCharts();
  }

  ngOnDestroy(): void {
    this.destroyCharts();
  }

  private scheduleCharts(): void {
    if (this.chartScheduled) {
      return;
    }
    this.chartScheduled = true;
    requestAnimationFrame(() => {
      this.chartScheduled = false;
      if (this.state().kind !== 'ok') {
        return;
      }
      this.buildCharts();
    });
  }

  private destroyCharts(): void {
    for (const c of this.charts) {
      c.destroy();
    }
    this.charts = [];
  }

  private buildCharts(): void {
    this.destroyCharts();
    const a = this.analytics();
    if (!a) {
      return;
    }
    const loaded = this.okData();
    if (!loaded) {
      return;
    }
    const dayLabels = this.dayKeys.map((k) => {
      const [, m, d] = k.split('-');
      return `${d}/${m}`;
    });
    const brand = 'rgb(31, 60, 147)';
    const brandLight = 'rgba(31, 60, 147, 0.12)';
    const amber = 'rgb(217, 119, 6)';
    const teal = 'rgb(13, 148, 136)';
    const rose = 'rgb(225, 29, 72)';

    const invPriceEl = this.chartInvPrice()?.nativeElement;
    if (invPriceEl) {
      const priceData = a.priceAvgs.map((p) => (p == null ? null : p));
      this.charts.push(
        new Chart(invPriceEl, {
          type: 'line',
          data: {
            labels: dayLabels,
            datasets: [
              {
                label: 'Tồn (tổng)',
                data: a.invTotals,
                yAxisID: 'y',
                borderColor: brand,
                backgroundColor: brandLight,
                fill: true,
                tension: 0.35,
                pointRadius: 3,
                pointHoverRadius: 5,
              },
              {
                label: 'Giá TB (VNĐ/l)',
                data: priceData,
                yAxisID: 'y1',
                borderColor: amber,
                backgroundColor: 'transparent',
                tension: 0.35,
                pointRadius: 3,
                spanGaps: true,
              },
            ],
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            interaction: { mode: 'index', intersect: false },
            plugins: {
              legend: { position: 'top', labels: { font: { weight: 600 } } },
              tooltip: {
                callbacks: {
                  label: (ctx) => {
                    const v = ctx.parsed.y;
                    if (v == null) {
                      return `${ctx.dataset.label}: —`;
                    }
                    if (ctx.datasetIndex === 0) {
                      return `${ctx.dataset.label}: ${v.toLocaleString('vi-VN', { maximumFractionDigits: 2 })}`;
                    }
                    return `${ctx.dataset.label}: ${v.toLocaleString('vi-VN', { maximumFractionDigits: 0 })}`;
                  },
                },
              },
            },
            scales: {
              y: {
                type: 'linear',
                position: 'left',
                title: { display: true, text: 'Tồn kho' },
                grid: { color: 'rgba(0,0,0,0.06)' },
              },
              y1: {
                type: 'linear',
                position: 'right',
                title: { display: true, text: 'Giá TB' },
                grid: { drawOnChartArea: false },
              },
            },
          },
        }),
      );
    }

    const priceLinesEl = this.chartPriceLines()?.nativeElement;
    if (priceLinesEl) {
      const palette = [brand, amber, teal, rose, 'rgb(124, 58, 237)'];
      const ds = a.productIds.slice(0, 6).map((pid, idx) => ({
        label: a.labels.get(pid) ?? `Id ${pid}`,
        data: this.dayKeys.map((dk) => priceAsOfDay(dk, pid, loaded.priceHistory)),
        borderColor: palette[idx % palette.length],
        backgroundColor: 'transparent',
        tension: 0.32,
        pointRadius: 2,
        spanGaps: true,
      }));
      this.charts.push(
        new Chart(priceLinesEl, {
          type: 'line',
          data: { labels: dayLabels, datasets: ds },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            interaction: { mode: 'index', intersect: false },
            plugins: { legend: { position: 'top' } },
            scales: {
              y: {
                title: { display: true, text: 'Giá (VNĐ/l)' },
                grid: { color: 'rgba(0,0,0,0.06)' },
              },
            },
          },
        }),
      );
    }

    const invBarEl = this.chartInvBar()?.nativeElement;
    if (invBarEl) {
      const codes = loaded.inventory.map((r) => r.productCode);
      const qtys = loaded.inventory.map((r) => r.currentQuantity);
      this.charts.push(
        new Chart(invBarEl, {
          type: 'bar',
          data: {
            labels: codes,
            datasets: [
              {
                label: 'Tồn hiện tại',
                data: qtys,
                backgroundColor: loaded.inventory.map((_, i) => paletteBar(i)),
                borderRadius: 6,
              },
            ],
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { display: false } },
            scales: {
              y: { beginAtZero: true, title: { display: true, text: 'Số lượng' } },
            },
          },
        }),
      );
    }

    const invPieEl = this.chartInvPie()?.nativeElement;
    if (invPieEl && loaded.inventory.length) {
      this.charts.push(
        new Chart(invPieEl, {
          type: 'doughnut',
          data: {
            labels: loaded.inventory.map((r) => r.productCode),
            datasets: [
              {
                data: loaded.inventory.map((r) => Math.max(0, r.currentQuantity)),
                backgroundColor: loaded.inventory.map((_, i) => paletteBar(i)),
                borderWidth: 2,
                borderColor: '#fff',
              },
            ],
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { position: 'right' } },
          },
        }),
      );
    }

    const invDeltaEl = this.chartInvDelta()?.nativeElement;
    if (invDeltaEl) {
      const colors = a.invDelta.map((v) =>
        v > 0 ? 'rgba(21, 128, 61, 0.75)' : v < 0 ? 'rgba(185, 28, 28, 0.75)' : 'rgba(100,116,139,0.5)',
      );
      this.charts.push(
        new Chart(invDeltaEl, {
          type: 'bar',
          data: {
            labels: dayLabels,
            datasets: [{ label: 'Δ tồn (so ngày trước)', data: a.invDelta, backgroundColor: colors, borderRadius: 4 }],
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { display: false } },
            scales: { y: { title: { display: true, text: 'Chênh lệch' } } },
          },
        }),
      );
    }

    const priceDeltaEl = this.chartPriceDelta()?.nativeElement;
    if (priceDeltaEl) {
      const colors = a.priceDelta.map((v) =>
        v > 0 ? 'rgba(217, 119, 6, 0.85)' : v < 0 ? 'rgba(37, 99, 235, 0.75)' : 'rgba(148,163,184,0.5)',
      );
      this.charts.push(
        new Chart(priceDeltaEl, {
          type: 'bar',
          data: {
            labels: dayLabels,
            datasets: [{ label: 'Δ giá TB (VNĐ)', data: a.priceDelta, backgroundColor: colors, borderRadius: 4 }],
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { display: false } },
            scales: { y: { title: { display: true, text: 'Chênh giá TB' } } },
          },
        }),
      );
    }
  }

  formatPct(p: number | null): string {
    if (p == null || Number.isNaN(p)) {
      return '—';
    }
    const sign = p > 0 ? '+' : '';
    return `${sign}${p.toFixed(1)}%`;
  }

  trendClass(p: number | null): string {
    if (p == null || Number.isNaN(p) || p === 0) {
      return 'store-dash__trend--flat';
    }
    return p > 0 ? 'store-dash__trend--up' : 'store-dash__trend--down';
  }

  /** Tên mặt hàng cho bảng giá (map từ tồn kho hiện tại cùng cửa hàng). */
  productNameForId(data: { inventory: StoreAdminInventoryCurrentLineDto[] }, productId: number): string {
    const line = data.inventory.find((r) => r.productId === productId);
    const name = line?.productName?.trim();
    if (name) {
      return name;
    }
    return `Mặt hàng #${productId}`;
  }

  inventoryTxTypeLabel(transactionType: number): string {
    if (transactionType === 1) {
      return 'Nhập kho';
    }
    if (transactionType === -1) {
      return 'Xuất kho';
    }
    return `Loại ${transactionType}`;
  }
}

function paletteBar(i: number): string {
  const c = [
    'rgba(31, 60, 147, 0.85)',
    'rgba(13, 148, 136, 0.85)',
    'rgba(217, 119, 6, 0.88)',
    'rgba(225, 29, 72, 0.8)',
    'rgba(124, 58, 237, 0.82)',
    'rgba(14, 116, 144, 0.82)',
  ];
  return c[i % c.length]!;
}
