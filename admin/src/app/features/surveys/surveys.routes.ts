import type { Routes } from '@angular/router';

export const SURVEYS_ROUTES: Routes = [
  {
    path: '',
    loadComponent: () => import('./surveys-shell.component').then((m) => m.SurveysShellComponent),
    children: [
      {
        path: '',
        loadComponent: () =>
          import('./pages/survey-list-page.component').then((m) => m.SurveyListPageComponent),
      },
      {
        path: ':id',
        loadComponent: () =>
          import('./pages/survey-detail-page.component').then((m) => m.SurveyDetailPageComponent),
      },
    ],
  },
];
