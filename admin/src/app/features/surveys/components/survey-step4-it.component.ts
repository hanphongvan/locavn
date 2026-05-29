import { CommonModule } from '@angular/common';
import { Component, Input } from '@angular/core';
import { FormArray, FormGroup, ReactiveFormsModule } from '@angular/forms';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';

import { NETWORK_TYPES, SECURITY_MEASURES } from '../config/survey-enum-options';
import { SurveySoftwareListArrayComponent } from './survey-software-list-array.component';

/** Step 4 — Hạ tầng CNTT. */
@Component({
  selector: 'app-survey-step4-it',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatSlideToggleModule,
    SurveySoftwareListArrayComponent,
  ],
  template: `
    <div class="step-form" [formGroup]="form">
      <mat-slide-toggle formControlName="has_software">Đã có phần mềm quản lý</mat-slide-toggle>

      @if (form.controls['has_software'].value) {
        <h4 class="step-form__sub">Danh sách phần mềm hiện dùng</h4>
        <app-survey-software-list-array [arr]="swArr" arrName="software_list" [parentDummy]="form" [disabled]="form.disabled" />
      }

      <h4 class="step-form__sub">Trang thiết bị + Mạng</h4>
      <div class="step-form__grid">
        <mat-form-field appearance="outline">
          <mat-label>Số máy để bàn (Desktop)</mat-label>
          <input matInput type="number" min="0" formControlName="desktop_count" />
        </mat-form-field>
        <mat-form-field appearance="outline">
          <mat-label>Số máy xách tay (Laptop)</mat-label>
          <input matInput type="number" min="0" formControlName="laptop_count" />
        </mat-form-field>
        <mat-form-field appearance="outline" class="full">
          <mat-label>Mô tả máy chủ (Server)</mat-label>
          <textarea matInput rows="2" formControlName="server_description"></textarea>
        </mat-form-field>
        <mat-form-field appearance="outline">
          <mat-label>Loại mạng (chọn nhiều)</mat-label>
          <mat-select formControlName="network_types" multiple>
            @for (o of networkTypes; track o.code) {
              <mat-option [value]="o.code">{{ o.label }}</mat-option>
            }
          </mat-select>
        </mat-form-field>
        <mat-form-field appearance="outline">
          <mat-label>Băng thông Internet</mat-label>
          <input matInput formControlName="bandwidth" placeholder="VD: 100 Mbps" />
        </mat-form-field>
      </div>

      <h4 class="step-form__sub">Bảo mật</h4>
      <div class="step-form__grid">
        <mat-form-field appearance="outline" class="full">
          <mat-label>Biện pháp bảo mật (chọn nhiều)</mat-label>
          <mat-select formControlName="security_measures" multiple>
            @for (o of securityMeasures; track o.code) {
              <mat-option [value]="o.code">{{ o.label }}</mat-option>
            }
          </mat-select>
        </mat-form-field>
        <mat-form-field appearance="outline" class="full">
          <mat-label>Ghi chú về bảo mật</mat-label>
          <textarea matInput rows="2" formControlName="security_notes"></textarea>
        </mat-form-field>
      </div>
    </div>
  `,
  styles: [
    `
      .step-form { display: flex; flex-direction: column; gap: 12px; }
      .step-form__grid { display: grid; gap: 12px; grid-template-columns: 1fr 1fr; }
      .step-form__grid .full { grid-column: 1 / -1; }
      .step-form__sub { margin: 8px 0 4px; color: #37474f; }
      @media (max-width: 720px) { .step-form__grid { grid-template-columns: 1fr; } }
    `,
  ],
})
export class SurveyStep4ItComponent {
  @Input({ required: true }) form!: FormGroup;
  readonly networkTypes = NETWORK_TYPES;
  readonly securityMeasures = SECURITY_MEASURES;

  get swArr(): FormArray {
    return this.form.controls['software_list'] as FormArray;
  }
}
