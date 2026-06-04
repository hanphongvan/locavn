import { CommonModule } from '@angular/common';
import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';

import { ApiRequestError } from '../../../core/http/api-request-error';
import { API_BASE_URL } from '../../../core/tokens/api-base-url.token';
import type { HttmFacilityCreateRequest, HttmFacilityDto } from '../models/httm-facility.model';
import type { HttmSubmissionDetail } from '../models/httm-submission.model';
import { HttmSubmissionService } from '../services/httm-submission.service';

interface DiffField {
  label: string;
  key: keyof HttmFacilityCreateRequest;
  currentValue: string | null;
  proposedValue: string | null;
  changed: boolean;
}

@Component({
  selector: 'app-httm-submission-detail-page',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    RouterLink,
    MatButtonModule,
    MatCardModule,
    MatFormFieldModule,
    MatIconModule,
    MatInputModule,
    MatSnackBarModule,
  ],
  templateUrl: './httm-submission-detail-page.component.html',
  styleUrls: ['./httm-submission-detail-page.component.scss'],
})
export class HttmSubmissionDetailPageComponent implements OnInit {
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly api = inject(HttmSubmissionService);
  private readonly snack = inject(MatSnackBar);
  private readonly apiBase = inject(API_BASE_URL).replace(/\/$/, '');

  /** Build absolute URL từ relative /uploads/... cho preview + link tải. */
  absoluteUrl(rel: string | null | undefined): string {
    return rel ? `${this.apiBase}${rel}` : '';
  }

  /** Map mã loại ảnh → tên tiếng Việt cho UI. */
  imageTypeLabel(code: string | null | undefined): string {
    return code === 'exterior' ? 'Mặt ngoài'
      : code === 'interior' ? 'Bên trong'
      : code === 'infrastructure' ? 'Hạ tầng kỹ thuật'
      : 'Khác';
  }

  /** Map mã loại giấy phép → tên tiếng Việt. */
  licenseTypeLabel(code: string | null | undefined): string {
    return code === 'business' ? 'Giấy phép kinh doanh'
      : code === 'fire_protection' ? 'Giấy chứng nhận PCCC'
      : code === 'food_safety' ? 'Giấy chứng nhận ATVSTP'
      : 'Khác';
  }

  readonly loading = signal(true);
  readonly detail = signal<HttmSubmissionDetail | null>(null);
  readonly working = signal(false);
  readonly exporting = signal(false);
  readonly approveNotes = signal('');
  readonly rejectReason = signal('');

  readonly diffFields = computed<DiffField[]>(() => {
    const d = this.detail();
    if (!d) return [];
    return this.buildDiff(d.proposed, d.current);
  });

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id');
    if (!id) {
      void this.router.navigate(['/httm/submissions']);
      return;
    }
    this.load(id);
  }

  load(id: string): void {
    this.loading.set(true);
    this.api.getAdminDetail(id).subscribe({
      next: (d) => this.detail.set(d),
      error: () => {
        this.snack.open('Không tải được chi tiết.', 'Đóng');
        void this.router.navigate(['/httm/submissions']);
      },
      complete: () => this.loading.set(false),
    });
  }

  approve(): void {
    const d = this.detail();
    if (!d || this.working()) return;
    if (d.status !== 'pending') return;
    this.working.set(true);
    this.api.approve(d.id, { notes: this.approveNotes() || null }).subscribe({
      next: (r) => {
        this.snack.open(`Đã duyệt — facility Id: ${r.mergedFacilityId}`, 'OK', { duration: 6000 });
        this.load(d.id);
      },
      error: (e) => {
        this.working.set(false);
        this.snack.open(
          `Approve thất bại: ${e instanceof ApiRequestError ? e.message : 'lỗi'}`,
          'Đóng',
          { duration: 8000 },
        );
      },
      complete: () => this.working.set(false),
    });
  }

  reject(): void {
    const d = this.detail();
    if (!d || this.working()) return;
    if (d.status !== 'pending') return;
    if (!this.rejectReason().trim()) {
      this.snack.open('Lý do từ chối bắt buộc.', 'OK');
      return;
    }
    this.working.set(true);
    this.api.reject(d.id, { reason: this.rejectReason().trim() }).subscribe({
      next: () => {
        this.snack.open('Đã từ chối đề xuất.', 'OK');
        this.load(d.id);
      },
      error: (e) => {
        this.working.set(false);
        this.snack.open(
          `Reject thất bại: ${e instanceof ApiRequestError ? e.message : 'lỗi'}`,
          'Đóng',
          { duration: 8000 },
        );
      },
      complete: () => this.working.set(false),
    });
  }

  /** Xuất chi tiết đề xuất hiện tại ra Excel. */
  exportExcel(): void {
    const d = this.detail();
    if (!d || this.exporting()) return;
    this.exporting.set(true);
    this.api.exportDetailExcel(d.id).subscribe({
      next: (resp) => {
        const blob = resp.body;
        if (!blob) {
          this.snack.open('Không nhận được file.', 'OK');
          return;
        }
        const cd = resp.headers.get('Content-Disposition') ?? '';
        const m = /filename\*?=(?:UTF-8'')?"?([^;\s"]+)"?/i.exec(cd);
        const filename = m ? decodeURIComponent(m[1]) : 'de-xuat-httm-chi-tiet.xlsx';
        this.saveBlob(blob, filename);
      },
      error: () => this.snack.open('Xuất Excel thất bại.', 'Đóng'),
      complete: () => this.exporting.set(false),
    });
  }

  private saveBlob(blob: Blob, filename: string): void {
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  }

  private buildDiff(proposed: HttmFacilityCreateRequest, current: HttmFacilityDto | null): DiffField[] {
    const pairs: { label: string; key: keyof HttmFacilityCreateRequest }[] = [
      { label: 'Tên cơ sở', key: 'name' },
      { label: 'Loại hình', key: 'httmType' },
      { label: 'Trạng thái', key: 'status' },
      { label: 'Mã tỉnh', key: 'provinceCode' },
      { label: 'Mã xã', key: 'wardCode' },
      { label: 'Địa chỉ chi tiết', key: 'addressDetail' },
      { label: 'Vĩ độ', key: 'lat' },
      { label: 'Kinh độ', key: 'lng' },
      { label: 'Độ chính xác GPS', key: 'gpsAccuracy' },
      { label: 'Diện tích đất', key: 'landArea' },
      { label: 'Diện tích sàn', key: 'floorArea' },
      { label: 'Số tầng', key: 'floors' },
      { label: 'Số gian hàng', key: 'stallCount' },
      { label: 'Năm đưa vào HĐ', key: 'yearEstablished' },
      { label: 'Năm cải tạo', key: 'yearRenovated' },
      { label: 'Chủ đầu tư', key: 'ownerName' },
      { label: 'Đơn vị quản lý', key: 'operatorName' },
      { label: 'Tỷ lệ lấp đầy', key: 'fillRate' },
      { label: 'Số tiểu thương', key: 'vendorCount' },
      { label: 'Giá thuê TB', key: 'avgRentPrice' },
      { label: 'Doanh thu năm', key: 'annualRevenue' },
      { label: 'Có điện DP', key: 'hasBackupPower' },
      { label: 'Có PCCC', key: 'hasFireProtection' },
      { label: 'Chất lượng', key: 'buildingQuality' },
      { label: 'Ghi chú', key: 'notes' },
    ];
    return pairs.map((p) => {
      const cur = current ? this.toStr((current as unknown as Record<string, unknown>)[p.key as string]) : null;
      const prop = this.toStr((proposed as unknown as Record<string, unknown>)[p.key as string]);
      return { label: p.label, key: p.key, currentValue: cur, proposedValue: prop, changed: cur !== prop };
    });
  }

  private toStr(v: unknown): string | null {
    if (v === null || v === undefined || v === '') return null;
    if (typeof v === 'boolean') return v ? 'Có' : 'Không';
    return String(v);
  }
}
