import { Component, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule } from '@angular/forms';
import { MAT_DIALOG_DATA, MatDialogModule, MatDialogRef } from '@angular/material/dialog';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatSelectModule } from '@angular/material/select';

import type { HttmCatalogItemDto } from '../../httm/models/httm-facility.model';

export interface SurveyCreateDialogData {
  types: HttmCatalogItemDto[];
}

export interface SurveyCreateDialogResult {
  httmType: string | null;
}

@Component({
  selector: 'app-survey-create-dialog',
  standalone: true,
  imports: [ReactiveFormsModule, MatDialogModule, MatButtonModule, MatFormFieldModule, MatSelectModule],
  template: `
    <h2 mat-dialog-title>Tạo phiếu khảo sát nháp</h2>
    <mat-dialog-content>
      <p class="survey-create-dialog__hint">
        Tỉnh/TP được xác định theo tài khoản đăng nhập. Chọn loại cơ sở nếu phiếu gắn với một loại hình HTTM cụ thể.
      </p>
      <form [formGroup]="form" class="survey-create-dialog__form">
        <mat-form-field appearance="outline" class="survey-create-dialog__field">
          <mat-label>Loại cơ sở (tùy chọn)</mat-label>
          <mat-select formControlName="httmType">
            <mat-option [value]="''">— Khảo sát chung (không gắn loại) —</mat-option>
            @for (t of data.types; track t.id) {
              <mat-option [value]="t.code">{{ t.name }}</mat-option>
            }
          </mat-select>
        </mat-form-field>
      </form>
    </mat-dialog-content>
    <mat-dialog-actions align="end">
      <button mat-stroked-button type="button" mat-dialog-close>Hủy</button>
      <button mat-flat-button color="primary" type="button" (click)="submit()" [disabled]="form.invalid">
        Tạo phiếu nháp
      </button>
    </mat-dialog-actions>
  `,
  styles: [
    `
      .survey-create-dialog__hint {
        margin: 0 0 1rem;
        font-size: 0.875rem;
        line-height: 1.5;
        color: var(--app-text-muted);
      }

      .survey-create-dialog__form {
        display: block;
        min-width: min(360px, 88vw);
      }

      .survey-create-dialog__field {
        width: 100%;
      }
    `,
  ],
})
export class SurveyCreateDialogComponent {
  private readonly ref = inject(MatDialogRef<SurveyCreateDialogComponent, SurveyCreateDialogResult | undefined>);
  readonly data = inject<SurveyCreateDialogData>(MAT_DIALOG_DATA);
  private readonly fb = inject(FormBuilder);

  readonly form = this.fb.nonNullable.group({
    httmType: [''],
  });

  submit(): void {
    const raw = this.form.getRawValue().httmType.trim();
    this.ref.close({ httmType: raw || null });
  }
}
