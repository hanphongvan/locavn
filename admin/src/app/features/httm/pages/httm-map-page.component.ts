import { CommonModule } from '@angular/common';
import {
  AfterViewInit,
  Component,
  ElementRef,
  OnDestroy,
  ViewChild,
  inject,
  signal,
} from '@angular/core';
import { RouterLink } from '@angular/router';
import { take } from 'rxjs';

import * as L from 'leaflet';

import { ApiRequestError } from '../../../core/http/api-request-error';
import { PageHeaderComponent } from '../../../shared/ui';
import { mountSeaIslandGeoLabels } from '../../inventory-map/inventory-map-geo-labels';
import type { HttmMapFeatureDto } from '../models/httm-map.model';
import { HttmFacilityService } from '../services/httm-facility.service';
import { HttmMapService } from '../services/httm-map.service';

@Component({
  selector: 'app-httm-map-page',
  standalone: true,
  imports: [CommonModule, RouterLink, PageHeaderComponent],
  templateUrl: './httm-map-page.component.html',
  styleUrl: './httm-map-page.component.scss',
})
export class HttmMapPageComponent implements AfterViewInit, OnDestroy {
  private readonly api = inject(HttmFacilityService);
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

  onProvider(v: string): void {
    if (v === 'goong' || v === 'osm') {
      this.mapService.setTileProvider(v);
    }
    this.refreshBasemap();
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

  private refreshBasemap(): void {
    if (!this.map) {
      return;
    }
    this.map.eachLayer((layer) => {
      if (layer instanceof L.TileLayer) {
        this.map!.removeLayer(layer);
      }
    });
    const spec = this.mapService.getTileSpec();
    L.tileLayer(spec.url, { attribution: spec.attribution, maxZoom: spec.maxZoom }).addTo(this.map);
  }

  private loadMarkers(): void {
    if (!this.map || !this.markers) {
      return;
    }
    const b = this.map.getBounds();
    this.loading.set(true);
    this.errorMessage.set(null);
    this.api
      .getMapData({
        west: b.getWest(),
        south: b.getSouth(),
        east: b.getEast(),
        north: b.getNorth(),
        maxRows: 1500,
      })
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
          this.errorMessage.set(err instanceof ApiRequestError ? err.message : 'Không tải được điểm bản đồ.');
        },
      });
  }

  private addFeatureMarker(f: HttmMapFeatureDto): void {
    if (!this.map || !this.markers) {
      return;
    }
    const [lng, lat] = f.geometry.coordinates;
    const m = L.circleMarker([lat, lng], { radius: 6, color: '#162a66', weight: 2, fillOpacity: 0.85 });
    m.bindPopup(
      `<strong>${escapeHtml(f.properties.name)}</strong><br/>` +
        `${escapeHtml(f.properties.httmType)} · ${escapeHtml(f.properties.status)}<br/>` +
        `<a href="/httm/${f.id}">Mở chi tiết</a>`,
    );
    m.addTo(this.markers);
  }
}

function escapeHtml(s: string): string {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}
