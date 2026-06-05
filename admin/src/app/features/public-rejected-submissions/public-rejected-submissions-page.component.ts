import { CommonModule } from '@angular/common';
import { Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { MatTableModule } from '@angular/material/table';
import { Router, RouterLink } from '@angular/router';

import { ApiRequestError } from '../../core/http/api-request-error';
import { DmsLogoComponent } from '../auth/components/dms-logo.component';
import type { HttmPublicRejectedSubmission } from '../httm/models/httm-submission.model';
import { HttmSubmissionService } from '../httm/services/httm-submission.service';

/**
 * Trang public (không đăng nhập): tra cứu các đề xuất hạ tầng BỊ TỪ CHỐI theo SĐT người gửi,
 * và mở lại form để sửa rồi gửi lại. Chỉ hiển thị đề xuất bị từ chối của đúng SĐT đã nhập.
 */
@Component({
  selector: 'app-public-rejected-submissions-page',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    RouterLink,
    MatButtonModule,
    MatFormFieldModule,
    MatIconModule,
    MatInputModule,
    MatProgressSpinnerModule,
    MatSnackBarModule,
    MatTableModule,
    DmsLogoComponent,
  ],
  templateUrl: './public-rejected-submissions-page.component.html',
  styleUrls: ['./public-rejected-submissions-page.component.scss'],
})
export class PublicRejectedSubmissionsPageComponent {
  private readonly api = inject(HttmSubmissionService);
  private readonly router = inject(Router);
  private readonly snack = inject(MatSnackBar);

  readonly phone = signal('');
  readonly loading = signal(false);
  readonly searched = signal(false);
  readonly items = signal<HttmPublicRejectedSubmission[]>([]);

  readonly columns = ['submittedAt', 'type', 'name', 'province', 'reason', 'action'];

  search(): void {
    const phone = this.phone().trim();
    if (!/^(0|\+84)\d{9,10}$/.test(phone)) {
      this.snack.open('Vui lòng nhập đúng số điện thoại đã dùng khi gửi đề xuất.', 'Đóng');
      return;
    }
    if (this.loading()) return;
    this.loading.set(true);
    this.api.listPublicRejected(phone).subscribe({
      next: (rows) => {
        this.items.set(rows);
        this.searched.set(true);
      },
      error: (e) => {
        this.items.set([]);
        this.searched.set(true);
        this.snack.open(
          `Tra cứu thất bại: ${e instanceof ApiRequestError ? e.message : 'lỗi'}`,
          'Đóng',
          { duration: 6000 },
        );
      },
      complete: () => this.loading.set(false),
    });
  }

  /** Mở form cập nhật hạ tầng, pre-fill từ đề xuất bị từ chối (không load thông tin người gửi). */
  edit(row: HttmPublicRejectedSubmission): void {
    void this.router.navigate(['/public/facility-update'], {
      queryParams: { fromRejected: row.id, phone: this.phone().trim() },
    });
  }
}
