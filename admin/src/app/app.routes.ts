import { Routes } from '@angular/router';

import { storeAdminAuthGuard } from './core/guards/store-admin-auth.guard';
import { storeAdminGuestGuard } from './core/guards/store-admin-guest.guard';
import { SHELL_CHILD_ROUTES } from './features/shell/shell.routes';
import { AdminShellComponent } from './shared/layout/admin-shell/admin-shell.component';

export const routes: Routes = [
  {
    path: 'login',
    canActivate: [storeAdminGuestGuard],
    loadComponent: () => import('./features/auth/login-page.component').then((m) => m.LoginPageComponent),
  },
  {
    path: 'register',
    canActivate: [storeAdminGuestGuard],
    loadComponent: () =>
      import('./features/auth/register-user/register-user-page.component').then((m) => m.RegisterUserPageComponent),
  },
  {
    path: 'access-denied',
    loadComponent: () =>
      import('./features/auth/access-denied-page.component').then((m) => m.AccessDeniedPageComponent),
  },
  {
    path: 'public/map',
    loadComponent: () =>
      import('./features/public-map/public-httm-map-page.component').then((m) => m.PublicHttmMapPageComponent),
  },
  {
    path: 'public/facility-update',
    loadComponent: () =>
      import('./features/public-facility-update/public-facility-update-page.component').then(
        (m) => m.PublicFacilityUpdatePageComponent,
      ),
  },
  {
    path: '',
    component: AdminShellComponent,
    canActivate: [storeAdminAuthGuard],
    runGuardsAndResolvers: 'always',
    children: SHELL_CHILD_ROUTES,
  },
  /** Absolute so unknown paths always enter the guarded shell at `/dashboard` → role redirect. */
  { path: '**', redirectTo: '/dashboard' },
];
