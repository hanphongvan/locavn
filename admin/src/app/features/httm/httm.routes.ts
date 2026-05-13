import type { Routes } from '@angular/router';

import { httmScopeGuard } from './guards/httm-scope.guard';

export const HTTM_ROUTES: Routes = [
  {
    path: '',
    canActivate: [httmScopeGuard],
    loadComponent: () => import('./httm-shell.component').then((m) => m.HttmShellComponent),
    children: [
      {
        path: '',
        loadComponent: () => import('./pages/httm-list-page.component').then((m) => m.HttmListPageComponent),
      },
      {
        path: 'map',
        loadComponent: () => import('./pages/httm-map-page.component').then((m) => m.HttmMapPageComponent),
      },
      {
        path: 'new',
        loadComponent: () => import('./pages/httm-create-page.component').then((m) => m.HttmCreatePageComponent),
      },
      {
        path: ':id',
        loadComponent: () => import('./pages/httm-detail-page.component').then((m) => m.HttmDetailPageComponent),
      },
    ],
  },
];
