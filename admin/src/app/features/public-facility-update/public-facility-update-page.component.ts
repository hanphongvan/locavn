import { CommonModule } from '@angular/common';
import { Component, OnInit, inject, signal } from '@angular/core';
import { FormArray, FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';
import { MatDialog, MatDialogModule } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatSelectModule } from '@angular/material/select';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { MatTabsModule } from '@angular/material/tabs';
import { ActivatedRoute, RouterLink } from '@angular/router';

import { API_BASE_URL } from '../../core/tokens/api-base-url.token';
import { DmsLogoComponent } from '../auth/components/dms-logo.component';
import type { HttmFacilityCreateRequest, HttmFacilityDto } from '../httm/models/httm-facility.model';
import type {
  HttmPublicFacilityRow,
  HttmSubmissionImage,
  HttmSubmissionLicense,
} from '../httm/models/httm-submission.model';
import { HttmSubmissionService } from '../httm/services/httm-submission.service';
import { FacilitySearchDialogComponent } from './facility-search-dialog.component';

/**
 * Public form (không cần đăng nhập) cho chủ HTTM cập nhật / tạo mới hồ sơ.
 * Workflow: chọn facility → load snapshot → chỉnh sửa → nhập tên/sđt → submit.
 * Server lưu vào HttmFacilitySubmissions (pending), cán bộ review trước khi merge.
 */
@Component({
  selector: 'app-public-facility-update-page',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    MatButtonModule,
    MatCardModule,
    MatDialogModule,
    MatFormFieldModule,
    MatIconModule,
    MatInputModule,
    MatProgressSpinnerModule,
    MatSelectModule,
    MatSlideToggleModule,
    MatSnackBarModule,
    MatTabsModule,
    RouterLink,
    DmsLogoComponent,
  ],
  templateUrl: './public-facility-update-page.component.html',
  styleUrls: ['./public-facility-update-page.component.scss'],
})
export class PublicFacilityUpdatePageComponent implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly api = inject(HttmSubmissionService);
  private readonly dialog = inject(MatDialog);
  private readonly snack = inject(MatSnackBar);
  private readonly route = inject(ActivatedRoute);
  private readonly apiBase = inject(API_BASE_URL).replace(/\/$/, '');

  /** Khi sửa lại 1 đề xuất bị từ chối: lý do từ chối để hiển thị banner. */
  readonly rejectedReason = signal<string | null>(null);
  readonly fromRejected = signal(false);

  readonly selectedFacility = signal<HttmPublicFacilityRow | null>(null);
  readonly loadingSnapshot = signal(false);
  readonly submitting = signal(false);
  readonly submittedId = signal<string | null>(null);
  readonly mode = signal<'update' | 'create_new' | null>(null);

  /** Dropdown options (load 1 lần khi init). */
  readonly provinces = signal<{ code: string; name: string }[]>([]);
  /** Dropdown xã của tỉnh đang chọn (cascade khi provinceCode đổi). */
  readonly wards = signal<{ code: string; name: string }[]>([]);
  readonly loadingWards = signal(false);
  /** Đang upload (ngăn double-click) — tham chiếu cho tất cả slot. */
  readonly uploadingImage = signal(false);
  readonly uploadingDocument = signal(false);

  readonly form = this.fb.group({
    // Facility payload (required basics)
    name: this.fb.nonNullable.control('', { validators: [Validators.required, Validators.maxLength(500)] }),
    httmType: this.fb.nonNullable.control('', { validators: [Validators.required] }),
    status: this.fb.nonNullable.control('active', { validators: [Validators.required] }),
    provinceCode: this.fb.nonNullable.control('', { validators: [Validators.required, Validators.maxLength(10)] }),
    districtCode: this.fb.control<string | null>(null),
    wardCode: this.fb.control<string | null>(null),
    addressDetail: this.fb.control<string | null>(null),
    lat: this.fb.control<number | null>(null),
    lng: this.fb.control<number | null>(null),
    gpsAccuracy: this.fb.control<string | null>(null),
    landArea: this.fb.control<number | null>(null),
    floorArea: this.fb.control<number | null>(null),
    floors: this.fb.control<number | null>(null),
    stallCount: this.fb.control<number | null>(null),
    avgStallArea: this.fb.control<number | null>(null),
    parkingSlots: this.fb.control<number | null>(null),
    yearEstablished: this.fb.control<number | null>(null),
    yearRenovated: this.fb.control<number | null>(null),
    ownerName: this.fb.control<string | null>(null),
    operatorName: this.fb.control<string | null>(null),
    fillRate: this.fb.control<number | null>(null),
    vendorCount: this.fb.control<number | null>(null),
    avgRentPrice: this.fb.control<number | null>(null),
    annualRevenue: this.fb.control<number | null>(null),
    hasBackupPower: this.fb.control<boolean | null>(null),
    hasFireProtection: this.fb.control<boolean | null>(null),
    buildingQuality: this.fb.control<string | null>(null),
    notes: this.fb.control<string | null>(null),

    // Submitter (required)
    submitterName: this.fb.nonNullable.control('', { validators: [Validators.required, Validators.maxLength(200)] }),
    submitterPhone: this.fb.nonNullable.control('', {
      validators: [Validators.required, Validators.pattern(/^(0|\+84)\d{9,10}$/)],
    }),
    submitterEmail: this.fb.control<string | null>(null, { validators: [Validators.email] }),
    submitterNotes: this.fb.control<string | null>(null),

    // Attachments
    images: this.fb.array<FormGroup>([]),
    licenses: this.fb.array<FormGroup>([]),
  });

  get imagesArr(): FormArray { return this.form.controls.images as FormArray; }
  get licensesArr(): FormArray { return this.form.controls.licenses as FormArray; }

  ngOnInit(): void {
    // Load 63 tỉnh 1 lần khi vào trang
    this.api.listPublicProvinces().subscribe({
      next: (list) => this.provinces.set(list.map((p) => ({ code: p.code, name: p.name }))),
      error: () => this.snack.open('Không tải được danh sách tỉnh.', 'Đóng'),
    });

    // Cascade: khi đổi tỉnh → load xã + reset wardCode
    this.form.controls.provinceCode.valueChanges.subscribe((code) => {
      this.form.patchValue({ wardCode: null }, { emitEvent: false });
      if (!code) {
        this.wards.set([]);
        return;
      }
      this.loadingWards.set(true);
      this.api.listPublicWardsByProvince(code).subscribe({
        next: (list) => this.wards.set(list.map((w) => ({ code: w.code, name: w.name }))),
        error: () => {
          this.wards.set([]);
          this.snack.open(`Không tải được danh sách xã của tỉnh ${code}.`, 'Đóng');
        },
        complete: () => this.loadingWards.set(false),
      });
    });

    // Mở từ trang "Đề xuất bị từ chối": pre-fill dữ liệu hồ sơ (KHÔNG load thông tin người gửi).
    const qp = this.route.snapshot.queryParamMap;
    const fromRejected = qp.get('fromRejected');
    const phone = qp.get('phone');
    if (fromRejected && phone) {
      this.loadFromRejected(fromRejected, phone);
    }
  }

  /** Tải đề xuất bị từ chối (xác thực bằng SĐT) và đổ vào form để sửa lại. */
  private loadFromRejected(id: string, phone: string): void {
    this.fromRejected.set(true);
    this.loadingSnapshot.set(true);
    this.api.getPublicRejectedDetail(id, phone).subscribe({
      next: (d) => {
        const p = d.proposed;
        this.mode.set(d.submissionType);
        // Với đề xuất cập nhật: giữ lại facilityId để submit gửi đúng facility gốc.
        this.selectedFacility.set(
          d.submissionType === 'update' && d.facilityId
            ? {
                id: d.facilityId,
                name: p.name,
                httmType: p.httmType,
                status: p.status,
                provinceCode: p.provinceCode,
                districtCode: p.districtCode ?? null,
                wardCode: p.wardCode ?? null,
                addressDetail: p.addressDetail ?? null,
              }
            : null,
        );
        this.applyProposed(p);
        this.applyAttachments(d.proposedImages, d.proposedLicenses);
        this.rejectedReason.set(d.reviewNotes ?? null);
      },
      error: () =>
        this.snack.open('Không tải được đề xuất bị từ chối (SĐT không khớp hoặc đề xuất không tồn tại).', 'Đóng', {
          duration: 8000,
        }),
      complete: () => this.loadingSnapshot.set(false),
    });
  }

  openSearch(): void {
    const ref = this.dialog.open(FacilitySearchDialogComponent, {
      width: '80vw',
      maxWidth: '80vw',
      maxHeight: '90vh',
      panelClass: 'public-portal-dialog',
    });
    ref.afterClosed().subscribe((row: HttmPublicFacilityRow | null) => {
      if (row) {
        this.loadFacility(row);
      }
    });
  }

  loadFacility(row: HttmPublicFacilityRow): void {
    this.selectedFacility.set(row);
    this.mode.set('update');
    this.loadingSnapshot.set(true);
    this.api.getPublicSnapshot(row.id).subscribe({
      next: (dto) => this.applySnapshot(dto),
      error: () => this.snack.open('Không tải được dữ liệu hạ tầng.', 'Đóng'),
      complete: () => this.loadingSnapshot.set(false),
    });
  }

  startCreateNew(): void {
    this.selectedFacility.set(null);
    this.mode.set('create_new');
    this.form.reset();
    this.form.patchValue({ status: 'active' });
  }

  private applySnapshot(d: HttmFacilityDto): void {
    // Cascade: provinceCode đổi → wards load async. Set wardCode SAU khi wards load xong
    // để mat-select hiển thị đúng option đã pre-fill.
    const savedWardCode = d.wardCode;
    this.form.patchValue({
      name: d.name,
      httmType: d.httmType,
      status: d.status,
      provinceCode: d.provinceCode,
      districtCode: d.districtCode,
      wardCode: null, // patch sau khi load xong wards
      addressDetail: d.addressDetail,
      lat: d.lat,
      lng: d.lng,
      gpsAccuracy: d.gpsAccuracy,
      landArea: d.landArea,
      floorArea: d.floorArea,
      floors: d.floors,
      stallCount: d.stallCount,
      avgStallArea: d.avgStallArea,
      parkingSlots: d.parkingSlots,
      yearEstablished: d.yearEstablished,
      yearRenovated: d.yearRenovated,
      ownerName: d.ownerName,
      operatorName: d.operatorName,
      fillRate: d.fillRate,
      vendorCount: d.vendorCount,
      avgRentPrice: d.avgRentPrice,
      annualRevenue: d.annualRevenue,
      hasBackupPower: d.hasBackupPower,
      hasFireProtection: d.hasFireProtection,
      buildingQuality: d.buildingQuality,
      notes: d.notes,
    });

    // valueChanges đã trigger cascade load wards từ patchValue provinceCode ở trên.
    this.patchWardAfterLoad(savedWardCode, d.provinceCode);
  }

  /** Đổ dữ liệu hồ sơ từ 1 đề xuất bị từ chối (HttmFacilityCreateRequest) vào form. */
  private applyProposed(p: HttmFacilityCreateRequest): void {
    const savedWardCode = p.wardCode ?? null;
    this.form.patchValue({
      name: p.name,
      httmType: p.httmType,
      status: p.status,
      provinceCode: p.provinceCode,
      districtCode: p.districtCode,
      wardCode: null, // patch sau khi load xong wards
      addressDetail: p.addressDetail,
      lat: p.lat,
      lng: p.lng,
      gpsAccuracy: p.gpsAccuracy,
      landArea: p.landArea,
      floorArea: p.floorArea,
      floors: p.floors,
      stallCount: p.stallCount,
      avgStallArea: p.avgStallArea,
      parkingSlots: p.parkingSlots,
      yearEstablished: p.yearEstablished,
      yearRenovated: p.yearRenovated,
      ownerName: p.ownerName,
      operatorName: p.operatorName,
      fillRate: p.fillRate,
      vendorCount: p.vendorCount,
      avgRentPrice: p.avgRentPrice,
      annualRevenue: p.annualRevenue,
      hasBackupPower: p.hasBackupPower,
      hasFireProtection: p.hasFireProtection,
      buildingQuality: p.buildingQuality,
      notes: p.notes,
    });
    this.patchWardAfterLoad(savedWardCode, p.provinceCode);
  }

  /** Đổ lại ảnh + giấy phép đã đính kèm của đề xuất bị từ chối vào các FormArray. */
  private applyAttachments(
    images: HttmSubmissionImage[],
    licenses: HttmSubmissionLicense[],
  ): void {
    this.imagesArr.clear();
    images.forEach((img, idx) => {
      this.imagesArr.push(this.fb.group({
        url: [img.url],
        fileName: [this.fileNameFromUrl(img.url)],
        imageType: [img.imageType ?? 'exterior'],
        caption: [img.caption ?? ''],
        takenDate: [img.takenDate ?? null],
        sortOrder: [typeof img.sortOrder === 'number' ? img.sortOrder : idx],
      }));
    });

    this.licensesArr.clear();
    licenses.forEach((lic) => {
      this.licensesArr.push(this.fb.group({
        licenseType: [lic.licenseType ?? 'business'],
        licenseNumber: [lic.licenseNumber ?? ''],
        issuedDate: [lic.issuedDate ?? null],
        expiryDate: [lic.expiryDate ?? null],
        issuedBy: [lic.issuedBy ?? ''],
        fileUrl: [lic.fileUrl ?? ''],
        fileName: [this.fileNameFromUrl(lic.fileUrl)],
        notes: [lic.notes ?? ''],
      }));
    });
  }

  private fileNameFromUrl(url: string | null | undefined): string {
    if (!url) return '';
    const parts = url.split('/');
    return parts[parts.length - 1] || '';
  }

  /**
   * Sau khi đổi provinceCode, wards load async → đợi load xong rồi set wardCode để mat-select
   * hiển thị đúng option đã pre-fill.
   */
  private patchWardAfterLoad(savedWardCode: string | null | undefined, provinceCode: string | null | undefined): void {
    if (!savedWardCode || !provinceCode) return;
    const start = Date.now();
    const poll = setInterval(() => {
      if (this.wards().some((w) => w.code === savedWardCode)) {
        this.form.patchValue({ wardCode: savedWardCode }, { emitEvent: false });
        clearInterval(poll);
      } else if (Date.now() - start > 5000 || (!this.loadingWards() && this.wards().length > 0)) {
        // Quá 5s hoặc wards đã load nhưng không match → bỏ wardCode.
        clearInterval(poll);
      }
    }, 100);
  }

  submit(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      this.snack.open('Kiểm tra lại các ô bắt buộc (tên, số điện thoại, loại hình, tỉnh).', 'Đóng');
      return;
    }
    const v = this.form.getRawValue();
    // Lat/Lng: coi 0 (hoặc null) là "chưa nhập". Chỉ gửi khi CẢ HAI hợp lệ để
    // thỏa ràng buộc backend "Lat và Lng phải cùng có hoặc cùng không".
    const hasCoords = !!v.lat && !!v.lng;
    const lat = hasCoords ? v.lat! : undefined;
    const lng = hasCoords ? v.lng! : undefined;
    const payload: HttmFacilityCreateRequest = {
      name: v.name,
      httmType: v.httmType,
      status: v.status,
      provinceCode: v.provinceCode,
      districtCode: v.districtCode ?? undefined,
      wardCode: v.wardCode ?? undefined,
      addressDetail: v.addressDetail ?? undefined,
      lat,
      lng,
      gpsAccuracy: v.gpsAccuracy ?? undefined,
      landArea: v.landArea ?? undefined,
      floorArea: v.floorArea ?? undefined,
      floors: v.floors ?? undefined,
      stallCount: v.stallCount ?? undefined,
      avgStallArea: v.avgStallArea ?? undefined,
      parkingSlots: v.parkingSlots ?? undefined,
      yearEstablished: v.yearEstablished ?? undefined,
      yearRenovated: v.yearRenovated ?? undefined,
      ownerName: v.ownerName ?? undefined,
      operatorName: v.operatorName ?? undefined,
      fillRate: v.fillRate ?? undefined,
      vendorCount: v.vendorCount ?? undefined,
      avgRentPrice: v.avgRentPrice ?? undefined,
      annualRevenue: v.annualRevenue ?? undefined,
      hasBackupPower: v.hasBackupPower ?? undefined,
      hasFireProtection: v.hasFireProtection ?? undefined,
      buildingQuality: v.buildingQuality ?? undefined,
      notes: v.notes ?? undefined,
    };

    // Build images + licenses arrays
    const images: HttmSubmissionImage[] = (v.images as Array<{
      url: string; imageType: string; caption?: string | null; takenDate?: string | null; sortOrder?: number;
    }>).filter((img) => !!img.url).map((img, idx) => ({
      url: img.url,
      imageType: (img.imageType ?? 'other') as HttmSubmissionImage['imageType'],
      caption: img.caption || null,
      takenDate: img.takenDate || null,
      sortOrder: typeof img.sortOrder === 'number' ? img.sortOrder : idx,
    }));

    const licenses: HttmSubmissionLicense[] = (v.licenses as Array<{
      licenseType: string; licenseNumber?: string | null; issuedDate?: string | null;
      expiryDate?: string | null; issuedBy?: string | null; fileUrl?: string | null; notes?: string | null;
    }>).filter((lic) => !!lic.licenseType).map((lic) => ({
      licenseType: lic.licenseType as HttmSubmissionLicense['licenseType'],
      licenseNumber: lic.licenseNumber || null,
      issuedDate: lic.issuedDate || null,
      expiryDate: lic.expiryDate || null,
      issuedBy: lic.issuedBy || null,
      fileUrl: lic.fileUrl || null,
      notes: lic.notes || null,
    }));

    this.submitting.set(true);
    this.api
      .submit({
        facilityId: this.selectedFacility()?.id ?? null,
        payload,
        images,
        licenses,
        submitter: {
          name: v.submitterName,
          phone: v.submitterPhone,
          email: v.submitterEmail || null,
          notes: v.submitterNotes || null,
        },
      })
      .subscribe({
        next: (r) => {
          this.submittedId.set(r.submissionId);
          this.snack.open(
            `Đã gửi đề xuất. Mã theo dõi: ${r.submissionId.substring(0, 8).toUpperCase()}. Cán bộ sẽ xem xét trong 1-2 ngày.`,
            'OK',
            { duration: 10000 },
          );
        },
        error: (e) =>
          this.snack.open(`Gửi thất bại: ${e?.error?.detail ?? e?.message ?? 'lỗi'}`, 'Đóng', { duration: 8000 }),
        complete: () => this.submitting.set(false),
      });
  }

  resetForm(): void {
    this.submittedId.set(null);
    this.selectedFacility.set(null);
    this.mode.set(null);
    this.form.reset();
    this.form.patchValue({ status: 'active' });
    this.imagesArr.clear();
    this.licensesArr.clear();
  }

  /** User chọn ảnh từ <input type="file"> → upload + push row vào imagesArr. */
  onPickImage(ev: Event): void {
    const input = ev.target as HTMLInputElement | null;
    const file = input?.files?.[0];
    if (!file) return;
    if (input) input.value = ''; // reset để chọn lại cùng file vẫn fire change
    this.uploadingImage.set(true);
    this.api.uploadImage(file).subscribe({
      next: (r) => {
        this.imagesArr.push(this.fb.group({
          url: [r.url],
          fileName: [r.fileName],
          imageType: ['exterior'],
          caption: [''],
          takenDate: [null as string | null],
          sortOrder: [this.imagesArr.length],
        }));
        this.snack.open(`Đã tải ảnh: ${r.fileName} (${Math.round(r.sizeBytes / 1024)} KB)`, 'OK', { duration: 3000 });
      },
      error: (e) =>
        this.snack.open(`Tải ảnh thất bại: ${e?.error?.detail ?? e?.message ?? 'lỗi'}`, 'Đóng', { duration: 6000 }),
      complete: () => this.uploadingImage.set(false),
    });
  }

  removeImage(i: number): void {
    this.imagesArr.removeAt(i);
  }

  /** User chọn file giấy tờ → upload + push row vào licensesArr (chưa có licenseType, để user chọn). */
  onPickDocument(ev: Event): void {
    const input = ev.target as HTMLInputElement | null;
    const file = input?.files?.[0];
    if (!file) return;
    if (input) input.value = '';
    this.uploadingDocument.set(true);
    this.api.uploadDocument(file).subscribe({
      next: (r) => {
        this.licensesArr.push(this.fb.group({
          licenseType: ['business'],
          licenseNumber: [''],
          issuedDate: [null as string | null],
          expiryDate: [null as string | null],
          issuedBy: [''],
          fileUrl: [r.url],
          fileName: [r.fileName],
          notes: [''],
        }));
        this.snack.open(`Đã tải giấy tờ: ${r.fileName} (${Math.round(r.sizeBytes / 1024)} KB)`, 'OK', { duration: 3000 });
      },
      error: (e) =>
        this.snack.open(`Tải tệp thất bại: ${e?.error?.detail ?? e?.message ?? 'lỗi'}`, 'Đóng', { duration: 6000 }),
      complete: () => this.uploadingDocument.set(false),
    });
  }

  /** Thêm license card RỖNG (user upload file sau, hoặc không có file đính kèm). */
  addEmptyLicense(): void {
    this.licensesArr.push(this.fb.group({
      licenseType: ['business'],
      licenseNumber: [''],
      issuedDate: [null as string | null],
      expiryDate: [null as string | null],
      issuedBy: [''],
      fileUrl: [''],
      fileName: [''],
      notes: [''],
    }));
  }

  removeLicense(i: number): void {
    this.licensesArr.removeAt(i);
  }

  imageUrl(i: number): string {
    const url = this.imagesArr.at(i)?.get('url')?.value as string | undefined;
    return url ? `${this.apiBase}${url}` : '';
  }

  documentUrl(url: string | null | undefined): string {
    return url ? `${this.apiBase}${url}` : '';
  }
}
