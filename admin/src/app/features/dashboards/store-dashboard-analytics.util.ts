import type { StoreAdminInventoryCurrentLineDto } from '../inventories/models/store-admin-inventory-current.models';
import type { StoreAdminInventoryTransactionBundleDto } from '../inventory-transactions/models/store-admin-inventory-transaction.models';
import type { StoreAdminStorePriceListItemDto } from '../store-prices/models/store-admin-store-price.models';

/** Giới hạn phiếu chi tiết tải thêm để ước lượng xu hướng (demo / hiệu năng). */
export const STORE_DASH_MAX_BUNDLES = 55;

/** Số ngày lấy header giao dịch. */
export const STORE_DASH_TX_LOOKBACK_DAYS = 120;

/** Số ngày hiển thị trên biểu đồ. */
export const STORE_DASH_CHART_DAYS = 21;

export interface StockMovement {
  atMs: number;
  productId: number;
  signedQty: number;
  amount: number | null;
  transactionType: number;
}

export function vnDayKeyFromMs(ms: number): string {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Ho_Chi_Minh',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(new Date(ms));
}

export function vnDayKeyToday(): string {
  return vnDayKeyFromMs(Date.now());
}

export function endOfVnDayMs(dayKey: string): number {
  return new Date(`${dayKey}T23:59:59.999+07:00`).getTime();
}

export function bundlesToMovements(bundles: StoreAdminInventoryTransactionBundleDto[]): StockMovement[] {
  const out: StockMovement[] = [];
  for (const b of bundles) {
    const atMs = new Date(b.transactionDate).getTime();
    if (Number.isNaN(atMs)) {
      continue;
    }
    for (const d of b.details) {
      const signedQty = b.transactionType * d.quantity;
      out.push({
        atMs,
        productId: d.productId,
        signedQty,
        amount: d.amount,
        transactionType: b.transactionType,
      });
    }
  }
  out.sort((a, b) => a.atMs - b.atMs);
  return out;
}

export function currentInventoryMap(lines: StoreAdminInventoryCurrentLineDto[]): Map<number, number> {
  const m = new Map<number, number>();
  for (const r of lines) {
    m.set(r.productId, r.currentQuantity);
  }
  return m;
}

export function productLabels(lines: StoreAdminInventoryCurrentLineDto[]): Map<number, string> {
  const m = new Map<number, string>();
  for (const r of lines) {
    m.set(r.productId, `${r.productCode}`.trim() || `Id ${r.productId}`);
  }
  return m;
}

/** Tồn từng mặt hàng tại cuối ngày (VN) — lùi từ tồn hiện tại và các dòng chi tiết đã tải. */
export function stockAtEndOfVnDay(
  dayKey: string,
  productId: number,
  currentByProduct: Map<number, number>,
  movements: StockMovement[],
): number {
  const endMs = endOfVnDayMs(dayKey);
  const base = currentByProduct.get(productId) ?? 0;
  let deltaAfter = 0;
  for (const mv of movements) {
    if (mv.productId !== productId) {
      continue;
    }
    if (mv.atMs > endMs) {
      deltaAfter += mv.signedQty;
    }
  }
  return base - deltaAfter;
}

export function vnCalendarAddDays(dayKey: string, deltaDays: number): string {
  const d = new Date(`${dayKey}T12:00:00+07:00`);
  d.setTime(d.getTime() + deltaDays * 86400000);
  return vnDayKeyFromMs(d.getTime());
}

/** Các mốc ngày `YYYY-MM-DD` (Asia/Ho_Chi_Minh), cũ → mới. */
export function chartDayKeysAscending(numDays: number): string[] {
  const today = vnDayKeyToday();
  const keys: string[] = [];
  for (let i = numDays - 1; i >= 0; i--) {
    keys.push(vnCalendarAddDays(today, -i));
  }
  return keys;
}

export function totalStockAtEndOfDay(
  dayKey: string,
  productIds: number[],
  currentByProduct: Map<number, number>,
  movements: StockMovement[],
): number {
  let t = 0;
  for (const pid of productIds) {
    t += stockAtEndOfVnDay(dayKey, pid, currentByProduct, movements);
  }
  return t;
}

/** Giá áp dụng cho mặt hàng tại hoặc trước cuối ngày `dayKey` (VN). */
export function priceAsOfDay(
  dayKey: string,
  productId: number,
  history: StoreAdminStorePriceListItemDto[],
): number | null {
  const endMs = endOfVnDayMs(dayKey);
  let best: StoreAdminStorePriceListItemDto | null = null;
  let bestMs = -Infinity;
  for (const h of history) {
    if (h.productId !== productId) {
      continue;
    }
    const t = new Date(h.effectiveDate).getTime();
    if (Number.isNaN(t) || t > endMs) {
      continue;
    }
    if (t >= bestMs) {
      bestMs = t;
      best = h;
    }
  }
  return best?.price ?? null;
}

export function averagePriceAsOfDay(
  dayKey: string,
  productIds: number[],
  history: StoreAdminStorePriceListItemDto[],
): number | null {
  let s = 0;
  let n = 0;
  for (const pid of productIds) {
    const p = priceAsOfDay(dayKey, pid, history);
    if (p != null && !Number.isNaN(p)) {
      s += p;
      n++;
    }
  }
  return n ? s / n : null;
}

export interface TodaySalesAgg {
  exportQty: number;
  importQty: number;
  revenue: number;
  exportHeaders: number;
}

export function aggregateTodayFromBundles(
  bundles: StoreAdminInventoryTransactionBundleDto[],
  todayKey: string,
): TodaySalesAgg {
  let exportQty = 0;
  let importQty = 0;
  let revenue = 0;
  let exportHeaders = 0;
  for (const b of bundles) {
    const dk = vnDayKeyFromMs(new Date(b.transactionDate).getTime());
    if (dk !== todayKey) {
      continue;
    }
    if (b.transactionType === -1) {
      exportHeaders++;
    }
    for (const d of b.details) {
      if (b.transactionType === -1) {
        exportQty += d.quantity;
        revenue += d.amount ?? 0;
      } else if (b.transactionType === 1) {
        importQty += d.quantity;
      }
    }
  }
  return { exportQty, importQty, revenue, exportHeaders };
}

export interface KpiModel {
  eodInventoryTotal: number;
  soldTodayQty: number;
  revenueToday: number;
  avgPriceToday: number | null;
  priceChangeVsYesterdayPct: number | null;
  todayKey: string;
  yesterdayKey: string;
}

export function buildKpis(
  inventory: StoreAdminInventoryCurrentLineDto[],
  pricesCurrent: StoreAdminStorePriceListItemDto[],
  priceHistory: StoreAdminStorePriceListItemDto[],
  bundles: StoreAdminInventoryTransactionBundleDto[],
): KpiModel {
  const todayKey = vnDayKeyToday();
  const yesterdayKey = vnCalendarAddDays(todayKey, -1);

  const eodInventoryTotal = inventory.reduce((s, r) => s + r.currentQuantity, 0);
  const sales = aggregateTodayFromBundles(bundles, todayKey);
  const productIds = [...new Set(inventory.map((r) => r.productId))];
  const avgToday = averagePriceAsOfDay(todayKey, productIds, priceHistory);
  const avgYest = averagePriceAsOfDay(yesterdayKey, productIds, priceHistory);
  let priceChangeVsYesterdayPct: number | null = null;
  if (avgToday != null && avgYest != null && avgYest !== 0) {
    priceChangeVsYesterdayPct = ((avgToday - avgYest) / avgYest) * 100;
  }
  let avgPriceToday = avgToday;
  if (avgPriceToday == null && pricesCurrent.length) {
    avgPriceToday = pricesCurrent.reduce((s, p) => s + p.price, 0) / pricesCurrent.length;
  }
  return {
    eodInventoryTotal,
    soldTodayQty: sales.exportQty,
    revenueToday: sales.revenue,
    avgPriceToday,
    priceChangeVsYesterdayPct,
    todayKey,
    yesterdayKey,
  };
}

export interface AlertItem {
  severity: 'warn' | 'danger' | 'info';
  title: string;
  detail: string;
}

const LOW_INV_ABS = 800;
const PRICE_SPIKE_PCT = 4;
const SALES_SPIKE_FACTOR = 2.2;

export function buildAlerts(
  inventory: StoreAdminInventoryCurrentLineDto[],
  dayKeys: string[],
  currentByProduct: Map<number, number>,
  movements: StockMovement[],
  priceHistory: StoreAdminStorePriceListItemDto[],
  productIds: number[],
  todaySalesQty: number,
): AlertItem[] {
  const alerts: AlertItem[] = [];
  for (const r of inventory) {
    if (r.currentQuantity < LOW_INV_ABS) {
      alerts.push({
        severity: 'warn',
        title: 'Tồn thấp',
        detail: `${r.productCode}: tồn ${r.currentQuantity.toLocaleString('vi-VN')} (< ${LOW_INV_ABS.toLocaleString('vi-VN')}).`,
      });
    }
  }
  if (dayKeys.length >= 2) {
    const a = dayKeys[dayKeys.length - 2]!;
    const b = dayKeys[dayKeys.length - 1]!;
    const pa = averagePriceAsOfDay(a, productIds, priceHistory);
    const pb = averagePriceAsOfDay(b, productIds, priceHistory);
    if (pa != null && pb != null && pa > 0) {
      const ch = ((pb - pa) / pa) * 100;
      if (Math.abs(ch) >= PRICE_SPIKE_PCT) {
        alerts.push({
          severity: 'danger',
          title: 'Biến động giá bất thường',
          detail: `Giá TB thay đổi ${ch >= 0 ? '+' : ''}${ch.toFixed(1)}% giữa ${a} và ${b}.`,
        });
      }
    }
  }
  const dailyExport: number[] = [];
  for (const dk of dayKeys) {
    const endMs = endOfVnDayMs(dk);
    const startMs = endOfVnDayMs(dk) - 86400000 + 1;
    let q = 0;
    for (const m of movements) {
      if (m.transactionType === -1 && m.atMs >= startMs && m.atMs <= endMs) {
        q += Math.abs(m.signedQty);
      }
    }
    dailyExport.push(q);
  }
  if (dailyExport.length >= 4) {
    const past = dailyExport.slice(0, -1);
    const med = median(past.filter((x) => x > 0));
    const last = dailyExport[dailyExport.length - 1] ?? 0;
    if (med > 0 && todaySalesQty > med * SALES_SPIKE_FACTOR) {
      alerts.push({
        severity: 'info',
        title: 'Xuất bán cao bất thường',
        detail: `Tổng xuất hôm nay vượt ~${SALES_SPIKE_FACTOR}× trung vị các ngày trước trong cửa sổ biểu đồ.`,
      });
    }
  }
  return alerts;
}

function median(nums: number[]): number {
  if (!nums.length) {
    return 0;
  }
  const s = [...nums].sort((a, b) => a - b);
  const mid = Math.floor(s.length / 2);
  return s.length % 2 ? s[mid]! : (s[mid - 1]! + s[mid]!) / 2;
}
