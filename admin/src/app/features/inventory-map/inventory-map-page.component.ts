import { APP_BASE_HREF, CommonModule } from '@angular/common';
import {
  AfterViewInit,
  Component,
  ElementRef,
  OnDestroy,
  ViewChild,
  inject,
  signal,
} from '@angular/core';
import { take } from 'rxjs';

import * as L from 'leaflet';

import { ApiRequestError } from '../../core/http/api-request-error';
import { PageHeaderComponent } from '../../shared/ui';
import { getMarkerIcon, type StockMarkerStatus } from './inventory-map-marker-icons';
import { buildInventoryMapStationPopupHtml } from './inventory-map-station-popup';
import type {
  InventoryMapGroupCode,
  StoreAdminInventoryMapStationDto,
} from './models/store-admin-inventory-map.models';
import { mountSeaIslandGeoLabels } from './inventory-map-geo-labels';
import { InventoryMapApiService } from './services/inventory-map-api.service';

/** Approximate geographic center of Vietnam for default framing. */
const VIETNAM_MAP_CENTER: L.LatLngExpression = [15.9266657, 107.9650855];
const DEFAULT_ZOOM = 6;

/** ~1 km half-span along N/S and E/W from a point (WGS84 approximation). */
function boundsAroundPointKm(lat: number, lng: number, radiusKm: number): L.LatLngBounds {
  const rM = radiusKm * 1000;
  const dLat = rM / 111_320;
  const cosLat = Math.cos((lat * Math.PI) / 180);
  const dLng = rM / (111_320 * (Math.abs(cosLat) > 1e-6 ? cosLat : 1e-6));
  return L.latLngBounds([lat - dLat, lng - dLng], [lat + dLat, lng + dLng]);
}

function parseStockStatus(raw: string): StockMarkerStatus | null {
  const v = (raw ?? '').trim().toLowerCase().replace(/\s+/g, '');
  if (v === 'out' || v === 'low' || v === 'normal') {
    return v;
  }
  return null;
}

/**
 * Bản đồ tồn kho — Admin. Leaflet + nền Carto Positron (dữ liệu OSM, ít “mùi” POI hơn tile OSM mặc định);
 * dữ liệu trạm `GET /api/admin/inventory-map`; marker ảnh từ `getMarkerIcon`.
 */
@Component({
  selector: 'app-inventory-map-page',
  standalone: true,
  imports: [CommonModule, PageHeaderComponent],
  templateUrl: './inventory-map-page.component.html',
  styleUrl: './inventory-map-page.component.scss',
})
export class InventoryMapPageComponent implements AfterViewInit, OnDestroy {
  private readonly api = inject(InventoryMapApiService);
  private readonly baseHref = inject(APP_BASE_HREF, { optional: true }) ?? '/';

  @ViewChild('mapHost') mapHost!: ElementRef<HTMLElement>;
  @ViewChild('mapShell') mapShell!: ElementRef<HTMLElement>;

  readonly groupCode = signal<InventoryMapGroupCode>('XANG');
  readonly loading = signal(false);
  readonly errorMessage = signal<string | null>(null);
  /** Trình duyệt hỗ trợ Fullscreen API cho phần tử (ẩn nút nếu không). */
  readonly fullscreenSupported = signal(false);
  readonly mapFullscreen = signal(false);

  private map: L.Map | null = null;
  private markerLayer: L.FeatureGroup | null = null;
  private resizeObserver: ResizeObserver | null = null;
  private loadSeq = 0;
  /** When set, initial / reload framing prefers this view over fitting all markers. */
  private userRadiusBounds: L.LatLngBounds | null = null;

  private readonly onFullscreenChange = (): void => {
    this.syncMapFullscreenState();
  };

  ngAfterViewInit(): void {
    document.addEventListener('fullscreenchange', this.onFullscreenChange);
    document.addEventListener('webkitfullscreenchange', this.onFullscreenChange);
    queueMicrotask(() => {
      const shell = this.mapShell?.nativeElement;
      this.fullscreenSupported.set(!!shell && canRequestFullscreenOn(shell));
      this.initMap();
    });
  }

  ngOnDestroy(): void {
    document.removeEventListener('fullscreenchange', this.onFullscreenChange);
    document.removeEventListener('webkitfullscreenchange', this.onFullscreenChange);
    if (this.isMapShellFullscreen()) {
      void exitDocumentFullscreen().catch(() => undefined);
    }
    this.teardownMap();
  }

  setGroup(code: InventoryMapGroupCode): void {
    if (this.groupCode() === code) {
      return;
    }
    this.groupCode.set(code);
    this.loadStations();
  }

  toggleMapFullscreen(): void {
    const shell = this.mapShell?.nativeElement;
    if (!shell || !canRequestFullscreenOn(shell)) {
      return;
    }
    if (this.isMapShellFullscreen()) {
      void exitDocumentFullscreen().catch(() => undefined);
      return;
    }
    void requestFullscreenOn(shell).catch(() => undefined);
  }

  private initMap(): void {
    const el = this.mapHost?.nativeElement;
    const shell = this.mapShell?.nativeElement;
    if (!el || !shell || this.map) {
      return;
    }

    this.map = L.map(el, {
      center: VIETNAM_MAP_CENTER,
      zoom: DEFAULT_ZOOM,
      minZoom: 5,
      maxZoom: 18,
      zoomControl: true,
      attributionControl: true,
    });

    // Raster tiles cannot filter từng loại POI; Positron giảm đáng kể icon/điểm nền so với osm.org tiles.
    L.tileLayer('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png', {
      attribution:
        '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> ' +
        '&copy; <a href="https://carto.com/attributions">CARTO</a>',
      subdomains: 'abcd',
      maxNativeZoom: 20,
    }).addTo(this.map);

    mountSeaIslandGeoLabels(this.map);
    this.markerLayer = L.featureGroup().addTo(this.map);

    this.scheduleInvalidateSize();

    this.resizeObserver = new ResizeObserver(() => {
      this.map?.invalidateSize({ animate: false });
    });
    this.resizeObserver.observe(shell);

    this.requestUserLocationZoom1km();
    this.loadStations();
  }

  /**
   * Zoom tới vị trí hiện tại (~bán kính 1 km). Nếu từ chối / lỗi, giữ khung mặc định + fit theo marker.
   */
  private requestUserLocationZoom1km(): void {
    if (typeof navigator === 'undefined' || !navigator.geolocation) {
      return;
    }
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        if (!this.map) {
          return;
        }
        const { latitude, longitude } = pos.coords;
        if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
          return;
        }
        this.userRadiusBounds = boundsAroundPointKm(latitude, longitude, 1);
        this.applyMapFramingAfterData();
      },
      () => {
        /* user denied or timeout — keep Vietnam / marker fit */
      },
      { enableHighAccuracy: false, timeout: 10_000, maximumAge: 120_000 },
    );
  }

  private loadStations(): void {
    if (!this.map || !this.markerLayer) {
      return;
    }

    const seq = ++this.loadSeq;
    this.loading.set(true);
    this.errorMessage.set(null);
    this.markerLayer.clearLayers();

    this.api
      .list({ groupCode: this.groupCode() })
      .pipe(take(1))
      .subscribe({
        next: (res) => {
          if (seq !== this.loadSeq) {
            return;
          }
          this.renderMarkers(res.stations);
          this.applyMapFramingAfterData();
          this.loading.set(false);
        },
        error: (err: unknown) => {
          if (seq !== this.loadSeq) {
            return;
          }
          const msg = err instanceof ApiRequestError ? err.message : 'Không tải được dữ liệu bản đồ.';
          this.errorMessage.set(msg);
          this.loading.set(false);
        },
      });
  }

  private renderMarkers(stations: StoreAdminInventoryMapStationDto[]): void {
    if (!this.map || !this.markerLayer) {
      return;
    }

    for (const s of stations) {
      if (s.latitude == null || s.longitude == null) {
        continue;
      }
      const status = parseStockStatus(s.stockStatus);
      if (!status) {
        continue;
      }

      const marker = L.marker([s.latitude, s.longitude], {
        icon: getMarkerIcon(status, this.baseHref),
      }).bindPopup(
        buildInventoryMapStationPopupHtml(s, status),
        {
          maxWidth: 280,
          className: 'inv-map-popup-wrap',
          closeButton: true,
          autoPanPadding: [12, 12],
        },
      );
      marker.addTo(this.markerLayer);
    }
  }

  private fitMapToMarkers(): void {
    if (!this.map || !this.markerLayer) {
      return;
    }
    const layers = this.markerLayer.getLayers();
    if (layers.length === 0) {
      return;
    }
    const bounds = this.markerLayer.getBounds();
    if (bounds.isValid()) {
      this.map.fitBounds(bounds, { padding: [28, 28], maxZoom: 11 });
    }
  }

  private applyMapFramingAfterData(): void {
    if (!this.map) {
      return;
    }
    if (this.userRadiusBounds?.isValid()) {
      this.map.fitBounds(this.userRadiusBounds, { padding: [24, 24], maxZoom: 17 });
      return;
    }
    this.fitMapToMarkers();
  }

  private scheduleInvalidateSize(): void {
    requestAnimationFrame(() => {
      this.map?.invalidateSize({ animate: false });
    });
  }

  private teardownMap(): void {
    this.resizeObserver?.disconnect();
    this.resizeObserver = null;

    this.markerLayer = null;

    if (this.map) {
      this.map.remove();
      this.map = null;
    }
  }

  private isMapShellFullscreen(): boolean {
    const shell = this.mapShell?.nativeElement;
    if (!shell) {
      return false;
    }
    return fullscreenElementIs(shell);
  }

  private syncMapFullscreenState(): void {
    this.mapFullscreen.set(this.isMapShellFullscreen());
    queueMicrotask(() => this.map?.invalidateSize({ animate: false }));
  }
}

type FullscreenCapableElement = HTMLElement & {
  webkitRequestFullscreen?: () => Promise<void> | void;
  msRequestFullscreen?: () => Promise<void> | void;
};

function canRequestFullscreenOn(el: HTMLElement): boolean {
  const e = el as FullscreenCapableElement;
  return typeof e.requestFullscreen === 'function' || typeof e.webkitRequestFullscreen === 'function';
}

function requestFullscreenOn(el: HTMLElement): Promise<void> {
  const e = el as FullscreenCapableElement;
  if (typeof e.requestFullscreen === 'function') {
    return e.requestFullscreen();
  }
  if (typeof e.webkitRequestFullscreen === 'function') {
    const r = e.webkitRequestFullscreen() as void | Promise<void> | undefined;
    return r !== undefined && typeof (r as Promise<void>).then === 'function'
      ? (r as Promise<void>)
      : Promise.resolve();
  }
  return Promise.reject(new Error('fullscreen'));
}

function exitDocumentFullscreen(): Promise<void> {
  const d = document as Document & {
    webkitExitFullscreen?: () => Promise<void> | void;
    msExitFullscreen?: () => Promise<void> | void;
  };
  if (typeof document.exitFullscreen === 'function') {
    return document.exitFullscreen();
  }
  if (typeof d.webkitExitFullscreen === 'function') {
    return Promise.resolve(d.webkitExitFullscreen() as void | Promise<void>).then(() => undefined);
  }
  return Promise.resolve();
}

function fullscreenElementIs(el: HTMLElement): boolean {
  const d = document as Document & {
    webkitFullscreenElement?: Element | null;
    msFullscreenElement?: Element | null;
  };
  return (
    document.fullscreenElement === el ||
    d.webkitFullscreenElement === el ||
    d.msFullscreenElement === el
  );
}
