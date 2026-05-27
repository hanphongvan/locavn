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
        pathMatch: 'full',
        redirectTo: 'dashboard',
      },
      {
        path: 'hoso',
        loadComponent: () => import('./pages/httm-list-page.component').then((m) => m.HttmListPageComponent),
      },
      {
        path: 'dashboard',
        loadComponent: () =>
          import('./pages/httm-dashboard-page.component').then((m) => m.HttmDashboardPageComponent),
      },
      {
        path: 'map',
        loadComponent: () => import('./pages/httm-map-page.component').then((m) => m.HttmMapPageComponent),
      },
      {
        path: 'analytics',
        loadComponent: () =>
          import('./pages/httm-analytics-page.component').then((m) => m.HttmAnalyticsPageComponent),
      },
      {
        path: 'report-templates',
        loadComponent: () =>
          import('./pages/httm-report-templates-page.component').then((m) => m.HttmReportTemplatesPageComponent),
      },
      {
        path: 'new',
        loadComponent: () => import('./pages/httm-create-page.component').then((m) => m.HttmCreatePageComponent),
      },
      {
        path: 'import',
        loadComponent: () =>
          import('./pages/httm-import-page.component').then((m) => m.HttmImportPageComponent),
      },
      {
        path: 'submissions',
        loadComponent: () =>
          import('./pages/httm-submissions-list-page.component').then((m) => m.HttmSubmissionsListPageComponent),
      },
      {
        path: 'submissions/:id',
        loadComponent: () =>
          import('./pages/httm-submission-detail-page.component').then((m) => m.HttmSubmissionDetailPageComponent),
      },
      {
        path: ':id',
        loadComponent: () => import('./pages/httm-detail-page.component').then((m) => m.HttmDetailPageComponent),
      },
    ],
  },
];
