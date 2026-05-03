/** DTOs aligned with backend `Features/Admin/UserManagement/Contracts`. */

export interface UserListItemDto {
  id: string;
  userName: string;
  displayName: string | null;
  loai: number | null;
  loaiLabel: string | null;
  donViId: number | null;
  donViDisplayName: string | null;
  isLocked: boolean;
}

export interface UserListPageDto {
  items: UserListItemDto[];
  totalCount: number;
  skip: number;
  take: number;
}

export interface UserRoleAssignmentDto {
  roleId: string;
  roleName: string | null;
}

export interface UserDonViAssignmentDto {
  donViId: number;
  ma: string | null;
  ten: string | null;
}

export interface UserDetailDto {
  id: string;
  userName: string;
  fullName: string | null;
  displayName: string | null;
  email: string | null;
  phone: string | null;
  address: string | null;
  description: string | null;
  isLocked: boolean;
  donViId: number | null;
  donViDisplayName: string | null;
  loai: number | null;
  loaiLabel: string | null;
  roles: UserRoleAssignmentDto[];
  donVis: UserDonViAssignmentDto[];
}

export interface UserCreateRequest {
  userName: string;
  displayName?: string | null;
  fullName?: string | null;
  email?: string | null;
  phone?: string | null;
  address?: string | null;
  description?: string | null;
  password: string;
  donViId?: number | null;
  loai?: number | null;
  roleIds?: string[] | null;
  donViIds?: number[] | null;
}

export interface UserUpdateRequest {
  displayName?: string | null;
  fullName?: string | null;
  email?: string | null;
  phone?: string | null;
  address?: string | null;
  description?: string | null;
  password?: string | null;
  donViId?: number | null;
  loai?: number | null;
  roleIds?: string[] | null;
  donViIds?: number[] | null;
}

export interface UserBulkIdsRequest {
  userIds: string[];
}

export interface UserLockUnlockResultDto {
  affected: number;
}

export interface UserSyncResultDto {
  message: string;
}

export interface RoleOptionDto {
  id: string;
  name: string;
}

export interface DonViOptionDto {
  id: number;
  ma: string;
  ten: string;
}
