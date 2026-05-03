export interface RegisterRoleOptionDto {
  id: string;
  name: string;
}

export interface RegisterDonViOptionDto {
  id: number;
  ma: string;
  name: string;
}

export interface RegisterUserNameCheckDto {
  userName: string;
  taken: boolean;
}

export interface RoleSelectionDto {
  id: string;
  name: string;
  checked: boolean;
}

export interface DonViSelectionDto {
  id: number;
  name: string;
  checked: boolean;
}

export interface RegisterUserRequest {
  userName: string;
  displayName: string;
  password: string;
  confirmPassword: string;
  email: string | null;
  phone: string | null;
  address: string | null;
  isActived: boolean;
  loai: number;
  donViId: number | null;
  roles: RoleSelectionDto[];
  dVs: DonViSelectionDto[];
}

export interface RegisterUserResponse {
  userId: string;
  userName: string;
}
