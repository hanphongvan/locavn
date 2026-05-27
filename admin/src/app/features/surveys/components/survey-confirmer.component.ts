import { CommonModule } from '@angular/common';
import { Component, Input } from '@angular/core';
import { FormGroup, ReactiveFormsModule } from '@angular/forms';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { provideNativeDateAdapter } from '@angular/material/core';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';

/** Bước xác nhận — name + confirmed_date bắt buộc khi nộp. */
@Component({
  selector: 'app-survey-confirmer',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, MatDatepickerModule, MatFormFieldModule, MatInputModule],
  providers: [provideNativeDateAdapter()],
  template: `
    <div class="step-form" [formGroup]="form">
      <div class="step-form__grid">
        <mat-form-field appearance="outline">
          <mat-label>Người xác nhận *</mat-label>
          <input matInput formControlName="name" maxlength="200" />
          @if (form.controls['name'].touched && form.controls['name'].invalid) {
            <mat-error>Bắt buộc khi nộp.</mat-error>
          }
        </mat-form-field>
        <mat-form-field appearance="outline">
          <mat-label>Chức vụ</mat-label>
          <input matInput formControlName="title" maxlength="200" />
        </mat-form-field>

        <mat-form-field appearance="outline">
          <mat-label>Người duyệt</mat-label>
          <input matInput formControlName="reviewer_name" maxlength="200" />
        </mat-form-field>
        <mat-form-field appearance="outline">
          <mat-label>Chức vụ người duyệt</mat-label>
          <input matInput formControlName="reviewer_title" maxlength="200" />
        </mat-form-field>

        <mat-form-field appearance="outline" class="full">
          <mat-label>Ngày xác nhận *</mat-label>
          <input matInput [matDatepicker]="picker" formControlName="confirmed_date" />
          <mat-datepicker-toggle matIconSuffix [for]="picker"></mat-datepicker-toggle>
          <mat-datepicker #picker></mat-datepicker>
          @if (form.controls['confirmed_date'].touched && form.controls['confirmed_date'].invalid) {
            <mat-error>Bắt buộc khi nộp.</mat-error>
          }
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
export class SurveyConfirmerComponent {
  @Input({ required: true }) form!: FormGroup;
}
