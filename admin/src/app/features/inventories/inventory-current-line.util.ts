import type { StoreAdminInventoryCurrentLineDto } from './models/store-admin-inventory-current.models';

/** Human-readable unit from aggregated inventory line (matches admin table conventions). */
export function formatInventoryCurrentLineUnitLabel(row: StoreAdminInventoryCurrentLineDto): string {
  const ma = row.unitMa?.trim();
  const ten = row.unitTen?.trim();
  if (ma && ten) {
    return `${ten}`;
  }
  if (ten) {
    return ten;
  }
  if (ma) {
    return ma;
  }
  if (row.unitId !== null && row.unitId !== undefined) {
    return `Đơn vị #${row.unitId}`;
  }
  return '—';
}
