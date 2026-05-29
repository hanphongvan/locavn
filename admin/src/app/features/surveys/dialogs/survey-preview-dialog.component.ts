import { CommonModule } from '@angular/common';
import { ChangeDetectionStrategy, Component, ElementRef, ViewChild, inject } from '@angular/core';
import { MAT_DIALOG_DATA, MatDialogModule } from '@angular/material/dialog';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';

import {
  INFO_NEEDS,
  MAIN_ACTIVITIES,
  MAP_REQUIREMENTS,
  NETWORK_TYPES,
  REPORT_SEND_METHODS,
  REPORT_TOOLS,
  SEARCH_CRITERIA,
  SECURITY_MEASURES,
  SW_FEATURES,
  SW_PLATFORMS,
  SW_UTILITIES,
  UNIT_TYPES,
  type SurveyOption,
} from '../config/survey-enum-options';
import type {
  SurveyConfirmerData,
  SurveyStep2Data,
  SurveyStep3Data,
  SurveyStep4Data,
  SurveyStep5Data,
  SurveyStep6Data,
  SurveyStep7Data,
} from '../models/survey-step.models';

export interface SurveyPreviewDialogData {
  meta: {
    surveyCode: string;
    status: string;
    provinceCode: string;
    httmType: string | null;
    createdAt: string;
    submittedAt: string | null;
    reviewedAt: string | null;
  };
  step2: SurveyStep2Data;
  step3: SurveyStep3Data;
  step4: SurveyStep4Data;
  step5: SurveyStep5Data;
  step6: SurveyStep6Data;
  step7: SurveyStep7Data;
  confirmer: SurveyConfirmerData;
}

const STATUS_LABEL: Record<string, string> = {
  draft: 'Bản nháp',
  submitted: 'Đã nộp',
  reviewing: 'Đang xem xét',
  approved: 'Đã duyệt',
  rejected: 'Từ chối',
};

@Component({
  selector: 'app-survey-preview-dialog',
  standalone: true,
  imports: [CommonModule, MatDialogModule, MatButtonModule, MatIconModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="preview-dialog">
      <header class="preview-dialog__bar no-print">
        <h2 matDialogTitle>Xem trước phiếu khảo sát</h2>
        <div class="actions">
          <button mat-stroked-button (click)="print()">
            <mat-icon>print</mat-icon> In phiếu
          </button>
          <button mat-flat-button mat-dialog-close>Đóng</button>
        </div>
      </header>

      <mat-dialog-content class="preview-dialog__body">
        <article #printArea class="preview-sheet">
          <!-- ─────────── Header ─────────── -->
          <section class="sheet-header">
            <h1 class="sheet-title">PHIẾU KHẢO SÁT HẠ TẦNG THƯƠNG MẠI</h1>
            <div class="sheet-meta-grid">
              <div><span class="lbl">Mã phiếu:</span><b>{{ data.meta.surveyCode }}</b></div>
              <div><span class="lbl">Trạng thái:</span><b>{{ statusLabel(data.meta.status) }}</b></div>
              <div><span class="lbl">Tỉnh:</span><b>{{ data.meta.provinceCode }}</b></div>
              <div><span class="lbl">Loại HTTM:</span><b>{{ data.meta.httmType || 'Khảo sát chung' }}</b></div>
              <div><span class="lbl">Ngày tạo:</span><b>{{ data.meta.createdAt | date: 'dd/MM/yyyy HH:mm' }}</b></div>
              <div><span class="lbl">Ngày nộp:</span><b>{{ (data.meta.submittedAt | date: 'dd/MM/yyyy HH:mm') || '—' }}</b></div>
            </div>
          </section>

          <!-- ─────────── I. Đơn vị được khảo sát ─────────── -->
          <section class="sheet-section">
            <h2 class="sheet-section__title">I. Thông tin đơn vị được khảo sát</h2>
            <dl class="kv">
              <dt>Tên đơn vị</dt><dd>{{ orDash(data.step2.unit_name) }}</dd>
              <dt>Địa chỉ</dt><dd>{{ orDash(data.step2.address) }}</dd>
              <dt>Mã số thuế</dt><dd>{{ orDash(data.step2.tax_code) }}</dd>
              <dt>Cơ quan chủ quản</dt><dd>{{ orDash(data.step2.parent_org) }}</dd>
            </dl>
            @if (data.step2.members?.length) {
              <h3 class="sheet-subtitle">Đầu mối liên hệ</h3>
              <table class="sheet-table">
                <thead>
                  <tr><th style="width: 36px;">#</th><th>Họ tên</th><th>Chức danh</th><th>SĐT</th><th>Email</th></tr>
                </thead>
                <tbody>
                  @for (m of data.step2.members; track $index) {
                    <tr>
                      <td>{{ $index + 1 }}</td>
                      <td>{{ orDash(m.name) }}</td>
                      <td>{{ orDash(m.title) }}</td>
                      <td>{{ orDash(m.phone) }}</td>
                      <td>{{ orDash(m.email) }}</td>
                    </tr>
                  }
                </tbody>
              </table>
            }
          </section>

          <!-- ─────────── II. Hiện trạng hoạt động ─────────── -->
          <section class="sheet-section">
            <h2 class="sheet-section__title">II. Hiện trạng hoạt động</h2>
            <dl class="kv">
              <dt>Loại hình đơn vị</dt><dd>{{ labels(data.step3.unit_types, UNIT_TYPES) }}</dd>
              <dt>Hoạt động chính</dt><dd>{{ labels(data.step3.main_activities, MAIN_ACTIVITIES) }}</dd>
              <dt>Phạm vi hoạt động</dt><dd>{{ orDash(data.step3.operation_scope) }}</dd>
              <dt>Đơn vị chủ quản</dt><dd>{{ orDash(data.step3.parent_unit) }}</dd>
              <dt>Đơn vị trực thuộc</dt><dd>{{ orDash(data.step3.sub_units) }}</dd>
              <dt>Số nhân sự</dt><dd>{{ orDash(data.step3.staff_count) }}</dd>
              <dt>Công cụ làm báo cáo</dt><dd>{{ labels(data.step3.report_tool, REPORT_TOOLS) }}</dd>
              <dt>Phương thức gửi báo cáo</dt><dd>{{ labels(data.step3.report_send_method, REPORT_SEND_METHODS) }}</dd>
            </dl>
            @if (data.step3.legal_documents?.length) {
              <h3 class="sheet-subtitle">Văn bản pháp lý liên quan</h3>
              <table class="sheet-table">
                <thead><tr><th style="width: 56px;">STT</th><th>Nội dung</th></tr></thead>
                <tbody>
                  @for (d of data.step3.legal_documents; track $index) {
                    <tr><td>{{ d.index ?? ($index + 1) }}</td><td>{{ orDash(d.content) }}</td></tr>
                  }
                </tbody>
              </table>
            }
            @if (data.step3.responsible_staff?.length) {
              <h3 class="sheet-subtitle">Nhân sự phụ trách</h3>
              <table class="sheet-table">
                <thead><tr><th style="width: 36px;">#</th><th>Họ tên</th><th>Chức danh</th><th>Vai trò</th></tr></thead>
                <tbody>
                  @for (m of data.step3.responsible_staff; track $index) {
                    <tr>
                      <td>{{ $index + 1 }}</td>
                      <td>{{ orDash(m.name) }}</td>
                      <td>{{ orDash(m.title) }}</td>
                      <td>{{ orDash(m.role) }}</td>
                    </tr>
                  }
                </tbody>
              </table>
            }
          </section>

          <!-- ─────────── III. Hạ tầng CNTT ─────────── -->
          <section class="sheet-section">
            <h2 class="sheet-section__title">III. Hạ tầng công nghệ thông tin</h2>
            <dl class="kv">
              <dt>Có sử dụng phần mềm</dt><dd>{{ boolLabel(data.step4.has_software) }}</dd>
              <dt>Máy tính để bàn</dt><dd>{{ orDash(data.step4.desktop_count) }}</dd>
              <dt>Máy tính xách tay</dt><dd>{{ orDash(data.step4.laptop_count) }}</dd>
              <dt>Hạ tầng máy chủ</dt><dd>{{ orDash(data.step4.server_description) }}</dd>
              <dt>Loại mạng</dt><dd>{{ labels(data.step4.network_types, NETWORK_TYPES) }}</dd>
              <dt>Băng thông</dt><dd>{{ orDash(data.step4.bandwidth) }}</dd>
              <dt>Biện pháp bảo mật</dt><dd>{{ labels(data.step4.security_measures, SECURITY_MEASURES) }}</dd>
              <dt>Ghi chú bảo mật</dt><dd>{{ orDash(data.step4.security_notes) }}</dd>
            </dl>
            @if (data.step4.software_list?.length) {
              <h3 class="sheet-subtitle">Danh sách phần mềm đang dùng</h3>
              <table class="sheet-table">
                <thead><tr><th style="width: 36px;">#</th><th>Tên phần mềm</th><th>Mô tả</th><th>Tích hợp</th></tr></thead>
                <tbody>
                  @for (s of data.step4.software_list; track $index) {
                    <tr>
                      <td>{{ $index + 1 }}</td>
                      <td>{{ orDash(s.name) }}</td>
                      <td>{{ orDash(s.description) }}</td>
                      <td>{{ orDash(s.integration) }}</td>
                    </tr>
                  }
                </tbody>
              </table>
            }
          </section>

          <!-- ─────────── IV. Nhu cầu quản lý ─────────── -->
          <section class="sheet-section">
            <h2 class="sheet-section__title">IV. Nhu cầu quản lý</h2>
            <dl class="kv">
              <dt>Nhu cầu thông tin</dt><dd>{{ labels(data.step5.info_needs, INFO_NEEDS) }}</dd>
              <dt>Tiêu chí tìm kiếm</dt><dd>{{ labels(data.step5.search_criteria, SEARCH_CRITERIA) }}</dd>
              <dt>Yêu cầu bản đồ</dt><dd>{{ labels(data.step5.map_requirements, MAP_REQUIREMENTS) }}</dd>
              <dt>Quy trình cần số hoá</dt><dd>{{ orDash(data.step5.digitize_processes) }}</dd>
              <dt>Báo cáo cần có</dt><dd>{{ orDash(data.step5.required_reports) }}</dd>
              <dt>Tra cứu cần có</dt><dd>{{ orDash(data.step5.required_lookups) }}</dd>
            </dl>
          </section>

          <!-- ─────────── V. Yêu cầu phần mềm ─────────── -->
          <section class="sheet-section">
            <h2 class="sheet-section__title">V. Yêu cầu phần mềm</h2>
            <dl class="kv">
              <dt>Chức năng nghiệp vụ</dt><dd>{{ labels(data.step6.features, SW_FEATURES) }}</dd>
              <dt>Chức năng quản trị</dt><dd>{{ labels(data.step6.admin_features, SW_FEATURES) }}</dd>
              <dt>Tiện ích</dt><dd>{{ labels(data.step6.utilities, SW_UTILITIES) }}</dd>
              <dt>Nền tảng triển khai</dt><dd>{{ labels(data.step6.platforms, SW_PLATFORMS) }}</dd>
              <dt>Tích hợp hệ thống ngoài</dt><dd>{{ orDash(data.step6.external_integrations) }}</dd>
              <dt>Ghi chú khác</dt><dd>{{ orDash(data.step6.other_notes) }}</dd>
            </dl>
          </section>

          <!-- ─────────── VI. Ý kiến đề xuất ─────────── -->
          <section class="sheet-section">
            <h2 class="sheet-section__title">VI. Ý kiến đề xuất</h2>
            <dl class="kv">
              <dt>Khó khăn, vướng mắc</dt><dd class="multiline">{{ orDash(data.step7.difficulties) }}</dd>
              <dt>Thuận lợi</dt><dd class="multiline">{{ orDash(data.step7.advantages) }}</dd>
              <dt>Đề xuất, kiến nghị</dt><dd class="multiline">{{ orDash(data.step7.proposals) }}</dd>
            </dl>
          </section>

          <!-- ─────────── Xác nhận ─────────── -->
          <section class="sheet-section">
            <h2 class="sheet-section__title">Xác nhận phiếu</h2>
            <div class="sign-grid">
              <div class="sign-cell">
                <p class="sign-role">Người lập phiếu</p>
                <p class="sign-name">{{ orDash(data.confirmer.name) }}</p>
                <p class="sign-title">{{ orDash(data.confirmer.title) }}</p>
              </div>
              <div class="sign-cell">
                <p class="sign-role">Người duyệt</p>
                <p class="sign-name">{{ orDash(data.confirmer.reviewer_name) }}</p>
                <p class="sign-title">{{ orDash(data.confirmer.reviewer_title) }}</p>
              </div>
              <div class="sign-cell sign-cell--date">
                <p class="sign-role">Ngày xác nhận</p>
                <p class="sign-name">{{ (data.confirmer.confirmed_date | date: 'dd/MM/yyyy') || '—' }}</p>
              </div>
            </div>
          </section>
        </article>
      </mat-dialog-content>
    </div>
  `,
  styles: [
    `
      .preview-dialog {
        display: flex;
        flex-direction: column;
        max-height: 92vh;
      }
      .preview-dialog__bar {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 0 8px 8px;
        border-bottom: 1px solid rgba(0, 0, 0, 0.08);
      }
      .preview-dialog__bar h2 { margin: 0; font-size: 16px; }
      .preview-dialog__bar .actions { display: flex; gap: 8px; }
      .preview-dialog__body { padding: 16px 4px; overflow: auto; }

      .preview-sheet {
        background: #fff;
        padding: 28px 36px;
        font-family: 'Times New Roman', 'Times', serif;
        color: #222;
        line-height: 1.5;
        max-width: 820px;
        margin: 0 auto;
      }

      .sheet-header { text-align: center; margin-bottom: 18px; }
      .sheet-title { margin: 0 0 12px; font-size: 18px; font-weight: 700; text-transform: uppercase; }
      .sheet-meta-grid {
        display: grid;
        grid-template-columns: repeat(3, 1fr);
        gap: 4px 16px;
        text-align: left;
        font-size: 12.5px;
        border: 1px solid #ddd;
        padding: 8px 12px;
        background: #fafafa;
      }
      .sheet-meta-grid .lbl { color: #555; margin-right: 6px; }

      .sheet-section { margin-top: 18px; page-break-inside: avoid; }
      .sheet-section__title {
        font-size: 14px;
        font-weight: 700;
        text-transform: uppercase;
        margin: 0 0 8px;
        padding: 4px 8px;
        background: #eef3fb;
        border-left: 3px solid #1565c0;
      }
      .sheet-subtitle {
        font-size: 13px;
        margin: 10px 0 6px;
        font-weight: 600;
        color: #1565c0;
      }

      .kv {
        display: grid;
        grid-template-columns: 230px 1fr;
        gap: 4px 12px;
        margin: 0;
        font-size: 13px;
      }
      .kv dt {
        color: #444;
        font-weight: 500;
      }
      .kv dt::after { content: ':'; }
      .kv dd {
        margin: 0;
        font-weight: 600;
        color: #111;
        word-break: break-word;
      }
      .kv dd.multiline { white-space: pre-wrap; font-weight: 400; }

      .sheet-table {
        width: 100%;
        border-collapse: collapse;
        font-size: 12.5px;
        margin-top: 6px;
      }
      .sheet-table th,
      .sheet-table td {
        border: 1px solid #ccc;
        padding: 4px 8px;
        vertical-align: top;
      }
      .sheet-table th {
        background: #f0f0f0;
        font-weight: 600;
        text-align: left;
      }

      .sign-grid {
        display: grid;
        grid-template-columns: 1fr 1fr 1fr;
        gap: 16px;
        margin-top: 10px;
        text-align: center;
      }
      .sign-cell {
        border: 1px dashed #bbb;
        padding: 8px;
        min-height: 90px;
      }
      .sign-role { margin: 0; font-size: 12px; color: #666; text-transform: uppercase; }
      .sign-name { margin: 24px 0 0; font-weight: 700; }
      .sign-title { margin: 2px 0 0; font-size: 12px; color: #444; }
      .sign-cell--date .sign-name { margin-top: 24px; }

      /* In: ẩn dialog chrome, mở rộng sheet ra cả trang */
      @media print {
        :host, .preview-dialog, .preview-dialog__body { max-height: none !important; overflow: visible !important; }
        .no-print { display: none !important; }
        .preview-sheet { max-width: none; padding: 0; }
      }
    `,
  ],
})
export class SurveyPreviewDialogComponent {
  readonly data = inject<SurveyPreviewDialogData>(MAT_DIALOG_DATA);

  // Expose enum maps cho template
  readonly UNIT_TYPES = UNIT_TYPES;
  readonly MAIN_ACTIVITIES = MAIN_ACTIVITIES;
  readonly REPORT_TOOLS = REPORT_TOOLS;
  readonly REPORT_SEND_METHODS = REPORT_SEND_METHODS;
  readonly NETWORK_TYPES = NETWORK_TYPES;
  readonly SECURITY_MEASURES = SECURITY_MEASURES;
  readonly INFO_NEEDS = INFO_NEEDS;
  readonly SEARCH_CRITERIA = SEARCH_CRITERIA;
  readonly MAP_REQUIREMENTS = MAP_REQUIREMENTS;
  readonly SW_FEATURES = SW_FEATURES;
  readonly SW_UTILITIES = SW_UTILITIES;
  readonly SW_PLATFORMS = SW_PLATFORMS;

  @ViewChild('printArea', { static: false }) printArea?: ElementRef<HTMLElement>;

  orDash(v: unknown): string {
    if (v === null || v === undefined) return '—';
    const s = String(v).trim();
    return s.length === 0 ? '—' : s;
  }

  boolLabel(v: boolean | null | undefined): string {
    if (v === true) return 'Có';
    if (v === false) return 'Không';
    return '—';
  }

  statusLabel(code: string | null | undefined): string {
    if (!code) return '—';
    return STATUS_LABEL[code] ?? code;
  }

  /** Map mảng code → chuỗi nhãn tiếng Việt, ngăn cách bằng "; ". Code không khớp giữ nguyên. */
  labels(codes: string[] | null | undefined, options: SurveyOption[]): string {
    if (!codes || codes.length === 0) return '—';
    const map = new Map(options.map((o) => [o.code, o.label]));
    return codes.map((c) => map.get(c) ?? c).join('; ');
  }

  /** Mở dialog in trình duyệt — CSS @media print sẽ tự ẩn dialog chrome. */
  print(): void {
    window.print();
  }
}
