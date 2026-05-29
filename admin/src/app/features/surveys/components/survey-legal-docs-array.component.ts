import { CommonModule } from '@angular/common';
import { Component, Input } from '@angular/core';
import { FormArray, FormBuilder, FormGroup, ReactiveFormsModule } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';

@Component({
  selector: 'app-survey-legal-docs-array',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, MatButtonModule, MatFormFieldModule, MatIconModule, MatInputModule],
  template: `
    <div class="legal-docs" [formGroup]="parentDummy">
      <ng-container [formArrayName]="arrName">
        @for (g of arr.controls; track $index) {
          <div class="legal-docs__row" [formGroupName]="$index">
            <mat-form-field appearance="outline" class="idx">
              <mat-label>Số / Mã</mat-label>
              <input matInput formControlName="index" />
            </mat-form-field>
            <mat-form-field appearance="outline" class="grow">
              <mat-label>Nội dung văn bản</mat-label>
              <input matInput formControlName="content" />
            </mat-form-field>
            <button mat-icon-button type="button" (click)="remove($index)" [disabled]="disabled" aria-label="Xóa">
              <mat-icon>delete</mat-icon>
            </button>
          </div>
        }
        @if (arr.length === 0) {
          <p class="muted">Chưa có văn bản pháp lý nào.</p>
        }
      </ng-container>
      <button mat-stroked-button type="button" (click)="add()" [disabled]="disabled">
        <mat-icon>add</mat-icon> Thêm văn bản
      </button>
    </div>
  `,
  styles: [
    `
      .legal-docs { display: flex; flex-direction: column; gap: 8px; }
      .legal-docs__row {
        display: flex;
        gap: 8px;
        align-items: flex-start;
        .idx { flex: 0 0 140px; }
        .grow { flex: 1 1 320px; }
      }
      .muted { color: #607d8b; font-style: italic; }
    `,
  ],
})
export class SurveyLegalDocsArrayComponent {
  @Input({ required: true }) arr!: FormArray;
  @Input({ required: true }) arrName!: string;
  @Input({ required: true }) parentDummy!: FormGroup;
  @Input() disabled = false;

  constructor(private readonly fb: FormBuilder) {}

  add(): void {
    this.arr.push(this.fb.group({ index: [''], content: [''] }));
    this.arr.markAsDirty();
  }

  remove(i: number): void {
    this.arr.removeAt(i);
    this.arr.markAsDirty();
  }
}
