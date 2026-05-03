import type { Routes } from '@angular/router';

export const INVENTORY_TRANSACTIONS_ROUTES: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./inventory-transactions-shell.component').then((m) => m.InventoryTransactionsShellComponent),
    children: [
      {
        path: '',
        loadComponent: () =>
          import('./inventory-transaction-hub-page.component').then((m) => m.InventoryTransactionHubPageComponent),
      },
      {
        path: 'new',
        loadComponent: () =>
          import('./inventory-transaction-form-page.component').then((m) => m.InventoryTransactionFormPageComponent),
      },
      {
        path: ':id/edit',
        loadComponent: () =>
          import('./inventory-transaction-form-page.component').then((m) => m.InventoryTransactionFormPageComponent),
      },
    ],
  },
];
