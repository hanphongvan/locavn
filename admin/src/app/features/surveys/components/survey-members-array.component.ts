import { CommonModule } from '@angular/common';
import { Component, Input } from '@angular/core';
import { FormArray, FormBuilder, FormGroup, ReactiveFormsModule } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';

/**
 * FormArray reusable cho danh sách thành viên / cán bộ phụ trách.
 * Mode "compact" (3 cột: name, title, role) dùng cho Step 1 (đoàn KS) + Step 3 (responsible_staff).
 * Mode "contact" (4 cột: name, title, phone, email) dùng cho Step 2 (đại diện đơn vị KS).
 *
 * Parent truyền FormArray qua `[arr]`. Component thêm/xóa controls qua FormBuilder.
 */
@Component({
  selector: 'app-survey-members-array',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, MatButtonModule, MatFormFieldModule, MatIconModule, MatInputModule],
  template: `
    <div class="members-array" [formGroup]="parentDummy">
      <ng-container [formArrayName]="arrName">
        @for (g of arr.controls; track $index) {
          <div class="members-array__row" [formGroupName]="$index">
            <mat-form-field appearance="outline" class="grow">
              <mat-label>Họ tên</mat-label>
              <input matInput formControlName="name" />
            </mat-form-field>
            <mat-form-field appearance="outline" class="grow">
              <mat-label>Chức vụ</mat-label>
              <input matInput formControlName="title" />
            </mat-form-field>
            @if (mode === 'compact') {
              <mat-form-field appearance="outline" class="grow">
                <mat-label>Vai trò</mat-label>
                <input matInput formControlName="role" />
              </mat-form-field>
            }
            @if (mode === 'contact') {
              <mat-form-field appearance="outline">
                <mat-label>SĐT</mat-label>
                <input matInput formControlName="phone" />
              </mat-form-field>
              <mat-form-field appearance="outline">
                <mat-label>Email</mat-label>
                <input matInput formControlName="email" />
              </mat-form-field>
            }
            <button mat-icon-button type="button" (click)="remove($index)" [disabled]="disabled" aria-label="Xóa">
              <mat-icon>delete</mat-icon>
            </button>
          </div>
        }
        @if (arr.length === 0) {
          <p class="muted">Chưa có thành viên nào.</p>
        }
      </ng-container>
      <button mat-stroked-button type="button" (click)="add()" [disabled]="disabled">
        <mat-icon>add</mat-icon> Thêm thành viên
      </button>
    </div>
  `,
  styles: [
    `
      .members-array {
        display: flex;
        flex-direction: column;
        gap: 8px;
      }
      .members-array__row {
        display: flex;
        gap: 8px;
        align-items: flex-start;
        flex-wrap: wrap;
        .grow {
          flex: 1 1 180px;
        }
      }
      .muted {
        color: #607d8b;
        font-style: italic;
      }
    `,
  ],
})
export class SurveyMembersArrayComponent {
  @Input({ required: true }) arr!: FormArray;
  @Input({ required: true }) arrName!: string;
  @Input() mode: 'compact' | 'contact' = 'compact';
  @Input() disabled = false;
  /** Wrapper FormGroup chứa FormArray — required vì template dùng `[formGroup]`. Parent truyền. */
  @Input({ required: true }) parentDummy!: FormGroup;

  constructor(private readonly fb: FormBuilder) {}

  add(): void {
    const group =
      this.mode === 'contact'
        ? this.fb.group({ name: [''], title: [''], phone: [''], email: [''] })
        : this.fb.group({ name: [''], title: [''], role: [''] });
    this.arr.push(group);
    this.arr.markAsDirty();
  }

  remove(i: number): void {
    this.arr.removeAt(i);
    this.arr.markAsDirty();
  }
}
