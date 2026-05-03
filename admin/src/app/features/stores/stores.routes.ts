import type { Routes } from '@angular/router';

import { ADMIN_PORTAL_ROLES_ONLY } from '../../core/auth/portal-route-roles.config';
import { portalRoleGuard } from '../../core/guards/portal-role.guard';

export const STORES_ROUTES: Routes = [
  {
    path: '',
    loadComponent: () => import('./stores-shell.component').then((m) => m.StoresShellComponent),
    children: [
      {
        path: '',
        loadComponent: () => import('./store-list-page.component').then((m) => m.StoreListPageComponent),
      },
      {
        path: 'new',
        canActivate: [portalRoleGuard],
        data: { portalRoles: ADMIN_PORTAL_ROLES_ONLY },
        loadComponent: () => import('./store-form-page.component').then((m) => m.StoreFormPageComponent),
      },
      {
        path: ':id/edit',
        loadComponent: () => import('./store-form-page.component').then((m) => m.StoreFormPageComponent),
      },
    ],
  },
];
