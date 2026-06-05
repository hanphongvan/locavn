import type { HttmFacilityCreateRequest, HttmFacilityDto } from './httm-facility.model';

/** Light row trả từ public search (không có sensitive). */
export interface HttmPublicFacilityRow {
  id: string;
  name: string;
  httmType: string;
  status: string;
  provinceCode: string;
  districtCode: string | null;
  wardCode: string | null;
  addressDetail: string | null;
}

export interface HttmSubmitter {
  name: string;
  phone: string;
  email?: string | null;
  notes?: string | null;
}

export interface HttmSubmissionImage {
  url: string;
  imageType: 'exterior' | 'interior' | 'infrastructure' | 'other';
  caption?: string | null;
  takenDate?: string | null;
  sortOrder?: number;
}

export interface HttmSubmissionLicense {
  licenseType: 'business' | 'fire_protection' | 'food_safety' | 'other';
  licenseNumber?: string | null;
  issuedDate?: string | null;
  expiryDate?: string | null;
  issuedBy?: string | null;
  fileUrl?: string | null;
  notes?: string | null;
}

/** Body POST /api/public/httm/facility-submissions. */
export interface HttmSubmissionCreateRequest {
  facilityId?: string | null;
  payload: HttmFacilityCreateRequest;
  images?: HttmSubmissionImage[];
  licenses?: HttmSubmissionLicense[];
  submitter: HttmSubmitter;
}

export interface HttmSubmissionListItem {
  id: string;
  facilityId: string | null;
  submissionType: 'update' | 'create_new';
  status: 'pending' | 'approved' | 'rejected';
  name: string;
  httmType: string | null;
  provinceCode: string | null;
  wardCode: string | null;
  submitterName: string;
  submitterPhone: string;
  submitterEmail: string | null;
  submittedAt: string;
  reviewedBy: string | null;
  reviewedAt: string | null;
  mergedFacilityId: string | null;
}

export interface HttmSubmissionListPage {
  totalCount: number;
  items: HttmSubmissionListItem[];
}

export interface HttmSubmissionDetail {
  id: string;
  facilityId: string | null;
  submissionType: 'update' | 'create_new';
  status: 'pending' | 'approved' | 'rejected';
  proposed: HttmFacilityCreateRequest;
  /** Ảnh user đính kèm khi submit. */
  proposedImages: HttmSubmissionImage[];
  /** Giấy phép user đính kèm khi submit. */
  proposedLicenses: HttmSubmissionLicense[];
  current: HttmFacilityDto | null;
  submitter: HttmSubmitter;
  submittedAt: string;
  submitterIp: string | null;
  reviewedBy: string | null;
  reviewedAt: string | null;
  reviewNotes: string | null;
  mergedFacilityId: string | null;
}

export interface HttmSubmissionApproveRequest {
  notes?: string | null;
}

export interface HttmSubmissionRejectRequest {
  reason: string;
}

export interface HttmSubmissionReviewResult {
  submissionId: string;
  status: string;
  mergedFacilityId: string | null;
}

/** 1 dòng danh sách public đề xuất bị từ chối (lọc theo SĐT). Không có thông tin người gửi. */
export interface HttmPublicRejectedSubmission {
  id: string;
  submissionType: 'update' | 'create_new';
  name: string;
  httmType: string | null;
  provinceCode: string | null;
  wardCode: string | null;
  submittedAt: string;
  reviewedAt: string | null;
  reviewNotes: string | null;
}

/** Chi tiết public đề xuất bị từ chối để pre-fill form sửa lại. Không có thông tin người gửi. */
export interface HttmPublicRejectedDetail {
  id: string;
  submissionType: 'update' | 'create_new';
  facilityId: string | null;
  proposed: HttmFacilityCreateRequest;
  proposedImages: HttmSubmissionImage[];
  proposedLicenses: HttmSubmissionLicense[];
  reviewNotes: string | null;
}
