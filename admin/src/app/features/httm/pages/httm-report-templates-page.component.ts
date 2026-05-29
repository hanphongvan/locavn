import { CommonModule } from '@angular/common';
import { Component, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { Subject, switchMap, tap } from 'rxjs';
import { finalize } from 'rxjs/operators';

import { ApiRequestError } from '../../../core/http/api-request-error';
import { PageHeaderComponent, SectionCardComponent } from '../../../shared/ui';
import type { HttmReportTemplateDto } from '../services/httm-report-templates.service';
import { HttmReportTemplatesService } from '../services/httm-report-templates.service';

@Component({
  selector: 'app-httm-report-templates-page',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, MatSnackBarModule, PageHeaderComponent, SectionCardComponent],
  templateUrl: './httm-report-templates-page.component.html',
  styleUrl: './httm-report-templates-page.component.scss',
})
export class HttmReportTemplatesPageComponent {
  private readonly api = inject(HttmReportTemplatesService);
  private readonly fb = inject(FormBuilder);
  private readonly snack = inject(MatSnackBar);

  readonly rows = signal<HttmReportTemplateDto[]>([]);
  readonly loading = signal(false);
  readonly errorMessage = signal<string | null>(null);
  readonly editingId = signal<string | null>(null);

  readonly form = this.fb.nonNullable.group({
    code: ['', Validators.required],
    name: ['', Validators.required],
    description: [''],
    reminderIntervalDays: [30, [Validators.required, Validators.min(1), Validators.max(3660)]],
    isActive: [true],
  });

  private readonly refresh$ = new Subject<void>();

  constructor() {
    this.refresh$
      .pipe(
        tap(() => this.loading.set(true)),
        switchMap(() => this.api.list(true).pipe(finalize(() => this.loading.set(false)))),
        takeUntilDestroyed(),
      )
      .subscribe({
        next: (list) => {
          this.rows.set(list);
          this.errorMessage.set(null);
        },
        error: (e: unknown) => {
          this.rows.set([]);
          this.errorMessage.set(e instanceof ApiRequestError ? e.message : 'Không tải được danh sách.');
        },
      });
    queueMicrotask(() => this.refresh$.next());
  }

  newTemplate(): void {
    this.editingId.set(null);
    this.form.reset({
      code: '',
      name: '',
      description: '',
      reminderIntervalDays: 30,
      isActive: true,
    });
  }

  edit(row: HttmReportTemplateDto): void {
    this.editingId.set(row.id);
    this.form.patchValue({
      code: row.code,
      name: row.name,
      description: row.description ?? '',
      reminderIntervalDays: row.reminderIntervalDays,
      isActive: row.isActive,
    });
  }

  save(): void {
    if (this.form.invalid) {
      return;
    }
    const v = this.form.getRawValue();
    const id = this.editingId();
    this.api
      .upsert({
        id: id ?? undefined,
        code: v.code.trim(),
        name: v.name.trim(),
        description: v.description?.trim() || null,
        reminderIntervalDays: v.reminderIntervalDays,
        isActive: v.isActive,
      })
      .subscribe({
        next: () => {
          this.snack.open('Đã lưu mẫu', 'Đóng', { duration: 2500 });
          this.refresh$.next();
        },
        error: (e: unknown) =>
          this.snack.open(e instanceof ApiRequestError ? e.message : 'Lỗi lưu', 'Đóng', { duration: 5000 }),
      });
  }

  remove(row: HttmReportTemplateDto): void {
    if (!confirm(`Xoá mẫu ${row.code}?`)) {
      return;
    }
    this.api.delete(row.id).subscribe({
      next: () => {
        this.snack.open('Đã xoá', 'Đóng', { duration: 2000 });
        if (this.editingId() === row.id) {
          this.newTemplate();
        }
        this.refresh$.next();
      },
      error: (e: unknown) =>
        this.snack.open(e instanceof ApiRequestError ? e.message : 'Lỗi xoá', 'Đóng', { duration: 5000 }),
    });
  }
}
