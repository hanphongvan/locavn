import { CommonModule } from '@angular/common';
import { Component, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MAT_DIALOG_DATA, MatDialogModule, MatDialogRef } from '@angular/material/dialog';
import { MatButtonModule } from '@angular/material/button';

import type { HttmCatalogItemDto, ProvinceOptionDto } from '../../httm/models/httm-facility.model';

export interface SurveyCreateDialogData {
  provinces: ProvinceOptionDto[];
  types: HttmCatalogItemDto[];
}

@Component({
  selector: 'app-survey-create-dialog',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, MatDialogModule, MatButtonModule],
  template: `
    <h2 matDialogTitle>Tạo phiếu khảo sát</h2>
    <mat-dialog-content>
      <form [formGroup]="form" class="dlg">
        <div class="form-field">
          <label class="form-label" for="dlg-prov">Tỉnh / TP</label>
          <select id="dlg-prov" class="form-control" formControlName="provinceCode">
            <option value="">Chọn</option>
            @for (p of data.provinces; track p.code) {
              <option [value]="p.code">{{ p.name }}</option>
            }
          </select>
        </div>
        <div class="form-field">
          <label class="form-label" for="dlg-type">Loại cơ sở</label>
          <select id="dlg-type" class="form-control" formControlName="httmType">
            <option value="">Chọn</option>
            @for (t of data.types; track t.id) {
              <option [value]="t.code">{{ t.name }}</option>
            }
          </select>
        </div>
      </form>
    </mat-dialog-content>
    <mat-dialog-actions align="end">
      <button mat-button type="button" (click)="ref.close()">Huỷ</button>
      <button mat-flat-button color="primary" type="button" [disabled]="form.invalid" (click)="ok()">Tạo</button>
    </mat-dialog-actions>
  `,
  styles: [
    `
      .dlg {
        display: flex;
        flex-direction: column;
        gap: 1rem;
        min-width: 260px;
        padding-top: 0.5rem;
      }
    `,
  ],
})
export class SurveyCreateDialogComponent {
  readonly data = inject<SurveyCreateDialogData>(MAT_DIALOG_DATA);
  readonly ref = inject(MatDialogRef<SurveyCreateDialogComponent, { provinceCode: string; httmType: string }>);
  private readonly fb = inject(FormBuilder);

  readonly form = this.fb.nonNullable.group({
    provinceCode: ['', Validators.required],
    httmType: ['', Validators.required],
  });

  ok(): void {
    const v = this.form.getRawValue();
    this.ref.close({ provinceCode: v.provinceCode, httmType: v.httmType });
  }
}
