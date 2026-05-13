import { CommonModule } from '@angular/common';
import { HttpClient, HttpErrorResponse, HttpParams } from '@angular/common/http';
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

import { API_BASE_URL } from '../../core/tokens/api-base-url.token';
import type { HttmMapFeatureDto } from '../httm/models/httm-map.model';
import { HttmMapService } from '../httm/services/httm-map.service';
import { mountSeaIslandGeoLabels } from '../inventory-map/inventory-map-geo-labels';

function appendParams(params: HttpParams, key: string, value: string | number | null | undefined): HttpParams {
  if (value === null || value === undefined || value === '') {
    return params;
  }
  return params.set(key, String(value));
}

/** Bản đồ HTTM không cần đăng nhập — dữ liệu từ `GET /api/public/httm/map-data`. */
@Component({
  selector: 'app-public-httm-map-page',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './public-httm-map-page.component.html',
  styleUrl: './public-httm-map-page.component.scss',
})
export class PublicHttmMapPageComponent implements AfterViewInit, OnDestroy {
  private readonly http = inject(HttpClient);
  private readonly baseUrl = inject(API_BASE_URL).replace(/\/$/, '');
  readonly mapService = inject(HttmMapService);

  @ViewChild('mapHost') mapHost!: ElementRef<HTMLElement>;

  readonly loading = signal(false);
  readonly errorMessage = signal<string | null>(null);

  private map: L.Map | null = null;
  private markers: L.LayerGroup | null = null;

  ngAfterViewInit(): void {
    queueMicrotask(() => this.initMap());
  }

  ngOnDestroy(): void {
    this.map?.remove();
    this.map = null;
    this.markers = null;
  }

  reloadMarkers(): void {
    this.loadMarkers();
  }

  private initMap(): void {
    const el = this.mapHost?.nativeElement;
    if (!el) {
      return;
    }
    const spec = this.mapService.getTileSpec();
    this.map = L.map(el, { preferCanvas: true }).setView(
      [this.mapService.defaultCenterLat, this.mapService.defaultCenterLng],
      this.mapService.defaultZoom,
    );
    L.tileLayer(spec.url, { attribution: spec.attribution, maxZoom: spec.maxZoom }).addTo(this.map);
    mountSeaIslandGeoLabels(this.map);
    this.markers = L.layerGroup().addTo(this.map);
    this.map.whenReady(() => {
      const b0 = this.map!.getBounds();
      if (!b0.isValid()) {
        this.map!.fitBounds(L.latLngBounds([8.5, 102.5], [23.5, 109.5]), { animate: false });
      }
      queueMicrotask(() => this.loadMarkers());
    });
  }

  private loadMarkers(): void {
    if (!this.map || !this.markers) {
      return;
    }
    const b = this.map.getBounds();
    this.loading.set(true);
    this.errorMessage.set(null);
    let p = new HttpParams()
      .set('west', String(b.getWest()))
      .set('south', String(b.getSouth()))
      .set('east', String(b.getEast()))
      .set('north', String(b.getNorth()));
    p = appendParams(p, 'maxRows', 700);
    const url = `${this.baseUrl}/api/public/httm/map-data`;
    this.http
      .get<{ features: HttmMapFeatureDto[] }>(url, { params: p })
      .pipe(take(1))
      .subscribe({
        next: (fc) => {
          this.loading.set(false);
          this.markers!.clearLayers();
          for (const f of fc.features) {
            this.addFeatureMarker(f);
          }
        },
        error: (err: unknown) => {
          this.loading.set(false);
          const msg =
            err instanceof HttpErrorResponse ? err.error?.detail ?? err.message : 'Không tải được điểm bản đồ.';
          this.errorMessage.set(typeof msg === 'string' ? msg : 'Không tải được điểm bản đồ.');
        },
      });
  }

  private addFeatureMarker(f: HttmMapFeatureDto): void {
    if (!this.map || !this.markers) {
      return;
    }
    const [lng, lat] = f.geometry.coordinates;
    const m = L.circleMarker([lat, lng], { radius: 6, color: '#1565c0', weight: 2, fillOpacity: 0.85 });
    m.bindPopup(
      `<strong>${escapeHtml(f.properties.name)}</strong><br/>` +
        `${escapeHtml(f.properties.httmType)} · ${escapeHtml(f.properties.status)}`,
    );
    m.addTo(this.markers);
  }
}

function escapeHtml(s: string): string {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}
