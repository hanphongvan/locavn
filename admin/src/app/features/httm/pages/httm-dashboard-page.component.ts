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
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { Router, RouterLink } from '@angular/router';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { Chart, registerables } from 'chart.js';
import * as L from 'leaflet';
import { take } from 'rxjs';

import { ApiRequestError } from '../../../core/http/api-request-error';
import { PageHeaderComponent, SectionCardComponent, StatCardComponent } from '../../../shared/ui';
import { mountSeaIslandGeoLabels } from '../../inventory-map/inventory-map-geo-labels';
import { SurveysApiService } from '../../surveys/services/surveys-api.service';
import type { HttmCatalogItemDto, HttmFacilityListItemDto } from '../models/httm-facility.model';
import type { HttmMapFeatureDto } from '../models/httm-map.model';
import type { HttmSubmissionListItem } from '../models/httm-submission.model';
import {
  HttmAnalyticsService,
  type AnalyticsSummaryRow,
  type TypeCountRow,
} from '../services/httm-analytics.service';
import { HttmCatalogService } from '../services/httm-catalog.service';
import { HttmFacilityService } from '../services/httm-facility.service';
import { HttmMapService } from '../services/httm-map.service';
import { HttmSubmissionService } from '../services/httm-submission.service';

Chart.register(...registerables);

const RECENT_TAKE = 5;
const MINI_MAP_MAX_ROWS = 500;

@Component({
  selector: 'app-httm-dashboard-page',
  standalone: true,
  imports: [
    CommonModule,
    RouterLink,
    MatSnackBarModule,
    PageHeaderComponent,
    SectionCardComponent,
    StatCardComponent,
  ],
  templateUrl: './httm-dashboard-page.component.html',
  styleUrl: './httm-dashboard-page.component.scss',
})
export class HttmDashboardPageComponent implements AfterViewInit, OnDestroy {
  private readonly analytics = inject(HttmAnalyticsService);
  private readonly surveysApi = inject(SurveysApiService);
  private readonly facilityApi = inject(HttmFacilityService);
  private readonly submissionsApi = inject(HttmSubmissionService);
  private readonly catalogs = inject(HttmCatalogService);
  private readonly mapService = inject(HttmMapService);
  private readonly snack = inject(MatSnackBar);
  private readonly router = inject(Router);

  @ViewChild('miniMap') miniMapHost?: ElementRef<HTMLElement>;

  readonly summary = signal<AnalyticsSummaryRow | null>(null);
  readonly notUpdatedCount = signal<number | null>(null);
  readonly recentSubmissions = signal<HttmSubmissionListItem[]>([]);
  readonly recentFacilities = signal<HttmFacilityListItemDto[]>([]);
  readonly typeLabels = signal<Map<string, string>>(new Map());
  readonly creatingSurvey = signal(false);
  readonly errorMessage = signal<string | null>(null);

  private chart: Chart | null = null;
  private map: L.Map | null = null;
  private markers: L.LayerGroup | null = null;

  constructor() {
    this.analytics
      .summary()
      .pipe(take(1), takeUntilDestroyed())
      .subscribe({
        next: (s) => this.summary.set(s),
        error: (e: unknown) => this.handleLoadError(e, 'Không tải được tóm tắt.'),
      });

    this.analytics
      .facilitiesNotUpdated()
      .pipe(take(1), takeUntilDestroyed())
      .subscribe({
        next: (r) => this.notUpdatedCount.set(r.count),
        error: (e: unknown) => this.handleLoadError(e, 'Không tải được số cơ sở chưa cập nhật.'),
      });

    this.submissionsApi
      .listAdmin({ page: 1, pageSize: RECENT_TAKE })
      .pipe(take(1), takeUntilDestroyed())
      .subscribe({
        next: (p) => this.recentSubmissions.set(p.items),
        error: () => this.recentSubmissions.set([]),
      });

    this.facilityApi
      .search({ page: 1, pageSize: RECENT_TAKE })
      .pipe(take(1), takeUntilDestroyed())
      .subscribe({
        next: (p) => this.recentFacilities.set(p.items),
        error: () => this.recentFacilities.set([]),
      });

    this.catalogs
      .getByType('httm_types')
      .pipe(take(1), takeUntilDestroyed())
      .subscribe({
        next: (rows: HttmCatalogItemDto[]) => {
          const m = new Map<string, string>();
          for (const r of rows) m.set(r.code, r.name);
          this.typeLabels.set(m);
        },
      });
  }

  ngAfterViewInit(): void {
    queueMicrotask(() => this.initMiniMap());

    this.analytics
      .facilitiesByType()
      .pipe(take(1), takeUntilDestroyed())
      .subscribe({
        next: (rows) => this.renderTypeChart(rows),
        error: (e: unknown) => this.handleLoadError(e, 'Không tải được biểu đồ loại cơ sở.'),
      });
  }

  ngOnDestroy(): void {
    this.chart?.destroy();
    this.chart = null;
    this.map?.remove();
    this.map = null;
    this.markers = null;
  }

  /** Hero CTA — tái dùng pattern openCreate từ survey-list: tạo phiếu nháp rồi navigate. */
  createSurveyDraft(): void {
    if (this.creatingSurvey()) return;
    this.creatingSurvey.set(true);
    this.surveysApi.create({ httmType: null }).subscribe({
      next: (r) => {
        this.snack.open('Đã tạo phiếu nháp', 'Đóng', { duration: 3000 });
        void this.router.navigate(['/surveys', r.id]);
      },
      error: (e: unknown) => {
        this.creatingSurvey.set(false);
        this.snack.open(
          e instanceof ApiRequestError ? e.message : 'Lỗi tạo phiếu',
          'Đóng',
          { duration: 6000 },
        );
      },
    });
  }

  exportCsv(): void {
    this.analytics.downloadSummaryCsv();
  }

  typeName(code: string | null | undefined): string {
    if (!code) return '—';
    return this.typeLabels().get(code) ?? code;
  }

  private renderTypeChart(rows: TypeCountRow[]): void {
    const el = document.getElementById('dash-chart-type') as HTMLCanvasElement | null;
    if (!el) return;
    const labels = rows.map((r) => this.typeName(r.httmType));
    const data = rows.map((r) => Number(r.count));
    this.chart?.destroy();
    this.chart = new Chart(el, {
      type: 'bar',
      data: {
        labels,
        datasets: [{ label: 'Cơ sở theo loại', data, backgroundColor: 'rgba(31, 60, 147, 0.67)' }],
      },
      options: {
        responsive: true,
        plugins: { legend: { display: false } },
        scales: { y: { beginAtZero: true, ticks: { precision: 0 } } },
      },
    });
  }

  private initMiniMap(): void {
    const el = this.miniMapHost?.nativeElement;
    if (!el) return;
    const spec = this.mapService.getTileSpec();
    this.map = L.map(el, { preferCanvas: true, zoomControl: false, attributionControl: false }).setView(
      [this.mapService.defaultCenterLat, this.mapService.defaultCenterLng],
      this.mapService.defaultZoom - 1,
    );
    L.tileLayer(spec.url, { attribution: spec.attribution, maxZoom: spec.maxZoom }).addTo(this.map);
    mountSeaIslandGeoLabels(this.map);
    this.markers = L.layerGroup().addTo(this.map);
    this.map.whenReady(() => {
      this.map!.fitBounds(L.latLngBounds([8.5, 102.5], [23.5, 109.5]), { animate: false });
      queueMicrotask(() => this.loadMiniMapMarkers());
    });
  }

  private loadMiniMapMarkers(): void {
    if (!this.map || !this.markers) return;
    const b = this.map.getBounds();
    this.facilityApi
      .getMapData({
        west: b.getWest(),
        south: b.getSouth(),
        east: b.getEast(),
        north: b.getNorth(),
        maxRows: MINI_MAP_MAX_ROWS,
      })
      .pipe(take(1))
      .subscribe({
        next: (fc) => {
          this.markers!.clearLayers();
          for (const f of fc.features) this.addFeatureMarker(f);
        },
      });
  }

  private addFeatureMarker(f: HttmMapFeatureDto): void {
    if (!this.markers) return;
    const [lng, lat] = f.geometry.coordinates;
    L.circleMarker([lat, lng], { radius: 4, color: '#162a66', weight: 1, fillOpacity: 0.85 }).addTo(this.markers);
  }

  private handleLoadError(err: unknown, fallback: string): void {
    this.errorMessage.set(err instanceof ApiRequestError ? err.message : fallback);
  }
}
