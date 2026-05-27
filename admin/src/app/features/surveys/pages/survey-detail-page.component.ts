import { CommonModule } from '@angular/common';
import { Component, computed, effect, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { MatButtonModule } from '@angular/material/button';
import { MatDialog, MatDialogModule } from '@angular/material/dialog';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { MatStepperModule } from '@angular/material/stepper';
import { debounceTime, distinctUntilChanged, filter, map, switchMap, tap } from 'rxjs';

import { AdminAuthService } from '../../../core/auth/admin-auth.service';
import { ApiRequestError } from '../../../core/http/api-request-error';
import { PageHeaderComponent, SectionCardComponent } from '../../../shared/ui';
import { HttmFacilityService } from '../../httm/services/httm-facility.service';
import { SurveyConfirmerComponent } from '../components/survey-confirmer.component';
import { SurveyStep2SurveyedComponent } from '../components/survey-step2-surveyed.component';
import { SurveyStep3GeneralComponent } from '../components/survey-step3-general.component';
import { SurveyStep4ItComponent } from '../components/survey-step4-it.component';
import { SurveyStep5RequirementsComponent } from '../components/survey-step5-requirements.component';
import { SurveyStep6SoftwareComponent } from '../components/survey-step6-software.component';
import { SurveyStep7OpinionsComponent } from '../components/survey-step7-opinions.component';
import type { HttmSurveyDto, HttmSurveyHistoryDto, HttmSurveyPatchRequest } from '../models/survey.models';
import {
  parseStepJson,
  stringifyStep,
  type SurveyConfirmerData,
  type SurveyStep2Data,
  type SurveyStep3Data,
  type SurveyStep4Data,
  type SurveyStep5Data,
  type SurveyStep6Data,
  type SurveyStep7Data,
} from '../models/survey-step.models';
import { SurveyPreviewDialogComponent } from '../dialogs/survey-preview-dialog.component';
import { SurveysApiService } from '../services/surveys-api.service';

@Component({
  selector: 'app-survey-detail-page',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    RouterLink,
    MatButtonModule,
    MatDialogModule,
    MatSnackBarModule,
    MatStepperModule,
    PageHeaderComponent,
    SectionCardComponent,
    SurveyStep2SurveyedComponent,
    SurveyStep3GeneralComponent,
    SurveyStep4ItComponent,
    SurveyStep5RequirementsComponent,
    SurveyStep6SoftwareComponent,
    SurveyStep7OpinionsComponent,
    SurveyConfirmerComponent,
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

  /** Status điều kiện edit (decision D7). */
  readonly isEditable = computed(() => {
    const st = this.survey()?.status;
    return st === 'draft' || st === 'rejected';
  });

  /** Form tổng: 8 sub-FormGroup + currentStep. */
  readonly form: FormGroup = this.buildForm();

  get step2(): FormGroup { return this.form.get('step2') as FormGroup; }
  get step3(): FormGroup { return this.form.get('step3') as FormGroup; }
  get step4(): FormGroup { return this.form.get('step4') as FormGroup; }
  get step5(): FormGroup { return this.form.get('step5') as FormGroup; }
  get step6(): FormGroup { return this.form.get('step6') as FormGroup; }
  get step7(): FormGroup { return this.form.get('step7') as FormGroup; }
  get confirmer(): FormGroup { return this.form.get('confirmer') as FormGroup; }

  constructor() {
    // Toggle enable/disable theo trạng thái
    effect(() => {
      if (this.isEditable()) this.form.enable({ emitEvent: false });
      else this.form.disable({ emitEvent: false });
    });

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
          this.loadIntoForm(dto);
          this.loading.set(false);
          this.loadHistory(dto.id);
        },
        error: (e: unknown) => {
          this.loading.set(false);
          this.errorMessage.set(e instanceof ApiRequestError ? e.message : 'Không tải được phiếu.');
        },
      });

    // Auto-save 60s khi editable + form dirty (D4 soft validation)
    this.form.valueChanges
      .pipe(
        debounceTime(60_000),
        filter(() => this.isEditable() && this.form.dirty),
        switchMap(() => this.savePatch()),
        takeUntilDestroyed(),
      )
      .subscribe({
        next: () => {
          this.form.markAsPristine();
          this.snack.open('Đã tự động lưu nháp', 'Đóng', { duration: 2500 });
        },
        error: (e: unknown) =>
          this.snack.open(e instanceof ApiRequestError ? e.message : 'Lỗi lưu', 'Đóng', { duration: 5000 }),
      });
  }

  private buildForm(): FormGroup {
    return this.fb.group({
      currentStep: [1],
      step2: this.fb.group({
        unit_name: [''],
        address: [''],
        tax_code: [''],
        parent_org: [''],
        members: this.fb.array<FormGroup>([]),
      }),
      step3: this.fb.group({
        unit_types: [[] as string[]],
        main_activities: [[] as string[]],
        operation_scope: [''],
        parent_unit: [''],
        sub_units: [''],
        legal_documents: this.fb.array<FormGroup>([]),
        staff_count: [null as number | null],
        responsible_staff: this.fb.array<FormGroup>([]),
        report_tool: [[] as string[]],
        report_send_method: [[] as string[]],
      }),
      step4: this.fb.group({
        has_software: [false],
        software_list: this.fb.array<FormGroup>([]),
        desktop_count: [null as number | null],
        laptop_count: [null as number | null],
        server_description: [''],
        network_types: [[] as string[]],
        bandwidth: [''],
        security_measures: [[] as string[]],
        security_notes: [''],
      }),
      step5: this.fb.group({
        info_needs: [[] as string[]],
        search_criteria: [[] as string[]],
        map_requirements: [[] as string[]],
        digitize_processes: [''],
        required_reports: [''],
        required_lookups: [''],
      }),
      step6: this.fb.group({
        features: [[] as string[]],
        admin_features: [[] as string[]],
        external_integrations: [''],
        utilities: [[] as string[]],
        platforms: [[] as string[]],
        other_notes: [''],
      }),
      step7: this.fb.group({
        difficulties: [''],
        advantages: [''],
        proposals: [''],
      }),
      confirmer: this.fb.group({
        name: [''],
        title: [''],
        reviewer_name: [''],
        reviewer_title: [''],
        confirmed_date: [null as Date | string | null],
      }),
    });
  }

  private loadIntoForm(dto: HttmSurveyDto): void {
    const s2 = parseStepJson<SurveyStep2Data>(dto.step2Data);
    const s3 = parseStepJson<SurveyStep3Data>(dto.step3Data);
    const s4 = parseStepJson<SurveyStep4Data>(dto.step4Data);
    const s5 = parseStepJson<SurveyStep5Data>(dto.step5Data);
    const s6 = parseStepJson<SurveyStep6Data>(dto.step6Data);
    const s7 = parseStepJson<SurveyStep7Data>(dto.step7Data);
    const cf = parseStepJson<SurveyConfirmerData>(dto.confirmerData);

    // Autofill tên đơn vị khảo sát = tên đơn vị của user đăng nhập (nếu user chưa nhập gì).
    // Áp dụng cho phiếu mới — phiếu cũ đã có dữ liệu thì giữ nguyên.
    if (!s2.unit_name) {
      const org = this.auth.currentUserProfile()?.organization;
      if (org?.ten) s2.unit_name = org.ten;
    }

    this.patchStep(this.step2, s2);
    this.replaceArray(this.step2, 'members', s2.members);

    this.patchStep(this.step3, s3);
    this.replaceArray(this.step3, 'legal_documents', s3.legal_documents);
    this.replaceArray(this.step3, 'responsible_staff', s3.responsible_staff);

    this.patchStep(this.step4, s4);
    this.replaceArray(this.step4, 'software_list', s4.software_list);

    this.patchStep(this.step5, s5);
    this.patchStep(this.step6, s6);
    this.patchStep(this.step7, s7);
    this.patchStep(this.confirmer, cf);

    this.form.patchValue({ currentStep: dto.currentStep }, { emitEvent: false });
    this.form.markAsPristine();
  }

  private patchStep(grp: FormGroup, obj: object): void {
    // patchValue chỉ với key có trong FormGroup, không emit để tránh trigger autosave
    const allowed: Record<string, unknown> = {};
    for (const k of Object.keys(grp.controls)) {
      const ctrl = grp.controls[k];
      // bỏ qua FormArray (xử lý riêng qua replaceArray)
      if ('controls' in ctrl && Array.isArray((ctrl as { controls: unknown }).controls)) continue;
      const v = (obj as Record<string, unknown>)[k];
      if (v !== undefined) allowed[k] = v;
    }
    grp.patchValue(allowed, { emitEvent: false });
  }

  private replaceArray(grp: FormGroup, key: string, rows: object[] | undefined): void {
    const arr = grp.get(key);
    if (!arr || typeof (arr as { clear?: () => void }).clear !== 'function') return;
    const a = arr as unknown as import('@angular/forms').FormArray;
    a.clear({ emitEvent: false });
    if (!rows) return;
    for (const r of rows) {
      a.push(this.fb.group(r as Record<string, unknown>), { emitEvent: false });
    }
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
    // Step1 (Bên KS) đã bỏ ở UI — quản trị sẽ bổ sung sau qua tool admin riêng.
    // KHÔNG gửi step1Data trong patch → backend giữ nguyên giá trị DB (mặc định '{}').
    const v = this.form.getRawValue();
    return {
      currentStep: v.currentStep,
      step2Data: stringifyStep(v.step2),
      step3Data: stringifyStep(v.step3),
      step4Data: stringifyStep(v.step4),
      step5Data: stringifyStep(v.step5),
      step6Data: stringifyStep(v.step6),
      step7Data: stringifyStep(v.step7),
      confirmerData: stringifyStep(v.confirmer),
    };
  }

  saveNow(): void {
    if (!this.isEditable()) return;
    this.savePatch().subscribe({
      next: () => {
        this.form.markAsPristine();
        this.snack.open('Đã lưu', 'Đóng', { duration: 2000 });
      },
      error: (e: unknown) =>
        this.snack.open(e instanceof ApiRequestError ? e.message : 'Lỗi lưu', 'Đóng', { duration: 5000 }),
    });
  }

  private savePatch() {
    const sid = this.currentSurveyId();
    if (!sid) throw new Error('missing survey id');
    return this.api.patch(sid, this.buildPatch());
  }

  openPreview(): void {
    const s = this.survey();
    if (!s) return;
    // Lấy trực tiếp giá trị form (kể cả phần chưa lưu) — preview = snapshot "what you'll submit".
    const v = this.form.getRawValue();
    this.dialog.open(SurveyPreviewDialogComponent, {
      width: '880px',
      maxWidth: '92vw',
      panelClass: 'survey-preview-panel',
      data: {
        meta: {
          surveyCode: s.surveyCode,
          status: s.status,
          provinceCode: s.provinceCode,
          httmType: s.httmType,
          createdAt: s.createdAt,
          submittedAt: s.submittedAt,
          reviewedAt: s.reviewedAt,
        },
        step2: v.step2,
        step3: v.step3,
        step4: v.step4,
        step5: v.step5,
        step6: v.step6,
        step7: v.step7,
        confirmer: v.confirmer,
      },
    });
  }

  submit(): void {
    const sid = this.currentSurveyId();
    if (!sid) return;
    if (!this.validateSubmit()) return;
    this.savePatch().subscribe({
      next: () => {
        this.api.submit(sid).subscribe({
          next: () => {
            this.snack.open('Đã nộp phiếu', 'Đóng', { duration: 3000 });
            this.reload(sid);
          },
          error: (e: unknown) =>
            this.snack.open(e instanceof ApiRequestError ? e.message : 'Không nộp được', 'Đóng', { duration: 5000 }),
        });
      },
      error: (e: unknown) =>
        this.snack.open(e instanceof ApiRequestError ? e.message : 'Lỗi lưu', 'Đóng', { duration: 5000 }),
    });
  }

  /** Validate strict trước khi nộp (decision D4). */
  private validateSubmit(): boolean {
    const errs: string[] = [];
    const v = this.form.getRawValue();
    if (!v.step2.unit_name?.trim()) errs.push('Bước 2: Tên đơn vị được khảo sát bắt buộc.');
    if (!v.step2.address?.trim()) errs.push('Bước 2: Địa chỉ bắt buộc.');
    if (!(v.step3.unit_types?.length > 0)) errs.push('Bước 3: Chọn ít nhất 1 loại hình đơn vị.');
    if (!(v.step3.main_activities?.length > 0)) errs.push('Bước 3: Chọn ít nhất 1 hoạt động chính.');
    if (!v.confirmer.name?.trim()) errs.push('Xác nhận: Tên người xác nhận bắt buộc.');
    if (!v.confirmer.confirmed_date) errs.push('Xác nhận: Ngày xác nhận bắt buộc.');

    if (errs.length > 0) {
      this.snack.open(errs.join(' | '), 'Đóng', { duration: 8000 });
      this.step2.markAllAsTouched();
      this.step3.markAllAsTouched();
      this.confirmer.markAllAsTouched();
      return false;
    }
    return true;
  }

  startReview(): void {
    const sid = this.currentSurveyId();
    if (!sid) return;
    this.api.startReview(sid).subscribe({
      next: () => this.reload(sid),
      error: (e: unknown) =>
        this.snack.open(e instanceof ApiRequestError ? e.message : 'Lỗi', 'Đóng', { duration: 5000 }),
    });
  }

  approve(): void {
    const sid = this.currentSurveyId();
    if (!sid) return;
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
    if (!sid) return;
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
    if (!sid || !confirm('Xoá phiếu nháp này?')) return;
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
        this.loadIntoForm(dto);
        this.loadHistory(sid);
      },
    });
  }
}
