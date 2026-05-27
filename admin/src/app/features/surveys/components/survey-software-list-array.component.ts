import { CommonModule } from '@angular/common';
import { Component, Input } from '@angular/core';
import { FormArray, FormBuilder, FormGroup, ReactiveFormsModule } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';

@Component({
  selector: 'app-survey-software-list-array',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, MatButtonModule, MatFormFieldModule, MatIconModule, MatInputModule],
  template: `
    <div class="sw-list" [formGroup]="parentDummy">
      <ng-container [formArrayName]="arrName">
        @for (g of arr.controls; track $index) {
          <div class="sw-list__row" [formGroupName]="$index">
            <mat-form-field appearance="outline" class="grow">
              <mat-label>Tên phần mềm</mat-label>
              <input matInput formControlName="name" />
            </mat-form-field>
            <mat-form-field appearance="outline" class="grow">
              <mat-label>Mô tả</mat-label>
              <input matInput formControlName="description" />
            </mat-form-field>
            <mat-form-field appearance="outline" class="grow">
              <mat-label>Tích hợp với</mat-label>
              <input matInput formControlName="integration" />
            </mat-form-field>
            <button mat-icon-button type="button" (click)="remove($index)" [disabled]="disabled" aria-label="Xóa">
              <mat-icon>delete</mat-icon>
            </button>
          </div>
        }
        @if (arr.length === 0) {
          <p class="muted">Chưa khai báo phần mềm nào.</p>
        }
      </ng-container>
      <button mat-stroked-button type="button" (click)="add()" [disabled]="disabled">
        <mat-icon>add</mat-icon> Thêm phần mềm
      </button>
    </div>
  `,
  styles: [
    `
      .sw-list { display: flex; flex-direction: column; gap: 8px; }
      .sw-list__row {
        display: flex;
        gap: 8px;
        align-items: flex-start;
        flex-wrap: wrap;
        .grow { flex: 1 1 200px; }
      }
      .muted { color: #607d8b; font-style: italic; }
    `,
  ],
})
export class SurveySoftwareListArrayComponent {
  @Input({ required: true }) arr!: FormArray;
  @Input({ required: true }) arrName!: string;
  @Input({ required: true }) parentDummy!: FormGroup;
  @Input() disabled = false;

  constructor(private readonly fb: FormBuilder) {}

  add(): void {
    this.arr.push(this.fb.group({ name: [''], description: [''], integration: [''] }));
    this.arr.markAsDirty();
  }

  remove(i: number): void {
    this.arr.removeAt(i);
    this.arr.markAsDirty();
  }
}
