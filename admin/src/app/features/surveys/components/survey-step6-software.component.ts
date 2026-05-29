import { CommonModule } from '@angular/common';
import { Component, Input } from '@angular/core';
import { FormGroup, ReactiveFormsModule } from '@angular/forms';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';

import { SW_FEATURES, SW_PLATFORMS, SW_UTILITIES } from '../config/survey-enum-options';

/** Step 6 — Yêu cầu phần mềm. */
@Component({
  selector: 'app-survey-step6-software',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, MatFormFieldModule, MatInputModule, MatSelectModule],
  template: `
    <div class="step-form" [formGroup]="form">
      <div class="step-form__grid">
        <mat-form-field appearance="outline" class="full">
          <mat-label>Chức năng nghiệp vụ cần có (chọn nhiều)</mat-label>
          <mat-select formControlName="features" multiple>
            @for (o of features; track o.code) {
              <mat-option [value]="o.code">{{ o.label }}</mat-option>
            }
          </mat-select>
        </mat-form-field>

        <mat-form-field appearance="outline">
          <mat-label>Chức năng quản trị (admin)</mat-label>
          <mat-select formControlName="admin_features" multiple>
            @for (o of features; track o.code) {
              <mat-option [value]="o.code">{{ o.label }}</mat-option>
            }
          </mat-select>
        </mat-form-field>

        <mat-form-field appearance="outline">
          <mat-label>Tiện ích (chọn nhiều)</mat-label>
          <mat-select formControlName="utilities" multiple>
            @for (o of utilities; track o.code) {
              <mat-option [value]="o.code">{{ o.label }}</mat-option>
            }
          </mat-select>
        </mat-form-field>

        <mat-form-field appearance="outline" class="full">
          <mat-label>Nền tảng triển khai (chọn nhiều)</mat-label>
          <mat-select formControlName="platforms" multiple>
            @for (o of platforms; track o.code) {
              <mat-option [value]="o.code">{{ o.label }}</mat-option>
            }
          </mat-select>
        </mat-form-field>

        <mat-form-field appearance="outline" class="full">
          <mat-label>Tích hợp hệ thống ngoài</mat-label>
          <textarea matInput rows="2" formControlName="external_integrations"></textarea>
        </mat-form-field>
        <mat-form-field appearance="outline" class="full">
          <mat-label>Ghi chú khác</mat-label>
          <textarea matInput rows="2" formControlName="other_notes"></textarea>
        </mat-form-field>
      </div>
    </div>
  `,
  styles: [
    `
      .step-form { display: flex; flex-direction: column; gap: 12px; }
      .step-form__grid { display: grid; gap: 12px; grid-template-columns: 1fr 1fr; }
      .step-form__grid .full { grid-column: 1 / -1; }
      @media (max-width: 720px) { .step-form__grid { grid-template-columns: 1fr; } }
    `,
  ],
})
export class SurveyStep6SoftwareComponent {
  @Input({ required: true }) form!: FormGroup;
  readonly features = SW_FEATURES;
  readonly utilities = SW_UTILITIES;
  readonly platforms = SW_PLATFORMS;
}
