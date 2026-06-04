import { CommonModule } from '@angular/common';
import { Component, OnInit, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { MatTableModule } from '@angular/material/table';
import { MatTooltipModule } from '@angular/material/tooltip';
import { RouterLink } from '@angular/router';

import type { HttmSubmissionListItem } from '../models/httm-submission.model';
import { HttmSubmissionService } from '../services/httm-submission.service';

@Component({
  selector: 'app-httm-submissions-list-page',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    RouterLink,
    MatButtonModule,
    MatFormFieldModule,
    MatIconModule,
    MatInputModule,
    MatSelectModule,
    MatSnackBarModule,
    MatTableModule,
    MatTooltipModule,
  ],
  templateUrl: './httm-submissions-list-page.component.html',
  styleUrls: ['./httm-submissions-list-page.component.scss'],
})
export class HttmSubmissionsListPageComponent implements OnInit {
  private readonly api = inject(HttmSubmissionService);
  private readonly snack = inject(MatSnackBar);

  readonly status = signal<string>('pending');
  readonly provinceCode = signal('');
  readonly submissionType = signal<string>('');
  readonly q = signal('');
  readonly page = signal(1);
  readonly pageSize = 20;
  readonly loading = signal(false);
  readonly exporting = signal(false);
  readonly items = signal<HttmSubmissionListItem[]>([]);
  readonly totalCount = signal(0);

  readonly columns = ['submittedAt', 'type', 'name', 'province', 'submitter', 'status', 'action'];

  ngOnInit(): void {
    this.reload();
  }

  reload(): void {
    this.loading.set(true);
    this.api
      .listAdmin({
        status: this.status() || undefined,
        provinceCode: this.provinceCode().trim() || undefined,
        submissionType: this.submissionType() || undefined,
        q: this.q().trim() || undefined,
        page: this.page(),
        pageSize: this.pageSize,
      })
      .subscribe({
        next: (r) => {
          this.items.set(r.items);
          this.totalCount.set(r.totalCount);
        },
        error: () => {
          this.items.set([]);
          this.totalCount.set(0);
        },
        complete: () => this.loading.set(false),
      });
  }

  applyFilter(): void {
    this.page.set(1);
    this.reload();
  }

  /** Xuất TẤT CẢ submissions khớp filter hiện tại (mọi trang) ra Excel. */
  exportExcel(): void {
    if (this.exporting()) return;
    this.exporting.set(true);
    this.api
      .exportExcel({
        status: this.status() || undefined,
        provinceCode: this.provinceCode().trim() || undefined,
        submissionType: this.submissionType() || undefined,
        q: this.q().trim() || undefined,
      })
      .subscribe({
        next: (resp) => {
          const blob = resp.body;
          if (!blob) {
            this.snack.open('Không nhận được file.', 'OK');
            return;
          }
          const cd = resp.headers.get('Content-Disposition') ?? '';
          const m = /filename\*?=(?:UTF-8'')?"?([^;\s"]+)"?/i.exec(cd);
          const filename = m ? decodeURIComponent(m[1]) : 'de-xuat-httm.xlsx';
          this.saveBlob(blob, filename);
        },
        error: () => this.snack.open('Xuất Excel thất bại.', 'Đóng'),
        complete: () => this.exporting.set(false),
      });
  }

  private saveBlob(blob: Blob, filename: string): void {
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  }

  prevPage(): void {
    if (this.page() > 1) {
      this.page.update((p) => p - 1);
      this.reload();
    }
  }

  nextPage(): void {
    if (this.page() * this.pageSize < this.totalCount()) {
      this.page.update((p) => p + 1);
      this.reload();
    }
  }

  totalPages(): number {
    return Math.max(1, Math.ceil(this.totalCount() / this.pageSize));
  }
}
