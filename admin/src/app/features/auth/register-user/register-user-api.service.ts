import { HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';

import { ApiHttpService } from '../../../core/http/api-http.service';
import type {
  RegisterDonViOptionDto,
  RegisterRoleOptionDto,
  RegisterUserNameCheckDto,
  RegisterUserRequest,
  RegisterUserResponse,
} from './register-user.models';

@Injectable({ providedIn: 'root' })
export class RegisterUserApiService {
  private readonly api = inject(ApiHttpService);

  getRoles() {
    return this.api.get<RegisterRoleOptionDto[]>('api/auth/register-user/roles');
  }

  getDonVis() {
    return this.api.get<RegisterDonViOptionDto[]>('api/auth/register-user/donvis');
  }

  checkUsername(username: string) {
    const params = new HttpParams().set('username', username);
    return this.api.get<RegisterUserNameCheckDto>('api/auth/register-user/check-username', params);
  }

  register(body: RegisterUserRequest) {
    return this.api.post<RegisterUserResponse>('api/auth/register-user', body);
  }
}
