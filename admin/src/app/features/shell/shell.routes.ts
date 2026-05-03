import type { Routes } from '@angular/router';

import { DASHBOARD_ROUTES } from '../dashboards/dashboards.routes';
import { RETAIL_SHELL_ROUTES } from '../retail/retail.routes';

/**
 * Authenticated shell children: dashboards (per role) + retail ops.
 */
export const SHELL_CHILD_ROUTES: Routes = [
  { path: '', pathMatch: 'full', redirectTo: 'dashboard' },
  ...DASHBOARD_ROUTES,
  ...RETAIL_SHELL_ROUTES,
];
