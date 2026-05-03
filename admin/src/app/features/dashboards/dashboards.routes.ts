import type { Routes } from '@angular/router';

import {
  ADMIN_PORTAL_ROLES_ONLY,
  ALL_PORTAL_ROLES,
  STORE_PORTAL_ROLES_ONLY,
  TRADER_PORTAL_ROLES_ONLY,
} from '../../core/auth/portal-route-roles.config';
import { portalRoleGuard } from '../../core/guards/portal-role.guard';

/**
 * Three dashboards under `/dashboard/{admin|trader|store}` — one component per role scope.
 * Parent path has no component; each leaf enforces `portalRoleGuard` + `data.portalRoles`.
 */
export const DASHBOARD_ROUTES: Routes = [
  {
    path: 'dashboard',
    children: [
      {
        path: '',
        pathMatch: 'full',
        canActivate: [portalRoleGuard],
        data: { portalRoles: ALL_PORTAL_ROLES },
        loadComponent: () =>
          import('../dashboard/dashboard-redirect.component').then((m) => m.DashboardRedirectComponent),
      },
      {
        path: 'admin',
        canActivate: [portalRoleGuard],
        data: { portalRoles: ADMIN_PORTAL_ROLES_ONLY },
        loadComponent: () =>
          import('./admin-dashboard-page.component').then((m) => m.AdminDashboardPageComponent),
      },
      {
        path: 'trader',
        canActivate: [portalRoleGuard],
        data: { portalRoles: TRADER_PORTAL_ROLES_ONLY },
        loadComponent: () =>
          import('./trader-dashboard-page.component').then((m) => m.TraderDashboardPageComponent),
      },
      {
        path: 'store',
        canActivate: [portalRoleGuard],
        data: { portalRoles: STORE_PORTAL_ROLES_ONLY },
        loadComponent: () =>
          import('./store-dashboard-page.component').then((m) => m.StoreDashboardPageComponent),
      },
    ],
  },
];
