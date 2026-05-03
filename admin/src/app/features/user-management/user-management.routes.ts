import type { Routes } from '@angular/router';

export const USER_MANAGEMENT_ROUTES: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./user-management-page.component').then((m) => m.UserManagementPageComponent),
  },
  {
    path: 'new',
    loadComponent: () =>
      import('./user-management-form.component').then((m) => m.UserManagementFormComponent),
    data: { mode: 'create' as const },
  },
  {
    path: ':id',
    loadComponent: () =>
      import('./user-management-form.component').then((m) => m.UserManagementFormComponent),
    data: { mode: 'edit' as const },
  },
];
