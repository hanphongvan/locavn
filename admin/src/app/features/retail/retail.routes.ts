import type { Routes } from '@angular/router';

import {
  ADMIN_PORTAL_ROLES_ONLY,
  HTTM_PORTAL_ROLES,
  RETAIL_PORTAL_ROLES,
  SURVEY_PORTAL_ROLES,
} from '../../core/auth/portal-route-roles.config';
import { portalRoleGuard } from '../../core/guards/portal-role.guard';

const retailData = { portalRoles: RETAIL_PORTAL_ROLES };
const httmData = { portalRoles: HTTM_PORTAL_ROLES };
const surveysData = { portalRoles: SURVEY_PORTAL_ROLES };
const fuelCatalogAdminData = { portalRoles: ADMIN_PORTAL_ROLES_ONLY };
/** `/inventory-map` — chỉ Admin (`Loai === 1`); đồng bộ mục sidebar `Bản đồ tồn kho`. */
const inventoryMapAdminData = { portalRoles: ADMIN_PORTAL_ROLES_ONLY };
/** `/app-feedback` — chỉ Admin xem góp ý ứng dụng. */
const appFeedbackAdminData = { portalRoles: ADMIN_PORTAL_ROLES_ONLY };

/** Store / inventory / pricing: all portal roles; fuel product CRUD UI is ADMIN-only (GET still used from hubs). */
export const RETAIL_SHELL_ROUTES: Routes = [
  {
    path: 'httm',
    canActivate: [portalRoleGuard],
    data: httmData,
    loadChildren: () => import('../httm/httm.routes').then((m) => m.HTTM_ROUTES),
  },
  {
    path: 'surveys',
    canActivate: [portalRoleGuard],
    data: surveysData,
    loadChildren: () => import('../surveys/surveys.routes').then((m) => m.SURVEYS_ROUTES),
  },
  {
    path: 'stores',
    canActivate: [portalRoleGuard],
    data: retailData,
    loadChildren: () => import('../stores/stores.routes').then((m) => m.STORES_ROUTES),
  },
  {
    path: 'fuel-products',
    canActivate: [portalRoleGuard],
    data: fuelCatalogAdminData,
    loadChildren: () => import('../fuel-products/fuel-products.routes').then((m) => m.FUEL_PRODUCTS_ROUTES),
  },
  {
    path: 'users',
    canActivate: [portalRoleGuard],
    data: fuelCatalogAdminData,
    loadChildren: () =>
      import('../user-management/user-management.routes').then((m) => m.USER_MANAGEMENT_ROUTES),
  },
  {
    path: 'demo-data',
    canActivate: [portalRoleGuard],
    data: fuelCatalogAdminData,
    loadComponent: () => import('../demo-data/demo-data-page.component').then((m) => m.DemoDataPageComponent),
  },
  {
    path: 'store-prices',
    canActivate: [portalRoleGuard],
    data: retailData,
    loadChildren: () => import('../store-prices/store-prices.routes').then((m) => m.STORE_PRICES_ROUTES),
  },
  {
    path: 'inventory-transactions',
    canActivate: [portalRoleGuard],
    data: retailData,
    loadChildren: () =>
      import('../inventory-transactions/inventory-transactions.routes').then(
        (m) => m.INVENTORY_TRANSACTIONS_ROUTES,
      ),
  },
  {
    path: 'inventory-current',
    canActivate: [portalRoleGuard],
    data: retailData,
    loadComponent: () =>
      import('../inventory-current/inventory-current-page.component').then(
        (m) => m.InventoryCurrentPageComponent,
      ),
  },
  {
    path: 'inventory-map',
    canActivate: [portalRoleGuard],
    data: inventoryMapAdminData satisfies { portalRoles: typeof ADMIN_PORTAL_ROLES_ONLY },
    loadComponent: () =>
      import('../inventory-map/inventory-map-page.component').then((m) => m.InventoryMapPageComponent),
  },
  {
    path: 'app-feedback',
    canActivate: [portalRoleGuard],
    data: appFeedbackAdminData,
    loadComponent: () =>
      import('../app-feedback/pages/app-feedback-list-page.component').then(
        (m) => m.AppFeedbackListPageComponent,
      ),
  },
];
