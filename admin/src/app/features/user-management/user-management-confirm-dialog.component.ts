import { Component, inject } from '@angular/core';
import { MAT_DIALOG_DATA, MatDialogModule, MatDialogRef } from '@angular/material/dialog';
import { MatButtonModule } from '@angular/material/button';

export interface UserManagementConfirmData {
  title: string;
  message: string;
}

@Component({
  selector: 'app-user-management-confirm-dialog',
  standalone: true,
  imports: [MatDialogModule, MatButtonModule],
  template: `
    <h2 mat-dialog-title>{{ data.title }}</h2>
    <mat-dialog-content>{{ data.message }}</mat-dialog-content>
    <mat-dialog-actions align="end">
      <button mat-button type="button" (click)="ref.close(false)">Hủy</button>
      <button mat-flat-button color="primary" type="button" (click)="ref.close(true)">Xác nhận</button>
    </mat-dialog-actions>
  `,
})
export class UserManagementConfirmDialogComponent {
  readonly ref = inject(MatDialogRef<UserManagementConfirmDialogComponent, boolean>);
  readonly data = inject<UserManagementConfirmData>(MAT_DIALOG_DATA);
}
