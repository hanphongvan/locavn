import { CommonModule } from '@angular/common';
import { Component, Input } from '@angular/core';
import { FormGroup, ReactiveFormsModule } from '@angular/forms';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';

/** Step 7 — Ý kiến đề xuất (3 textarea). */
@Component({
  selector: 'app-survey-step7-opinions',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, MatFormFieldModule, MatInputModule],
  template: `
    <div class="step-form" [formGroup]="form">
      <mat-form-field appearance="outline">
        <mat-label>Khó khăn, vướng mắc đang gặp</mat-label>
        <textarea matInput rows="3" formControlName="difficulties"></textarea>
      </mat-form-field>
      <mat-form-field appearance="outline">
        <mat-label>Thuận lợi đã có</mat-label>
        <textarea matInput rows="3" formControlName="advantages"></textarea>
      </mat-form-field>
      <mat-form-field appearance="outline">
        <mat-label>Đề xuất, kiến nghị</mat-label>
        <textarea matInput rows="3" formControlName="proposals"></textarea>
      </mat-form-field>
    </div>
  `,
  styles: [
    `
      .step-form { display: flex; flex-direction: column; gap: 12px; }
      .step-form mat-form-field { width: 100%; }
    `,
  ],
})
export class SurveyStep7OpinionsComponent {
  @Input({ required: true }) form!: FormGroup;
}
