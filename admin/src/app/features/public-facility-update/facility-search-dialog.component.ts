import { CommonModule } from '@angular/common';
import { Component, OnInit, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatDialogModule, MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatSelectModule } from '@angular/material/select';
import { MatTableModule } from '@angular/material/table';

import type { HttmPublicFacilityRow } from '../httm/models/httm-submission.model';
import { HttmSubmissionService } from '../httm/services/httm-submission.service';

@Component({
  selector: 'app-facility-search-dialog',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    MatButtonModule,
    MatDialogModule,
    MatFormFieldModule,
    MatIconModule,
    MatInputModule,
    MatProgressSpinnerModule,
    MatSelectModule,
    MatTableModule,
  ],
  templateUrl: './facility-search-dialog.component.html',
  styleUrls: ['./facility-search-dialog.component.scss'],
})
export class FacilitySearchDialogComponent implements OnInit {
  private readonly ref = inject(MatDialogRef<FacilitySearchDialogComponent>);
  private readonly api = inject(HttmSubmissionService);

  readonly q = signal('');
  readonly provinceCode = signal('');
  readonly wardCode = signal('');
  readonly loading = signal(false);
  readonly results = signal<HttmPublicFacilityRow[]>([]);

  /** Dropdown options. */
  readonly provinces = signal<{ code: string; name: string }[]>([]);
  readonly wards = signal<{ code: string; name: string }[]>([]);
  readonly loadingWards = signal(false);

  readonly columns = ['name', 'httmType', 'provinceCode', 'wardCode', 'addressDetail'];

  ngOnInit(): void {
    this.api.listPublicProvinces().subscribe({
      next: (list) => this.provinces.set(list.map((p) => ({ code: p.code, name: p.name }))),
      error: () => this.provinces.set([]),
    });
  }

  /** Cascade khi user đổi tỉnh. */
  onProvinceChange(code: string): void {
    this.provinceCode.set(code);
    this.wardCode.set('');
    if (!code) {
      this.wards.set([]);
      return;
    }
    this.loadingWards.set(true);
    this.api.listPublicWardsByProvince(code).subscribe({
      next: (list) => this.wards.set(list.map((w) => ({ code: w.code, name: w.name }))),
      error: () => this.wards.set([]),
      complete: () => this.loadingWards.set(false),
    });
  }

  search(): void {
    this.loading.set(true);
    this.api
      .searchPublicFacilities({
        q: this.q().trim() || undefined,
        provinceCode: this.provinceCode().trim() || undefined,
        wardCode: this.wardCode().trim() || undefined,
        limit: 50,
      })
      .subscribe({
        next: (r) => this.results.set(r),
        error: () => this.results.set([]),
        complete: () => this.loading.set(false),
      });
  }

  pick(row: HttmPublicFacilityRow): void {
    this.ref.close(row);
  }

  close(): void {
    this.ref.close(null);
  }
}
