/** Khớp `AppFeedbackCategory` backend (0=Bug,1=Suggestion,2=Other). */
export const APP_FEEDBACK_CATEGORY_LABELS: Record<number, string> = {
  0: 'Báo lỗi',
  1: 'Đề xuất',
  2: 'Khác',
};

/** Khớp `AppFeedbackStatus` backend (0=Pending,1=UnderReview,2=Resolved). */
export const APP_FEEDBACK_STATUS_LABELS: Record<number, string> = {
  0: 'Chờ xử lý',
  1: 'Đang xử lý',
  2: 'Đã xử lý',
};

export interface AppFeedbackImage {
  readonly id: number;
  readonly imageUrl: string;
}

export interface AppFeedbackListItem {
  readonly id: number;
  readonly category: number;
  readonly content: string;
  readonly contactEmail: string | null;
  readonly contactPhone: string | null;
  readonly appVersion: string | null;
  readonly platform: string | null;
  readonly fromAuthenticatedUser: boolean;
  readonly createdAt: string;
  readonly status: number;
  readonly imageCount: number;
}

export interface AppFeedbackPage {
  readonly items: AppFeedbackListItem[];
  readonly totalCount: number;
  readonly skip: number;
  readonly take: number;
}

export interface AppFeedbackDetail {
  readonly id: number;
  readonly category: number;
  readonly content: string;
  readonly contactEmail: string | null;
  readonly contactPhone: string | null;
  readonly appVersion: string | null;
  readonly platform: string | null;
  readonly userId: string | null;
  readonly createdAt: string;
  readonly status: number;
  readonly images: AppFeedbackImage[];
}
