import { CommonModule } from '@angular/common';
import { Component, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { combineLatest, EMPTY, of } from 'rxjs';
import { catchError, finalize, switchMap, tap } from 'rxjs/operators';

import { ApiRequestError } from '../../core/http/api-request-error';
import type {
  StoreAdminFuelProductDetailDto,
  StoreAdminFuelProductTreeNodeDto,
  StoreAdminFuelProductUpsertRequest,
} from './models/store-admin-fuel-product.models';
import { FuelProductsApiService } from './services/fuel-products-api.service';
import { FUEL_PRODUCT_FIELD_MAX } from './fuel-product-form.constants';
import {
  collectSubtreeIds,
  findTreeNode,
  flattenFuelProductTreeForSelect,
  parentMapFromTree,
  parentWouldCreateCycle,
} from './fuel-product-tree.utils';

function strOrNull(s: string | null | undefined): string | null {
  if (s === null || s === undefined) {
    return null;
  }
  const t = String(s).trim();
  return t === '' ? null : t;
}

function parseNullableInt(v: unknown): number | null {
  if (v === null || v === undefined || v === '') {
    return null;
  }
  const n = typeof v === 'number' ? v : Number(v);
  return Number.isFinite(n) ? n : null;
}

@Component({
  selector: 'app-fuel-product-form-page',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: './fuel-product-form-page.component.html',
})
export class FuelProductFormPageComponent {
  private readonly fb = inject(FormBuilder);
  private readonly api = inject(FuelProductsApiService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);

  readonly FIELD_MAX = FUEL_PRODUCT_FIELD_MAX;

  readonly loading = signal(false);
  readonly saving = signal(false);
  readonly errorMessage = signal<string | null>(null);
  readonly fuelProductId = signal<number | null>(null);

  readonly parentRows = signal<{ id: number; label: string }[]>([]);
  private parentByProductId = new Map<number, number | null>();

  readonly form = this.fb.group({
    code: ['', [Validators.required, Validators.maxLength(FUEL_PRODUCT_FIELD_MAX.code)]],
    name: ['', [Validators.required, Validators.maxLength(FUEL_PRODUCT_FIELD_MAX.name)]],
    parentId: this.fb.control<number | null>(null),
    unitId: this.fb.control<number | null>(null),
    isActive: this.fb.nonNullable.control(true),
    sortOrder: this.fb.control<number | null>(null),
    description: ['', [Validators.maxLength(FUEL_PRODUCT_FIELD_MAX.description)]],
  });

  constructor() {
    this.form.controls.parentId.valueChanges.pipe(takeUntilDestroyed()).subscribe(() => {
      const c = this.form.controls.parentId;
      if (c.hasError('cycle')) {
        c.setErrors(null);
      }
    });

    combineLatest([this.route.paramMap, this.route.queryParamMap])
      .pipe(
        tap(() => this.errorMessage.set(null)),
        switchMap(([pm, qm]) => {
          const idStr = pm.get('id');
          const editId = idStr && idStr !== '' ? Number(idStr) : null;
          const validEdit = editId !== null && Number.isFinite(editId) ? editId : null;
          this.fuelProductId.set(validEdit);

          this.loading.set(true);
          return this.api.getTree().pipe(
            switchMap((tree) => {
              this.parentByProductId = parentMapFromTree(tree);
              this.parentRows.set(this.buildParentSelectRows(validEdit, tree));

              if (validEdit !== null) {
                return this.api.getById(validEdit).pipe(
                  tap((d) => this.patchFromDetail(d)),
                  catchError((err: unknown) => {
                    this.errorMessage.set(
                      err instanceof ApiRequestError ? err.message : 'Không tải được mặt hàng.',
                    );
                    return EMPTY;
                  }),
                );
              }

              this.resetForCreate();
              const pq = qm.get('parentId');
              const p = pq && pq !== '' ? Number(pq) : null;
              if (p !== null && Number.isFinite(p)) {
                const allowed = this.parentRows().some((r) => r.id === p);
                if (allowed) {
                  this.form.patchValue({ parentId: p });
                }
              }
              return of(null);
            }),
            finalize(() => this.loading.set(false)),
            catchError((err: unknown) => {
              this.errorMessage.set(err instanceof ApiRequestError ? err.message : 'Không tải được cây mặt hàng.');
              this.parentRows.set([]);
              return EMPTY;
            }),
          );
        }),
        takeUntilDestroyed(),
      )
      .subscribe();
  }

  isEditMode(): boolean {
    return this.fuelProductId() !== null;
  }

  pageTitle(): string {
    return this.isEditMode() ? 'Sửa mặt hàng' : 'Thêm mặt hàng';
  }

  submit(): void {
    this.form.markAllAsTouched();
    const editId = this.fuelProductId();
    const parentId = this.form.getRawValue().parentId;
    if (editId !== null && parentId !== null) {
      if (parentWouldCreateCycle(editId, parentId, this.parentByProductId)) {
        this.form.controls.parentId.setErrors({ cycle: true });
        return;
      }
    }
    if (this.form.invalid) {
      return;
    }

    const body = this.buildUpsertRequest();
    this.saving.set(true);
    this.errorMessage.set(null);
    const req$ =
      editId !== null ? this.api.update(editId, body) : this.api.create(body);
    req$.pipe(finalize(() => this.saving.set(false))).subscribe({
      next: () => void this.router.navigateByUrl('/fuel-products'),
      error: (err: unknown) => {
        this.errorMessage.set(err instanceof ApiRequestError ? err.message : 'Lưu thất bại.');
      },
    });
  }

  cancel(): void {
    void this.router.navigateByUrl('/fuel-products');
  }

  private resetForCreate(): void {
    this.form.reset({
      code: '',
      name: '',
      parentId: null,
      unitId: null,
      isActive: true,
      sortOrder: null,
      description: '',
    });
  }

  private patchFromDetail(d: StoreAdminFuelProductDetailDto): void {
    this.form.patchValue({
      code: d.code,
      name: d.name,
      parentId: d.parentId,
      unitId: d.unitId,
      isActive: d.isActive,
      sortOrder: d.sortOrder,
      description: d.description ?? '',
    });
  }

  private buildParentSelectRows(
    editId: number | null,
    tree: StoreAdminFuelProductTreeNodeDto[],
  ): { id: number; label: string }[] {
    const flat = flattenFuelProductTreeForSelect(tree);
    if (editId === null) {
      return flat;
    }
    const node = findTreeNode(tree, editId);
    if (!node) {
      return flat;
    }
    const ex = collectSubtreeIds(node);
    return flat.filter((r) => !ex.has(r.id));
  }

  private buildUpsertRequest(): StoreAdminFuelProductUpsertRequest {
    const v = this.form.getRawValue();
    return {
      code: (v.code ?? '').trim(),
      name: (v.name ?? '').trim(),
      parentId: v.parentId,
      unitId: parseNullableInt(v.unitId),
      isActive: v.isActive,
      sortOrder: parseNullableInt(v.sortOrder),
      description: strOrNull(v.description),
    };
  }
}
