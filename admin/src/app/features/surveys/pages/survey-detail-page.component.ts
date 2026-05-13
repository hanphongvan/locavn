import { CommonModule } from '@angular/common';
import { Component, computed, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { MatButtonModule } from '@angular/material/button';
import { MatDialog, MatDialogModule } from '@angular/material/dialog';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { MatTabsModule } from '@angular/material/tabs';
import { debounceTime, distinctUntilChanged, filter, map, switchMap, tap } from 'rxjs';

import { AdminAuthService } from '../../../core/auth/admin-auth.service';
import { ApiRequestError } from '../../../core/http/api-request-error';
import { PageHeaderComponent, SectionCardComponent } from '../../../shared/ui';
import { HttmFacilityService } from '../../httm/services/httm-facility.service';
import type { HttmSurveyDto, HttmSurveyHistoryDto, HttmSurveyPatchRequest } from '../models/survey.models';
import { SurveysApiService } from '../services/surveys-api.service';
import { SurveyPreviewDialogComponent } from '../dialogs/survey-preview-dialog.component';

function jsonOk(s: string): boolean {
  try {
    const o = JSON.parse(s) as unknown;
    return typeof o === 'object' && o !== null;
  } catch {
    return false;
  }
}

@Component({
  selector: 'app-survey-detail-page',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    RouterLink,
    MatTabsModule,
    MatSnackBarModule,
    MatDialogModule,
    MatButtonModule,
    PageHeaderComponent,
    SectionCardComponent,
  ],
  templateUrl: './survey-detail-page.component.html',
  styleUrl: './survey-detail-page.component.scss',
})
export class SurveyDetailPageComponent {
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly api = inject(SurveysApiService);
  private readonly facilities = inject(HttmFacilityService);
  private readonly fb = inject(FormBuilder);
  private readonly snack = inject(MatSnackBar);
  private readonly dialog = inject(MatDialog);
  private readonly auth = inject(AdminAuthService);

  readonly survey = signal<HttmSurveyDto | null>(null);
  readonly history = signal<HttmSurveyHistoryDto[]>([]);
  readonly loading = signal(false);
  readonly errorMessage = signal<string | null>(null);
  readonly rejectReason = signal('');
  readonly showReject = signal(false);

  readonly canReviewer = computed(() => {
    const r = this.auth.portalRole();
    return r === 'ADMIN' || r === 'HTTM_ADMIN' || r === 'BCT_STAFF';
  });

  readonly form = this.fb.nonNullable.group({
    currentStep: [1 as number, [Validators.required, Validators.min(1), Validators.max(7)]],
    step1Data: ['{}', [Validators.required]],
    step2Data: ['{}', [Validators.required]],
    step3Data: ['{}', [Validators.required]],
    step4Data: ['{}', [Validators.required]],
    step5Data: ['{}', [Validators.required]],
    step6Data: ['{}', [Validators.required]],
    step7Data: ['{}', [Validators.required]],
    confirmerData: ['{}', [Validators.required]],
  });

  constructor() {
    this.route.paramMap
      .pipe(
        map((p) => p.get('id')),
        filter((x): x is string => !!x),
        distinctUntilChanged(),
        tap(() => {
          this.loading.set(true);
          this.errorMessage.set(null);
        }),
        switchMap((sid) => this.api.getById(sid)),
        takeUntilDestroyed(),
      )
      .subscribe({
        next: (dto) => {
          this.survey.set(dto);
          this.form.patchValue(
            {
              currentStep: dto.currentStep,
              step1Data: dto.step1Data || '{}',
              step2Data: dto.step2Data || '{}',
              step3Data: dto.step3Data || '{}',
              step4Data: dto.step4Data || '{}',
              step5Data: dto.step5Data || '{}',
              step6Data: dto.step6Data || '{}',
              step7Data: dto.step7Data || '{}',
              confirmerData: dto.confirmerData || '{}',
            },
            { emitEvent: false },
          );
          this.loading.set(false);
          this.loadHistory(dto.id);
        },
        error: (e: unknown) => {
          this.loading.set(false);
          this.errorMessage.set(e instanceof ApiRequestError ? e.message : 'Không tải được phiếu.');
        },
      });

    this.form.valueChanges
      .pipe(
        debounceTime(60_000),
        distinctUntilChanged(),
        filter(() => {
          const s = this.survey();
          return !!s && (s.status === 'draft' || s.status === 'rejected');
        }),
        switchMap(() => this.savePatch()),
        takeUntilDestroyed(),
      )
      .subscribe({
        next: () => this.snack.open('Đã tự động lưu nháp', 'Đóng', { duration: 2500 }),
        error: (e: unknown) =>
          this.snack.open(e instanceof ApiRequestError ? e.message : 'Lỗi lưu', 'Đóng', { duration: 5000 }),
      });
  }

  private loadHistory(surveyId: string): void {
    this.api.history(surveyId).subscribe({
      next: (h) => this.history.set(h),
      error: () => this.history.set([]),
    });
  }

  private currentSurveyId(): string | null {
    return this.route.snapshot.paramMap.get('id');
  }

  private buildPatch(): HttmSurveyPatchRequest {
    const v = this.form.getRawValue();
    return {
      currentStep: v.currentStep,
      step1Data: v.step1Data,
      step2Data: v.step2Data,
      step3Data: v.step3Data,
      step4Data: v.step4Data,
      step5Data: v.step5Data,
      step6Data: v.step6Data,
      step7Data: v.step7Data,
      confirmerData: v.confirmerData,
    };
  }

  saveNow(): void {
    for (const k of ['step1Data', 'step2Data', 'step3Data', 'step4Data', 'step5Data', 'step6Data', 'step7Data', 'confirmerData'] as const) {
      if (!jsonOk(this.form.get(k)!.value)) {
        this.snack.open(`JSON không hợp lệ: ${k}`, 'Đóng', { duration: 4000 });
        return;
      }
    }
    this.savePatch().subscribe({
      next: () => this.snack.open('Đã lưu', 'Đóng', { duration: 2000 }),
      error: (e: unknown) =>
        this.snack.open(e instanceof ApiRequestError ? e.message : 'Lỗi lưu', 'Đóng', { duration: 5000 }),
    });
  }

  private savePatch() {
    const sid = this.currentSurveyId();
    if (!sid) {
      throw new Error('missing survey id');
    }
    return this.api.patch(sid, this.buildPatch());
  }

  openPreview(): void {
    const s = this.survey();
    if (!s) {
      return;
    }
    const merged = { ...s, ...this.buildPatch() };
    this.dialog.open(SurveyPreviewDialogComponent, {
      width: '720px',
      data: { json: JSON.stringify(merged, null, 2) },
    });
  }

  submit(): void {
    const sid = this.currentSurveyId();
    if (!sid) {
      return;
    }
    this.api.submit(sid).subscribe({
      next: () => {
        this.snack.open('Đã nộp phiếu', 'Đóng', { duration: 3000 });
        this.reload(sid);
      },
      error: (e: unknown) =>
        this.snack.open(e instanceof ApiRequestError ? e.message : 'Không nộp được', 'Đóng', { duration: 5000 }),
    });
  }

  startReview(): void {
    const sid = this.currentSurveyId();
    if (!sid) {
      return;
    }
    this.api.startReview(sid).subscribe({
      next: () => this.reload(sid),
      error: (e: unknown) =>
        this.snack.open(e instanceof ApiRequestError ? e.message : 'Lỗi', 'Đóng', { duration: 5000 }),
    });
  }

  approve(): void {
    const sid = this.currentSurveyId();
    if (!sid) {
      return;
    }
    this.api.approve(sid, null).subscribe({
      next: () => this.reload(sid),
      error: (e: unknown) =>
        this.snack.open(e instanceof ApiRequestError ? e.message : 'Lỗi', 'Đóng', { duration: 5000 }),
    });
  }

  doReject(): void {
    const sid = this.currentSurveyId();
    const reason = this.rejectReason().trim();
    if (!sid || reason.length < 3) {
      this.snack.open('Nhập lý do trả lại (ít nhất 3 ký tự)', 'Đóng', { duration: 3000 });
      return;
    }
    this.api.reject(sid, reason).subscribe({
      next: () => {
        this.showReject.set(false);
        this.rejectReason.set('');
        this.reload(sid);
      },
      error: (e: unknown) =>
        this.snack.open(e instanceof ApiRequestError ? e.message : 'Lỗi', 'Đóng', { duration: 5000 }),
    });
  }

  importToHttm(): void {
    const sid = this.currentSurveyId();
    if (!sid) {
      return;
    }
    this.facilities.createFromApprovedSurvey(sid).subscribe({
      next: (r) => {
        this.snack.open('Đã tạo hồ sơ HTTM', 'Đóng', { duration: 3000 });
        void this.router.navigate(['/httm', r.id]);
      },
      error: (e: unknown) =>
        this.snack.open(e instanceof ApiRequestError ? e.message : 'Không tạo được hồ sơ', 'Đóng', {
          duration: 6000,
        }),
    });
  }

  deleteDraft(): void {
    const sid = this.currentSurveyId();
    if (!sid || !confirm('Xoá phiếu nháp này?')) {
      return;
    }
    this.api.delete(sid).subscribe({
      next: () => void this.router.navigate(['/surveys']),
      error: (e: unknown) =>
        this.snack.open(e instanceof ApiRequestError ? e.message : 'Lỗi xoá', 'Đóng', { duration: 5000 }),
    });
  }

  private reload(sid: string): void {
    this.api.getById(sid).subscribe({
      next: (dto) => {
        this.survey.set(dto);
        this.loadHistory(sid);
      },
    });
  }
}
