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
  httmType: string;
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
  httmType: string;
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
  provinceCode: string;
  httmType: string;
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
  performedBy: string;
  performedAt: string;
}
