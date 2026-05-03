/** Thrown when `Loai` is not one of the values allowed for this admin application. */
export class PortalRoleUnauthorizedError extends Error {
  readonly code = 'PORTAL_ROLE_UNAUTHORIZED' as const;

  constructor() {
    super(
      'Tài khoản không có vai trò được phép truy cập ứng dụng quản trị (Loai không hợp lệ).',
    );
    this.name = 'PortalRoleUnauthorizedError';
  }
}

export function isPortalRoleUnauthorizedError(err: unknown): err is PortalRoleUnauthorizedError {
  return err instanceof PortalRoleUnauthorizedError;
}
