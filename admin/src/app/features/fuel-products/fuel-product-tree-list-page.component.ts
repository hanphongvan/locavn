import { CommonModule } from '@angular/common';
import { Component, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { RouterLink } from '@angular/router';
import { Subject, switchMap, tap } from 'rxjs';
import { finalize } from 'rxjs/operators';

import { ApiRequestError } from '../../core/http/api-request-error';
import { FuelProductTreeViewComponent } from './components/fuel-product-tree-view.component';
import type {
  StoreAdminFuelProductListItemDto,
  StoreAdminFuelProductListPageDto,
  StoreAdminFuelProductTreeNodeDto,
} from './models/store-admin-fuel-product.models';
import { FuelProductsApiService } from './services/fuel-products-api.service';
import { FUEL_PRODUCT_LIST_DEFAULT_TAKE, FUEL_PRODUCT_LIST_MAX_TAKE } from './fuel-product-form.constants';

@Component({
  selector: 'app-fuel-product-tree-list-page',
  standalone: true,
  imports: [CommonModule, RouterLink, FuelProductTreeViewComponent],
  templateUrl: './fuel-product-tree-list-page.component.html',
  styleUrl: './fuel-product-tree-list-page.component.scss',
})
export class FuelProductTreeListPageComponent {
  private readonly api = inject(FuelProductsApiService);
  private readonly refreshTree$ = new Subject<void>();
  private readonly refreshList$ = new Subject<void>();

  readonly view = signal<'tree' | 'list'>('tree');

  readonly tree = signal<StoreAdminFuelProductTreeNodeDto[]>([]);
  readonly treeLoading = signal(false);
  readonly treeError = signal<string | null>(null);

  readonly listItems = signal<StoreAdminFuelProductListItemDto[]>([]);
  readonly listTotal = signal(0);
  readonly listSkip = signal(0);
  readonly listTake = signal(FUEL_PRODUCT_LIST_DEFAULT_TAKE);
  readonly listLoading = signal(false);
  readonly listError = signal<string | null>(null);

  readonly takeOptions = [25, 50, 100, 200] as const;

  constructor() {
    this.refreshTree$
      .pipe(
        tap(() => {
          this.treeLoading.set(true);
          this.treeError.set(null);
        }),
        switchMap(() => this.api.getTree().pipe(finalize(() => this.treeLoading.set(false)))),
        takeUntilDestroyed(),
      )
      .subscribe({
        next: (nodes) => this.tree.set(nodes),
        error: (err: unknown) => {
          this.tree.set([]);
          this.treeError.set(err instanceof ApiRequestError ? err.message : 'Không tải được cây mặt hàng.');
        },
      });

    this.refreshList$
      .pipe(
        tap(() => {
          this.listLoading.set(true);
          this.listError.set(null);
        }),
        switchMap(() =>
          this.api
            .list({ skip: this.listSkip(), take: this.listTake() })
            .pipe(finalize(() => this.listLoading.set(false))),
        ),
        takeUntilDestroyed(),
      )
      .subscribe({
        next: (page: StoreAdminFuelProductListPageDto) => {
          this.listItems.set(page.items);
          this.listTotal.set(page.totalCount);
          this.listSkip.set(page.skip);
          this.listTake.set(page.take);
        },
        error: (err: unknown) => {
          this.listItems.set([]);
          this.listError.set(err instanceof ApiRequestError ? err.message : 'Không tải được danh sách.');
        },
      });

    queueMicrotask(() => {
      this.refreshTree$.next();
      this.refreshList$.next();
    });
  }

  setView(mode: 'tree' | 'list'): void {
    this.view.set(mode);
  }

  reloadAll(): void {
    this.refreshTree$.next();
    this.refreshList$.next();
  }

  setTake(n: number): void {
    const v = Math.min(Math.max(1, n), FUEL_PRODUCT_LIST_MAX_TAKE);
    this.listTake.set(v);
    this.listSkip.set(0);
    this.refreshList$.next();
  }

  prevPage(): void {
    const next = Math.max(0, this.listSkip() - this.listTake());
    this.listSkip.set(next);
    this.refreshList$.next();
  }

  nextPage(): void {
    const next = this.listSkip() + this.listTake();
    if (next < this.listTotal()) {
      this.listSkip.set(next);
      this.refreshList$.next();
    }
  }

  listRangeLabel(): string {
    const total = this.listTotal();
    if (total === 0) {
      return 'Không có dòng';
    }
    const from = this.listSkip() + 1;
    const to = Math.min(this.listSkip() + this.listItems().length, total);
    return `${from}–${to} / ${total}`;
  }
}
