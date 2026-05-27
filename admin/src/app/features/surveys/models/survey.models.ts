export interface HttmSurveyDto {
  id: string;
  surveyCode: string;
  status: string;
  currentStep: number;
  step1Data: string;
  step2Data: string;
  step3Data: string;
  step4Data: string;
  step5Data: string;
  step6Data: string;
  step7Data: string;
  confirmerData: string;
  provinceCode: string;
  /** Có thể NULL — khảo sát chung của Sở (không gắn loại HTTM cụ thể). */
  httmType: string | null;
  linkedFacilityId: string | null;
  createdBy: string;
  submittedAt: string | null;
  reviewedBy: string | null;
  reviewedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface HttmSurveyListItemDto {
  id: string;
  surveyCode: string;
  status: string;
  provinceCode: string;
  /** Có thể NULL — xem {@link HttmSurveyDto.httmType}. */
  httmType: string | null;
  createdBy: string;
  createdAt: string;
  updatedAt: string;
}

export interface HttmSurveySearchPageDto {
  totalCount: number;
  items: HttmSurveyListItemDto[];
}

export interface HttmSurveySearchQuery {
  q?: string | null;
  status?: string | null;
  provinceCode?: string | null;
  httmType?: string | null;
  page?: number;
  pageSize?: number;
}

export interface HttmSurveyCreateRequest {
  /**
   * Loại HTTM — tuỳ chọn. NULL = khảo sát chung của Sở (không gắn loại cụ thể).
   * Tỉnh auto-derive từ tài khoản đăng nhập, không nhận từ client.
   */
  httmType?: string | null;
}

export interface HttmSurveyPatchRequest {
  currentStep?: number | null;
  step1Data?: string | null;
  step2Data?: string | null;
  step3Data?: string | null;
  step4Data?: string | null;
  step5Data?: string | null;
  step6Data?: string | null;
  step7Data?: string | null;
  confirmerData?: string | null;
}

export interface HttmSurveyHistoryDto {
  id: string;
  surveyId: string;
  fromStatus: string | null;
  toStatus: string;
  action: string;
  notes: string | null;
  /** AspNetUsers.Id — chỉ dùng cho debug / audit. UI nên hiển thị {@link performedByName}. */
  performedBy: string;
  /** DisplayName / UserName từ AspNetUsers. Fallback về `performedBy` nếu không join được. */
  performedByName: string;
  performedAt: string;
}
