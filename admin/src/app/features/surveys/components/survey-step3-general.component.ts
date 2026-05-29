import { CommonModule } from '@angular/common';
import { Component, Input } from '@angular/core';
import { FormArray, FormGroup, ReactiveFormsModule } from '@angular/forms';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';

import {
  MAIN_ACTIVITIES,
  REPORT_SEND_METHODS,
  REPORT_TOOLS,
  UNIT_TYPES,
} from '../config/survey-enum-options';
import { SurveyLegalDocsArrayComponent } from './survey-legal-docs-array.component';
import { SurveyMembersArrayComponent } from './survey-members-array.component';

/** Step 3 — Hiện trạng hoạt động. */
@Component({
  selector: 'app-survey-step3-general',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    SurveyLegalDocsArrayComponent,
    SurveyMembersArrayComponent,
  ],
  template: `
    <div class="step-form" [formGroup]="form">
      <div class="step-form__grid">
        <mat-form-field appearance="outline" class="full">
          <mat-label>Loại hình đơn vị * (chọn nhiều)</mat-label>
          <mat-select formControlName="unit_types" multiple>
            @for (o of unitTypes; track o.code) {
              <mat-option [value]="o.code">{{ o.label }}</mat-option>
            }
          </mat-select>
          @if (form.controls['unit_types'].touched && form.controls['unit_types'].invalid) {
            <mat-error>Chọn ít nhất 1 loại hình khi nộp.</mat-error>
          }
        </mat-form-field>

        <mat-form-field appearance="outline" class="full">
          <mat-label>Hoạt động chính * (chọn nhiều)</mat-label>
          <mat-select formControlName="main_activities" multiple>
            @for (o of mainActivities; track o.code) {
              <mat-option [value]="o.code">{{ o.label }}</mat-option>
            }
          </mat-select>
          @if (form.controls['main_activities'].touched && form.controls['main_activities'].invalid) {
            <mat-error>Chọn ít nhất 1 hoạt động khi nộp.</mat-error>
          }
        </mat-form-field>

        <mat-form-field appearance="outline" class="full">
          <mat-label>Phạm vi hoạt động</mat-label>
          <textarea matInput rows="2" formControlName="operation_scope"></textarea>
        </mat-form-field>

        <mat-form-field appearance="outline">
          <mat-label>Đơn vị cấp trên</mat-label>
          <input matInput formControlName="parent_unit" />
        </mat-form-field>
        <mat-form-field appearance="outline">
          <mat-label>Đơn vị trực thuộc</mat-label>
          <input matInput formControlName="sub_units" />
        </mat-form-field>

        <mat-form-field appearance="outline">
          <mat-label>Tổng số cán bộ</mat-label>
          <input matInput type="number" min="0" formControlName="staff_count" />
        </mat-form-field>

        <mat-form-field appearance="outline">
          <mat-label>Công cụ làm báo cáo (chọn nhiều)</mat-label>
          <mat-select formControlName="report_tool" multiple>
            @for (o of reportTools; track o.code) {
              <mat-option [value]="o.code">{{ o.label }}</mat-option>
            }
          </mat-select>
        </mat-form-field>

        <mat-form-field appearance="outline" class="full">
          <mat-label>Phương thức gửi báo cáo (chọn nhiều)</mat-label>
          <mat-select formControlName="report_send_method" multiple>
            @for (o of reportSendMethods; track o.code) {
              <mat-option [value]="o.code">{{ o.label }}</mat-option>
            }
          </mat-select>
        </mat-form-field>
      </div>

      <h4 class="step-form__sub">Văn bản pháp lý liên quan</h4>
      <app-survey-legal-docs-array [arr]="legalDocsArr" arrName="legal_documents" [parentDummy]="form" [disabled]="form.disabled" />

      <h4 class="step-form__sub">Cán bộ phụ trách</h4>
      <app-survey-members-array [arr]="staffArr" arrName="responsible_staff" mode="compact" [parentDummy]="form" [disabled]="form.disabled" />
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
export class SurveyStep3GeneralComponent {
  @Input({ required: true }) form!: FormGroup;
  readonly unitTypes = UNIT_TYPES;
  readonly mainActivities = MAIN_ACTIVITIES;
  readonly reportTools = REPORT_TOOLS;
  readonly reportSendMethods = REPORT_SEND_METHODS;

  get legalDocsArr(): FormArray {
    return this.form.controls['legal_documents'] as FormArray;
  }
  get staffArr(): FormArray {
    return this.form.controls['responsible_staff'] as FormArray;
  }
}
