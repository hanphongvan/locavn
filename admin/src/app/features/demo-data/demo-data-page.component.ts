import { CommonModule } from '@angular/common';
import { Component, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import type { Observable } from 'rxjs';
import { finalize } from 'rxjs/operators';

import { ApiRequestError } from '../../core/http/api-request-error';
import type { DemoDataOperationResult } from './services/demo-data-api.service';
import { DemoDataApiService } from './services/demo-data-api.service';
import { GeographyApiService } from '../geography/services/geography-api.service';

@Component({
  selector: 'app-demo-data-page',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './demo-data-page.component.html',
  styleUrl: './demo-data-page.component.scss',
})
export class DemoDataPageComponent {
  private readonly fb = inject(FormBuilder);
  private readonly demoApi = inject(DemoDataApiService);
  private readonly geoApi = inject(GeographyApiService);

  readonly provinces = signal<{ id: number; label: string }[]>([]);
  readonly provincesLoading = signal(false);
  readonly busy = signal(false);
  readonly message = signal<string | null>(null);
  readonly errorMessage = signal<string | null>(null);

  readonly form = this.fb.group({
    tinh: this.fb.control<number | null>(null, [Validators.required]),
    clearOldData: this.fb.nonNullable.control(false),
    days: this.fb.nonNullable.control(14, [Validators.required, Validators.min(1), Validators.max(400)]),
  });

  constructor() {
    this.provincesLoading.set(true);
    this.geoApi
      .listProvinces()
      .pipe(
        takeUntilDestroyed(),
        finalize(() => this.provincesLoading.set(false)),
      )
      .subscribe({
        next: (rows) =>
          this.provinces.set(
            rows.map((p) => ({
              id: p.id,
              label: `${p.name} (${p.id})`,
            })),
          ),
        error: (e: unknown) => {
          const msg = e instanceof ApiRequestError ? e.message : 'Could not load provinces.';
          this.errorMessage.set(msg);
        },
      });
  }

  private payload() {
    const v = this.form.getRawValue();
    const tinh = v.tinh;
    if (tinh === null || tinh === undefined) {
      return null;
    }
    return {
      tinh,
      clearOldData: v.clearOldData,
      days: v.days,
    };
  }

  clearData(): void {
    const p = this.payload();
    if (p === null || this.form.controls.tinh.invalid) {
      this.form.controls.tinh.markAsTouched();
      return;
    }
    this.run('Demo data cleared.', this.demoApi.clear(p));
  }

  generatePrices(): void {
    const p = this.payload();
    if (p === null || this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    this.run('Prices generated.', this.demoApi.generatePrices(p));
  }

  generateInventory(): void {
    const p = this.payload();
    if (p === null || this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    this.run('Inventory generated.', this.demoApi.generateInventory(p));
  }

  generateAll(): void {
    const p = this.payload();
    if (p === null || this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    this.run('Prices and inventory generated.', this.demoApi.generateAll(p));
  }

  private run(successText: string, obs: Observable<DemoDataOperationResult>): void {
    this.message.set(null);
    this.errorMessage.set(null);
    this.busy.set(true);
    obs.pipe(finalize(() => this.busy.set(false))).subscribe({
      next: (r) => {
        if (r.success) {
          const fromApi = r.message?.trim();
          this.message.set(fromApi && fromApi.length > 0 ? fromApi : successText);
        } else {
          this.errorMessage.set(r.message ?? 'Operation failed.');
        }
      },
      error: (e: unknown) => {
        const msg = e instanceof ApiRequestError ? e.message : 'Operation failed.';
        this.errorMessage.set(msg);
      },
    });
  }
}
