import { Component, input } from '@angular/core';
import { RouterLink } from '@angular/router';

import type { StoreAdminFuelProductTreeNodeDto } from '../models/store-admin-fuel-product.models';

@Component({
  selector: 'app-fuel-product-tree-view',
  standalone: true,
  imports: [RouterLink, FuelProductTreeViewComponent],
  templateUrl: './fuel-product-tree-view.component.html',
  styleUrl: './fuel-product-tree-view.component.scss',
})
export class FuelProductTreeViewComponent {
  readonly nodes = input.required<StoreAdminFuelProductTreeNodeDto[]>();
}
