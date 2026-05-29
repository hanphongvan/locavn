import { CommonModule } from '@angular/common';
import { Component, Input } from '@angular/core';
import { FormGroup, ReactiveFormsModule } from '@angular/forms';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';

import { INFO_NEEDS, MAP_REQUIREMENTS, SEARCH_CRITERIA } from '../config/survey-enum-options';

/** Step 5 — Nhu cầu quản lý. */
@Component({
  selector: 'app-survey-step5-requirements',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, MatFormFieldModule, MatInputModule, MatSelectModule],
  template: `
    <div class="step-form" [formGroup]="form">
      <div class="step-form__grid">
        <mat-form-field appearance="outline" class="full">
          <mat-label>Nhu cầu thông tin cần quản lý (chọn nhiều)</mat-label>
          <mat-select formControlName="info_needs" multiple>
            @for (o of infoNeeds; track o.code) {
              <mat-option [value]="o.code">{{ o.label }}</mat-option>
            }
          </mat-select>
        </mat-form-field>

        <mat-form-field appearance="outline">
          <mat-label>Tiêu chí tìm kiếm (chọn nhiều)</mat-label>
          <mat-select formControlName="search_criteria" multiple>
            @for (o of searchCriteria; track o.code) {
              <mat-option [value]="o.code">{{ o.label }}</mat-option>
            }
          </mat-select>
        </mat-form-field>

        <mat-form-field appearance="outline">
          <mat-label>Yêu cầu bản đồ (chọn nhiều)</mat-label>
          <mat-select formControlName="map_requirements" multiple>
            @for (o of mapRequirements; track o.code) {
              <mat-option [value]="o.code">{{ o.label }}</mat-option>
            }
          </mat-select>
        </mat-form-field>

        <mat-form-field appearance="outline" class="full">
          <mat-label>Quy trình cần số hoá</mat-label>
          <textarea matInput rows="2" formControlName="digitize_processes"></textarea>
        </mat-form-field>
        <mat-form-field appearance="outline" class="full">
          <mat-label>Báo cáo cần triển khai</mat-label>
          <textarea matInput rows="2" formControlName="required_reports"></textarea>
        </mat-form-field>
        <mat-form-field appearance="outline" class="full">
          <mat-label>Tra cứu cần triển khai</mat-label>
          <textarea matInput rows="2" formControlName="required_lookups"></textarea>
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
export class SurveyStep5RequirementsComponent {
  @Input({ required: true }) form!: FormGroup;
  readonly infoNeeds = INFO_NEEDS;
  readonly searchCriteria = SEARCH_CRITERIA;
  readonly mapRequirements = MAP_REQUIREMENTS;
}
