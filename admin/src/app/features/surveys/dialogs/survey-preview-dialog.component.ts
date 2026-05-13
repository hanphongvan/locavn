import { Component, inject } from '@angular/core';
import { MAT_DIALOG_DATA, MatDialogModule } from '@angular/material/dialog';
import { MatButtonModule } from '@angular/material/button';

export interface SurveyPreviewDialogData {
  json: string;
}

@Component({
  selector: 'app-survey-preview-dialog',
  standalone: true,
  imports: [MatDialogModule, MatButtonModule],
  template: `
    <h2 matDialogTitle>Xem trước dữ liệu phiếu</h2>
    <mat-dialog-content>
      <pre class="pre">{{ data.json }}</pre>
    </mat-dialog-content>
    <mat-dialog-actions align="end">
      <button mat-flat-button mat-dialog-close>Đóng</button>
    </mat-dialog-actions>
  `,
  styles: [
    `
      .pre {
        max-height: 60vh;
        overflow: auto;
        font-size: 12px;
        background: #f7f7fb;
        padding: 12px;
        border-radius: 8px;
      }
    `,
  ],
})
export class SurveyPreviewDialogComponent {
  readonly data = inject<SurveyPreviewDialogData>(MAT_DIALOG_DATA);
}
