import type { Routes } from '@angular/router';

export const FUEL_PRODUCTS_ROUTES: Routes = [
  {
    path: '',
    loadComponent: () => import('./fuel-products-shell.component').then((m) => m.FuelProductsShellComponent),
    children: [
      {
        path: '',
        loadComponent: () =>
          import('./fuel-product-tree-list-page.component').then((m) => m.FuelProductTreeListPageComponent),
      },
      {
        path: 'new',
        loadComponent: () => import('./fuel-product-form-page.component').then((m) => m.FuelProductFormPageComponent),
      },
      {
        path: ':id/edit',
        loadComponent: () => import('./fuel-product-form-page.component').then((m) => m.FuelProductFormPageComponent),
      },
    ],
  },
];
