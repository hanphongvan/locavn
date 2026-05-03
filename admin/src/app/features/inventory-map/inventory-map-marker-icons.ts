import * as L from 'leaflet';

/**
 * Trạng thái tồn kho → file ảnh trong `src/assets/map_markers/` (runtime URL qua {@link mapMarkersBaseUrl}).
 * PNG gốc 512×512; hiển thị qua `iconSize` cố định để Leaflet gán kích thước img, tránh scale tay/HTML.
 */
export type StockMarkerStatus = 'out' | 'low' | 'normal';

const MARKER_FILENAME: Record<StockMarkerStatus, string> = {
  out: 'station_closed.png',
  low: 'station_cheap.png',
  normal: 'station_open.png',
};

/**
 * Absolute URL prefix for marker PNGs (Leaflet resolves relative URLs against the page path, not `/`).
 * @param baseHref Value injected as `APP_BASE_HREF` (e.g. `/` or `/my-app/`).
 */
export function mapMarkersBaseUrl(baseHref: string): string {
  const raw = (baseHref ?? '/').trim() || '/';
  if (raw === '/') {
    return '/assets/map_markers/';
  }
  const base = raw.endsWith('/') ? raw.slice(0, -1) : raw;
  return `${base}/assets/map_markers/`;
}

/**
 * Kích thước hiển thị (CSS px) trên bản đồ — khớp với `iconSize` Leaflet (ảnh gốc 512×512 được trình duyệt downsample).
 * Nếu đổi kích thước hiển thị, chỉnh một chỗ tại đây.
 */
const ICON_WIDTH = 40;
const ICON_HEIGHT = 40;

/** Neo điểm địa lý: giữa đáy ô vuông (phù hợp icon “trạm” trong khung vuông). */
const ICON_ANCHOR: L.PointExpression = [ICON_WIDTH / 2, ICON_HEIGHT];

/** Popup mở phía trên neo. */
const POPUP_ANCHOR: L.PointExpression = [0, -ICON_HEIGHT];

const ICON_SIZE: L.PointExpression = [ICON_WIDTH, ICON_HEIGHT];

const iconCache = new Map<string, L.Icon>();

function markerIconUrl(status: StockMarkerStatus, baseHref: string): string {
  return `${mapMarkersBaseUrl(baseHref)}${MARKER_FILENAME[status]}`;
}

/**
 * Trả về `L.Icon` cho marker theo trạng thái tồn kho (tái sử dụng instance, tối đa 3 icon / baseHref).
 */
export function getMarkerIcon(stockStatus: StockMarkerStatus, baseHref: string): L.Icon {
  const key = `${baseHref}::${stockStatus}`;
  let icon = iconCache.get(key);
  if (!icon) {
    icon = L.icon({
      iconUrl: markerIconUrl(stockStatus, baseHref),
      iconSize: ICON_SIZE,
      iconAnchor: ICON_ANCHOR,
      popupAnchor: POPUP_ANCHOR,
    });
    iconCache.set(key, icon);
  }
  return icon;
}

/** Layout cố định (popup/tooltip offset tùy biến sau này). */
export const STATION_MARKER_LAYOUT = {
  iconSize: ICON_SIZE,
  iconAnchor: ICON_ANCHOR,
  popupAnchor: POPUP_ANCHOR,
} as const;
