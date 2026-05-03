import type { PortalRole } from './portal-loai-role';

/** `Route.data` key read by {@link portalRoleGuard}. */
export const PORTAL_ROLES_ROUTE_DATA_KEY = 'portalRoles' as const;

export type PortalRolesRouteData = {
  readonly [PORTAL_ROLES_ROUTE_DATA_KEY]?: readonly PortalRole[];
};
