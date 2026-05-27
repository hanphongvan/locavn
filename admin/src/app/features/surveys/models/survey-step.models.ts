/**
 * Schema 7 step + Confirmer của phiếu khảo sát HTTM.
 * Khớp với `httm_surveys.step{1..7}_data + confirmer_data` (NVARCHAR(MAX) ISJSON).
 * Mọi field optional ở C# DTO — required check làm ở UI khi nhấn "Nộp" (decision D4).
 */

export interface SurveyMember {
  name?: string;
  title?: string;
  role?: string;
}

export interface SurveyContactMember {
  name?: string;
  title?: string;
  phone?: string;
  email?: string;
}

export interface SurveyLegalDocument {
  index?: string | number;
  content?: string;
}

export interface SurveySoftwareItem {
  name?: string;
  description?: string;
  integration?: string;
}

/** Step 1 — Thông tin bên khảo sát. */
export interface SurveyStep1Data {
  unit_name?: string;
  consultant?: string;
  members?: SurveyMember[];
}

/** Step 2 — Thông tin đơn vị được khảo sát. */
export interface SurveyStep2Data {
  unit_name?: string;
  address?: string;
  tax_code?: string;
  parent_org?: string;
  members?: SurveyContactMember[];
}

/** Step 3 — Hiện trạng hoạt động. */
export interface SurveyStep3Data {
  unit_types?: string[];
  main_activities?: string[];
  operation_scope?: string;
  parent_unit?: string;
  sub_units?: string;
  legal_documents?: SurveyLegalDocument[];
  staff_count?: number | null;
  responsible_staff?: SurveyMember[];
  report_tool?: string[];
  report_send_method?: string[];
}

/** Step 4 — Hạ tầng CNTT. */
export interface SurveyStep4Data {
  has_software?: boolean | null;
  software_list?: SurveySoftwareItem[];
  desktop_count?: number | null;
  laptop_count?: number | null;
  server_description?: string;
  network_types?: string[];
  bandwidth?: string;
  security_measures?: string[];
  security_notes?: string;
}

/** Step 5 — Nhu cầu quản lý. */
export interface SurveyStep5Data {
  info_needs?: string[];
  search_criteria?: string[];
  map_requirements?: string[];
  digitize_processes?: string;
  required_reports?: string;
  required_lookups?: string;
}

/** Step 6 — Yêu cầu phần mềm. */
export interface SurveyStep6Data {
  features?: string[];
  admin_features?: string[];
  external_integrations?: string;
  utilities?: string[];
  platforms?: string[];
  other_notes?: string;
}

/** Step 7 — Ý kiến đề xuất. */
export interface SurveyStep7Data {
  difficulties?: string;
  advantages?: string;
  proposals?: string;
}

/** Xác nhận. */
export interface SurveyConfirmerData {
  name?: string;
  title?: string;
  reviewer_name?: string;
  reviewer_title?: string;
  confirmed_date?: string | null; // ISO date string
}

/** Parse JSON string an toàn — fallback object rỗng nếu lỗi. */
export function parseStepJson<T extends object>(raw: string | null | undefined): T {
  if (!raw || raw.trim().length === 0) return {} as T;
  try {
    const obj = JSON.parse(raw);
    return obj && typeof obj === 'object' ? (obj as T) : ({} as T);
  } catch {
    return {} as T;
  }
}

/** Serialize step object → JSON string (compact). */
export function stringifyStep(obj: object | null | undefined): string {
  if (!obj) return '{}';
  return JSON.stringify(obj);
}
