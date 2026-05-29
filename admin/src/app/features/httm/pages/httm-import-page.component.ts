import { CommonModule } from '@angular/common';
import { Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';
import { MatCheckboxModule } from '@angular/material/checkbox';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { MatStepperModule } from '@angular/material/stepper';
import { MatTableModule } from '@angular/material/table';
import { Router, RouterLink } from '@angular/router';

import type {
  HttmImportConfirmResponse,
  HttmImportRowError,
  HttmImportValidateResponse,
} from '../models/httm-import.model';
import { HttmImportService } from '../services/httm-import.service';

@Component({
  selector: 'app-httm-import-page',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    RouterLink,
    MatButtonModule,
    MatCardModule,
    MatCheckboxModule,
    MatIconModule,
    MatProgressSpinnerModule,
    MatSnackBarModule,
    MatStepperModule,
    MatTableModule,
  ],
  templateUrl: './httm-import-page.component.html',
  styleUrls: ['./httm-import-page.component.scss'],
})
export class HttmImportPageComponent {
  private readonly api = inject(HttmImportService);
  private readonly snack = inject(MatSnackBar);
  private readonly router = inject(Router);

  readonly file = signal<File | null>(null);
  readonly downloading = signal(false);
  readonly validating = signal(false);
  readonly confirming = signal(false);

  readonly validateResult = signal<HttmImportValidateResponse | null>(null);
  readonly confirmResult = signal<HttmImportConfirmResponse | null>(null);

  readonly skipErrors = signal(false);

  readonly previewColumns = ['rowNumber', 'name', 'httmType', 'provinceCode', 'addressDetail'];
  readonly errorColumns = ['rowNumber', 'column', 'message'];

  /** Step 1: tải template */
  downloadTemplate(): void {
    if (this.downloading()) return;
    this.downloading.set(true);
    this.api.downloadTemplate().subscribe({
      next: (resp) => {
        const blob = resp.body;
        if (!blob) {
          this.snack.open('Không nhận được file mẫu.', 'OK');
          return;
        }
        const cd = resp.headers.get('Content-Disposition') ?? '';
        const m = /filename\*?=(?:UTF-8'')?"?([^;\s"]+)"?/i.exec(cd);
        const filename = m ? decodeURIComponent(m[1]) : `httm-import-template.xlsx`;
        this.saveBlob(blob, filename);
      },
      error: () => this.snack.open('Tải mẫu thất bại.', 'Đóng'),
      complete: () => this.downloading.set(false),
    });
  }

  /** Step 1: chọn file từ input */
  onFileSelected(ev: Event): void {
    const f = (ev.target as HTMLInputElement | null)?.files?.[0] ?? null;
    if (!f) return;
    if (!f.name.toLowerCase().endsWith('.xlsx')) {
      this.snack.open('Chỉ hỗ trợ định dạng .xlsx.', 'OK');
      return;
    }
    if (f.size > 10 * 1024 * 1024) {
      this.snack.open('File vượt 10MB.', 'OK');
      return;
    }
    this.file.set(f);
    this.validateResult.set(null);
    this.confirmResult.set(null);
  }

  /** Step 1 → Step 2: upload + validate */
  runValidate(): void {
    const f = this.file();
    if (!f || this.validating()) return;
    this.validating.set(true);
    this.api.validate(f).subscribe({
      next: (r) => {
        this.validateResult.set(r);
        this.snack.open(
          `Hợp lệ: ${r.validCount} / Tổng ${r.totalRows} dòng. Lỗi: ${r.errorCount}. Trùng: ${r.skippedDuplicateCount}.`,
          'OK',
          { duration: 4000 },
        );
      },
      error: (e) =>
        this.snack.open(`Không validate được: ${e?.error?.detail ?? e?.message ?? 'lỗi'}`, 'Đóng', {
          duration: 6000,
        }),
      complete: () => this.validating.set(false),
    });
  }

  /** Step 2 → Step 3: confirm */
  runConfirm(): void {
    const r = this.validateResult();
    if (!r || this.confirming()) return;
    if (r.validCount === 0) {
      this.snack.open('Không có dòng hợp lệ để import.', 'OK');
      return;
    }
    this.confirming.set(true);
    this.api.confirm({ sessionToken: r.sessionToken, skipErrors: this.skipErrors() }).subscribe({
      next: (res) => {
        this.confirmResult.set(res);
        this.snack.open(
          `Đã tạo ${res.created} hồ sơ. Bỏ qua trùng ${res.skippedDuplicates}. Lỗi ${res.perRowErrors.length}.`,
          'OK',
          { duration: 5000 },
        );
      },
      error: (e) =>
        this.snack.open(`Confirm thất bại: ${e?.error?.detail ?? e?.message ?? 'lỗi'}`, 'Đóng', {
          duration: 8000,
        }),
      complete: () => this.confirming.set(false),
    });
  }

  goBackToList(): void {
    void this.router.navigate(['/httm/hoso']);
  }

  hasBlockingErrors(): boolean {
    const r = this.validateResult();
    return !!r && r.errorCount > 0 && !this.skipErrors();
  }

  errorsToString(errors: HttmImportRowError[]): string {
    return errors.map((e) => `Dòng ${e.rowNumber} (${e.column ?? 'N/A'}): ${e.message}`).join('\n');
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
}
