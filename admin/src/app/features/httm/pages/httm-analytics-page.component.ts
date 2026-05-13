import { CommonModule } from '@angular/common';
import { AfterViewInit, Component, OnDestroy, inject, signal } from '@angular/core';
import { take } from 'rxjs';
import { Chart, registerables } from 'chart.js';

import { PageHeaderComponent, SectionCardComponent } from '../../../shared/ui';
import type { AnalyticsSummaryRow } from '../services/httm-analytics.service';
import { HttmAnalyticsService } from '../services/httm-analytics.service';

Chart.register(...registerables);

@Component({
  selector: 'app-httm-analytics-page',
  standalone: true,
  imports: [CommonModule, PageHeaderComponent, SectionCardComponent],
  templateUrl: './httm-analytics-page.component.html',
  styleUrl: './httm-analytics-page.component.scss',
})
export class HttmAnalyticsPageComponent implements AfterViewInit, OnDestroy {
  private readonly analytics = inject(HttmAnalyticsService);

  readonly summary = signal<AnalyticsSummaryRow | null>(null);
  readonly errorMessage = signal<string | null>(null);
  readonly loading = signal(true);

  private charts: Chart[] = [];

  ngAfterViewInit(): void {
    this.analytics
      .summary()
      .pipe(take(1))
      .subscribe({
        next: (s) => this.summary.set(s),
        error: () => {},
      });

    this.analytics
      .facilitiesByType()
      .pipe(take(1))
      .subscribe({
        next: (rows) => {
          this.renderBar('chart-type', 'Cơ sở theo loại', rows.map((r) => r.httmType), rows.map((r) => Number(r.count)));
        },
        error: (e) => this.errorMessage.set(String(e?.message ?? e)),
      });

    this.analytics
      .facilitiesByProvince(12)
      .pipe(take(1))
      .subscribe({
        next: (rows) =>
          this.renderBar(
            'chart-prov',
            'Cơ sở theo tỉnh (Top 12)',
            rows.map((r) => r.provinceCode),
            rows.map((r) => Number(r.count)),
          ),
      });

    this.analytics
      .surveysByStatus()
      .pipe(take(1))
      .subscribe({
        next: (rows) =>
          this.renderBar('chart-status', 'Phiếu theo trạng thái', rows.map((r) => r.status), rows.map((r) => Number(r.count))),
      });

    this.analytics
      .facilityCreatedByMonth(6)
      .pipe(take(1))
      .subscribe({
        next: (rows) =>
          this.renderBar(
            'chart-fac-m',
            'Tạo hồ sơ theo tháng',
            rows.map((r) => r.month),
            rows.map((r) => Number(r.count)),
          ),
      });

    this.analytics
      .surveySubmittedByMonth(6)
      .pipe(take(1))
      .subscribe({
        next: (rows) => {
          this.renderBar(
            'chart-sv-m',
            'Nộp phiếu theo tháng',
            rows.map((r) => r.month),
            rows.map((r) => Number(r.count)),
          );
          this.loading.set(false);
        },
        error: () => this.loading.set(false),
      });
  }

  ngOnDestroy(): void {
    for (const c of this.charts) {
      c.destroy();
    }
    this.charts = [];
  }

  exportCsv(): void {
    this.analytics.downloadSummaryCsv();
  }

  private renderBar(canvasId: string, title: string, labels: string[], data: number[]): void {
    queueMicrotask(() => {
      const el = document.getElementById(canvasId) as HTMLCanvasElement | null;
      if (!el) {
        return;
      }
      const chart = new Chart(el, {
        type: 'bar',
        data: {
          labels,
          datasets: [{ label: title, data, backgroundColor: '#1976d2aa' }],
        },
        options: {
          responsive: true,
          plugins: { legend: { display: false } },
          scales: { y: { beginAtZero: true } },
        },
      });
      this.charts.push(chart);
    });
  }
}
