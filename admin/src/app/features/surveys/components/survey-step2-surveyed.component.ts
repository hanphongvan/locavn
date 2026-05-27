import { CommonModule } from '@angular/common';
import { Component, Input } from '@angular/core';
import { FormArray, FormGroup, ReactiveFormsModule } from '@angular/forms';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';

import { SurveyMembersArrayComponent } from './survey-members-array.component';

/** Step 2 — Thông tin đơn vị được khảo sát (theo S2.2: unit_name + address required). */
@Component({
  selector: 'app-survey-step2-surveyed',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, MatFormFieldModule, MatInputModule, SurveyMembersArrayComponent],
  template: `
    <div class="step-form" [formGroup]="form">
      <div class="step-form__grid">
        <mat-form-field appearance="outline" class="full">
          <mat-label>Tên đơn vị được khảo sát *</mat-label>
          <input matInput formControlName="unit_name" maxlength="500" />
          @if (form.controls['unit_name'].touched && form.controls['unit_name'].invalid) {
            <mat-error>Bắt buộc khi nộp.</mat-error>
          }
        </mat-form-field>
        <mat-form-field appearance="outline" class="full">
          <mat-label>Địa chỉ *</mat-label>
          <input matInput formControlName="address" maxlength="500" />
          @if (form.controls['address'].touched && form.controls['address'].invalid) {
            <mat-error>Bắt buộc khi nộp.</mat-error>
          }
        </mat-form-field>
        <mat-form-field appearance="outline">
          <mat-label>Mã số thuế</mat-label>
          <input matInput formControlName="tax_code" maxlength="50" />
        </mat-form-field>
        <mat-form-field appearance="outline">
          <mat-label>Cơ quan chủ quản</mat-label>
          <input matInput formControlName="parent_org" maxlength="500" />
        </mat-form-field>
      </div>
      <h4 class="step-form__sub">Đại diện đơn vị</h4>
      <app-survey-members-array [arr]="membersArr" arrName="members" mode="contact" [parentDummy]="form" [disabled]="form.disabled" />
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
export class SurveyStep2SurveyedComponent {
  @Input({ required: true }) form!: FormGroup;
  get membersArr(): FormArray {
    return this.form.controls['members'] as FormArray;
  }
}
