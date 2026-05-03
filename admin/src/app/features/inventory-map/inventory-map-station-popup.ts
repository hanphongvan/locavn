import type { StockMarkerStatus } from './inventory-map-marker-icons';
import type { StoreAdminInventoryMapStationDto } from './models/store-admin-inventory-map.models';

const STATUS_LABEL: Record<StockMarkerStatus, string> = {
  out: 'Hết hàng',
  low: 'Cạn kho',
  normal: 'Đủ hàng',
};

function escapeHtml(text: string): string {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function formatQuantity(value: number): string {
  return new Intl.NumberFormat('vi-VN', { maximumFractionDigits: 3 }).format(value);
}

/**
 * Compact HTML for Leaflet `bindPopup` — fields from API only, escaped.
 */
export function buildInventoryMapStationPopupHtml(
  station: StoreAdminInventoryMapStationDto,
  status: StockMarkerStatus,
): string {
  const name = escapeHtml(station.stationName.trim() || station.stationCode);
  const addrRaw = station.address?.trim();
  const addr = addrRaw ? escapeHtml(addrRaw) : '—';
  const qty = formatQuantity(station.currentQuantity);
  const badgeClass =
    status === 'out' ? 'inv-map-popup__badge--out' : status === 'low' ? 'inv-map-popup__badge--low' : 'inv-map-popup__badge--normal';
  const badgeText = escapeHtml(STATUS_LABEL[status]);

  return [
    '<div class="inv-map-popup">',
    `<div class="inv-map-popup__name">${name}</div>`,
    `<div class="inv-map-popup__addr">${addr}</div>`,
    '<div class="inv-map-popup__row">',
    '<span class="inv-map-popup__label">Tồn</span>',
    `<span class="inv-map-popup__qty">${qty}</span>`,
    '</div>',
    '<div class="inv-map-popup__row inv-map-popup__row--status">',
    `<span class="inv-map-popup__badge ${badgeClass}">${badgeText}</span>`,
    '</div>',
    '</div>',
  ].join('');
}
