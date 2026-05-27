# Survey Form (Phiếu Khảo Sát) — Implementation Checklist

> **Scope**: refactor trang `/surveys/:id` từ 8 textarea raw JSON → form đầy đủ với ô nhập tương ứng schema JSON từng bước (theo `docs/modules/httm/screens.md` S2.2).
> Track tiến độ implement. Đánh dấu `[x]` khi xong + commit hash.

## 0. Decisions đã chốt (2026-05-15)

| # | Quyết định |
|---|------------|
| D1 | Enum options 12 list — **hardcode** trong `survey-enum-options.ts` theo screens.md (Phase 1). Future Phase 3: chuyển catalog dynamic |
| D2 | Step 1 (surveyor) — **autofill** từ thông tin user đang đăng nhập (unit_name = DM_DonVi của user) |
| D3 | Giữ **7 step + Confirmer riêng** (UI 8 tab) theo schema gốc |
| D4 | Validation **soft** — chỉ required khi nhấn "Nộp"; auto-save draft luôn được phép kể cả khi thiếu |
| D5 | **Bỏ** raw JSON view — chỉ form. Admin debug dùng DevTools / DB |
| D6 | FormArray UI: **inline rows** trong card, nút "Thêm dòng" / "Xóa" |
| D7 | Status workflow: `draft|rejected` → editable; `submitted|reviewing|approved` → readonly |

## 1. Types + config

- [x] `models/survey-step.models.ts` — 8 interface: `SurveyStep1Data` ... `SurveyStep7Data` + `SurveyConfirmerData`
- [x] `models/survey-form-helpers.ts` — `parseStepJson<T>()`, `stringifyStep()` helpers
- [x] `config/survey-enum-options.ts` — 12 hardcoded list:
  - [x] `UNIT_TYPES` (loại đơn vị bị KS, step 3)
  - [x] `MAIN_ACTIVITIES` (hoạt động chính, step 3)
  - [x] `REPORT_TOOLS`
  - [x] `REPORT_SEND_METHODS`
  - [x] `NETWORK_TYPES`
  - [x] `SECURITY_MEASURES`
  - [x] `INFO_NEEDS` (18 loại, step 5)
  - [x] `SEARCH_CRITERIA`
  - [x] `MAP_REQUIREMENTS`
  - [x] `SW_FEATURES` (14 chức năng, step 6)
  - [x] `SW_UTILITIES`
  - [x] `SW_PLATFORMS`

## 2. Shared components

- [x] `components/survey-members-array.component.ts` — FormArray reusable cho step 1, 2, 3 (members / responsible_staff)
  - Columns: name, title, role (step 1, 3) hoặc name, title, phone, email (step 2)
  - Mode "compact" (3 cột) vs "contact" (4 cột) qua input prop
- [x] `components/survey-legal-docs-array.component.ts` — FormArray cho legal_documents { index, content }
- [x] `components/survey-software-list-array.component.ts` — FormArray software_list { name, description, integration }

## 3. Step components (8 standalone, mỗi file dưới `components/`)

### 3.1 Step 1 — Surveyor (Thông tin bên khảo sát)
- [x] `survey-step1-surveyor.component.ts/html/scss`
- Fields: `unit_name` (autofill DM_DonVi user), `consultant`, `members` FormArray (compact mode)
- Required khi submit: none (step 1 không required theo S2.2 spec)

### 3.2 Step 2 — Surveyed (Đơn vị được khảo sát)
- [x] `survey-step2-surveyed.component.ts/html/scss`
- Fields: `unit_name` **req**, `address` **req**, `tax_code`, `parent_org`, `members` (contact mode)

### 3.3 Step 3 — General (Hiện trạng hoạt động)
- [x] `survey-step3-general.component.ts/html/scss`
- Fields: `unit_types[]` **req min 1** (multi-select), `main_activities[]` **req min 1**, `operation_scope` (textarea), `parent_unit`, `sub_units`, `legal_documents[]`, `staff_count` (int), `responsible_staff[]`, `report_tool[]`, `report_send_method[]`

### 3.4 Step 4 — IT (Hạ tầng CNTT)
- [x] `survey-step4-it.component.ts/html/scss`
- Fields: `has_software` (toggle), `software_list[]`, `desktop_count` (int), `laptop_count` (int), `server_description` (textarea), `network_types[]`, `bandwidth`, `security_measures[]`, `security_notes` (textarea)

### 3.5 Step 5 — Requirements (Nhu cầu quản lý)
- [x] `survey-step5-requirements.component.ts/html/scss`
- Fields: `info_needs[]` (18 options), `search_criteria[]`, `map_requirements[]`, `digitize_processes` (textarea), `required_reports` (textarea), `required_lookups` (textarea)

### 3.6 Step 6 — Software requirements (Yêu cầu phần mềm)
- [x] `survey-step6-software.component.ts/html/scss`
- Fields: `features[]` (14 options), `admin_features[]`, `external_integrations` (textarea), `utilities[]`, `platforms[]`, `other_notes` (textarea)

### 3.7 Step 7 — Opinions (Ý kiến đề xuất)
- [x] `survey-step7-opinions.component.ts/html/scss`
- Fields: `difficulties` (textarea), `advantages` (textarea), `proposals` (textarea)

### 3.8 Confirmer
- [x] `survey-confirmer.component.ts/html/scss`
- Fields: `name` **req**, `title`, `reviewer_name`, `reviewer_title`, `confirmed_date` **req** (date picker)

## 4. Parent stepper refactor

- [x] Sửa `survey-detail-page.component.ts`:
  - Bỏ 8 textarea + JSON.parse logic
  - Build FormGroup tổng có 8 sub-FormGroup (step1..step7 + confirmer)
  - Mỗi step component nhận `[parent]="form.controls.stepX"` qua `@Input`
  - Auto-save 60s: serialize từng sub-FormGroup → JSON → patch lên API qua `surveys-api.service`
- [x] Sửa template: thay accordion JSON → `<mat-stepper linear="false">` với 8 step
- [x] Sidebar: hiển thị danh sách step + dấu ✓ khi step valid (cho UX, không block điều hướng)

## 5. Status workflow

- [x] Computed `isEditable = status in ['draft', 'rejected']`
- [x] Disable toàn bộ form controls + hide nút "Lưu" nếu không editable
- [x] Badge trạng thái + link "Xem hồ sơ HTTM đã tạo" (nếu approved + linkedFacilityId)

## 6. Serialize/deserialize

- [x] Khi load: parse `step1Data..step7Data + confirmerData` (string JSON) → object → patchValue
- [x] Khi save (auto-save hoặc manual): stringify từng sub-FormGroup → gửi PATCH
- [x] Empty FormArray → `{ members: [] }` (không undefined)

## 7. Submit flow

- [x] Nút "Lưu nháp" → PATCH với data hiện tại (kể cả thiếu required)
- [x] Nút "Nộp" → validate strict (D4) → confirm modal → POST `/api/surveys/{id}/submit`
- [x] Sau submit → reload, form chuyển readonly

## 8. Testing + verify

- [ ] Karma test 1 step component sample (step 7 opinions — đơn giản nhất) — defer
- [ ] Manual E2E: tạo phiếu mới → điền 8 step → save draft → reload → submit — anh test

## Lịch sử

| Ngày | Người | Thay đổi |
|------|-------|----------|
| 2026-05-15 | Claude | Khởi tạo checklist + 7 decisions D1-D7 |
| 2026-05-15 | Claude | Implement đầy đủ: 12 enum lists, 3 FormArray shared components, 8 step components, parent stepper refactor, status workflow disable, submit strict validation, auto-save 60s, Angular build pass |
