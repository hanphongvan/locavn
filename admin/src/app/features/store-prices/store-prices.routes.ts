import type { Routes } from '@angular/router';

export const STORE_PRICES_ROUTES: Routes = [
  {
    path: '',
    loadComponent: () => import('./store-prices-shell.component').then((m) => m.StorePricesShellComponent),
    children: [
      {
        path: '',
        loadComponent: () =>
          import('./store-price-hub-page.component').then((m) => m.StorePriceHubPageComponent),
      },
      {
        path: 'new',
        loadComponent: () =>
          import('./store-price-form-page.component').then((m) => m.StorePriceFormPageComponent),
      },
      {
        path: 'price-boards/:boardId/edit',
        loadComponent: () =>
          import('./store-price-form-page.component').then((m) => m.StorePriceFormPageComponent),
      },
      {
        path: ':id/edit',
        loadComponent: () =>
          import('./store-price-form-page.component').then((m) => m.StorePriceFormPageComponent),
      },
    ],
  },
];
