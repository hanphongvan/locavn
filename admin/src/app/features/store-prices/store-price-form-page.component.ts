import { CommonModule } from '@angular/common';
import { Component, computed, ElementRef, inject, signal, viewChildren } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { MatAutocompleteModule, MatAutocompleteSelectedEvent } from '@angular/material/autocomplete';
import { MatInputModule } from '@angular/material/input';
import {
  AbstractControl,
  FormArray,
  FormBuilder,
  FormGroup,
  ReactiveFormsModule,
  ValidationErrors,
  ValidatorFn,
  Validators,
} from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { combineLatest, forkJoin, of } from 'rxjs';
import { catchError, finalize, switchMap, tap } from 'rxjs/operators';

import { CurrentUserContextService } from '../../core/auth/current-user-context.service';
import { ApiRequestError } from '../../core/http/api-request-error';
import { retailPinnedDonViIdForStoreRole } from '../retail/retail-scope.util';
import type { StoreAdminStoreDto } from '../stores/models/store-admin-store.models';
import { StoresApiService } from '../stores/services/stores-api.service';
import type {
  StoreAdminDonViTinhLookupDto,
  StoreAdminFuelProductLookupDto,
  StoreAdminStationPriceBoardEditorResponseDto,
  StoreAdminStationPriceBoardEditorSaveRequest,
  StoreAdminStorePriceBatchCreateRequest,
  StoreAdminStorePriceDetailDto,
  StoreAdminStorePriceUpsertRequest,
} from './models/store-admin-store-price.models';
import { VnGroupedNumberInputDirective } from '../../shared/inputs/vn-grouped-number-input.directive';
import { StorePricesApiService } from './services/store-prices-api.service';
import { STORE_PRICE_LIST_MAX_TAKE, STORE_PRICE_NOTE_MAX } from './store-price.constants';

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

function pad2(n: number): string {
  return String(n).padStart(2, '0');
}

/** Thành phần lịch/giờ theo múi Asia/Ho_Chi_Minh (không phụ thuộc múi trình duyệt). */
function hcmPartsFromDate(d: Date): { day: string; month: string; year: string; hour: string; minute: string } {
  const parts = new Intl.DateTimeFormat('en-GB', {
    timeZone: 'Asia/Ho_Chi_Minh',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  }).formatToParts(d);
  const g = (t: Intl.DateTimeFormatPart['type']) => parts.find((p) => p.type === t)?.value ?? '';
  return { day: g('day'), month: g('month'), year: g('year'), hour: g('hour'), minute: g('minute') };
}

/** ISO từ API → hiển thị `dd/MM/yyyy HH:mm` theo giờ Việt Nam (đồng bộ với lưu CSDL). */
function isoToVnEffectiveDateTime(iso: string | null | undefined): string {
  if (!iso) {
    return '';
  }
  const d = new Date(String(iso));
  if (Number.isNaN(d.getTime())) {
    return '';
  }
  const { day, month, year, hour, minute } = hcmPartsFromDate(d);
  return `${day}/${month}/${year} ${hour}:${minute}`;
}

/** “Bây giờ” trên form ngày hiệu lực — luôn theo Asia/Ho_Chi_Minh (tránh toISOString() UTC làm lệch ngày). */
function vnWallNowEffectiveDisplay(): string {
  const { day, month, year, hour, minute } = hcmPartsFromDate(new Date());
  return `${day}/${month}/${year} ${hour}:${minute}`;
}

/**
 * Parse `dd/MM/yyyy HH:mm` (24h) theo giờ địa phương → chuỗi gửi API `yyyy-MM-ddTHH:mm:ss` (không hậu tố `Z`).
 * Cột SQL `datetime` là “giờ wall” nghiệp vụ; dùng `toISOString()` trước đây gửi UTC và làm lệch 7h (VN) trong DB.
 * Trả chuỗi rỗng nếu không khớp định dạng hoặc ngày giờ không tồn tại.
 */
function vnEffectiveDateTimeToIso(vn: string): string {
  const t = vn.trim();
  if (t === '') {
    return '';
  }
  const m = /^(\d{1,2})\/(\d{1,2})\/(\d{4})\s+(\d{1,2}):(\d{1,2})$/.exec(t);
  if (!m) {
    return '';
  }
  const day = Number(m[1]);
  const month = Number(m[2]);
  const year = Number(m[3]);
  const hour = Number(m[4]);
  const minute = Number(m[5]);
  if (month < 1 || month > 12 || day < 1 || day > 31 || hour > 23 || minute > 59) {
    return '';
  }
  const d = new Date(year, month - 1, day, hour, minute, 0, 0);
  if (
    d.getFullYear() !== year ||
    d.getMonth() !== month - 1 ||
    d.getDate() !== day ||
    d.getHours() !== hour ||
    d.getMinutes() !== minute
  ) {
    return '';
  }
  return `${year}-${pad2(month)}-${pad2(day)}T${pad2(hour)}:${pad2(minute)}:00`;
}

function vnEffectiveDateTimeValidator(): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    const v = String(control.value ?? '')
      .trim();
    if (v === '') {
      return null;
    }
    return vnEffectiveDateTimeToIso(v) === '' ? { vnDateTime: true } : null;
  };
}

function effectiveDisplayToApiIso(display: string): string {
  return vnEffectiveDateTimeToIso(display.trim());
}

function uniquePriceRowProductsValidator(): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    const arr = control as FormArray<FormGroup>;
    const ids: number[] = [];
    for (const c of arr.controls) {
      const pid = c.get('productId')?.value as number | null | undefined;
      if (pid !== null && pid !== undefined && Number.isFinite(pid)) {
        ids.push(pid);
      }
    }
    return new Set(ids).size === ids.length ? null : { duplicateProducts: true };
  };
}

@Component({
  selector: 'app-store-price-form-page',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    RouterLink,
    MatAutocompleteModule,
    MatInputModule,
    VnGroupedNumberInputDirective,
  ],
  templateUrl: './store-price-form-page.component.html',
  styleUrl: './store-price-form-page.component.scss',
})
export class StorePriceFormPageComponent {
  private readonly fb = inject(FormBuilder);
  private readonly prices = inject(StorePricesApiService);
  private readonly storesApi = inject(StoresApiService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly userContext = inject(CurrentUserContextService);

  readonly NOTE_MAX = STORE_PRICE_NOTE_MAX;

  readonly stores = signal<StoreAdminStoreDto[]>([]);
  readonly productCatalog = signal<StoreAdminFuelProductLookupDto[]>([]);
  readonly donViTinhOptions = signal<StoreAdminDonViTinhLookupDto[]>([]);
  readonly defaultProducts = signal<StoreAdminFuelProductLookupDto[]>([]);

  readonly productInputs = viewChildren<ElementRef<HTMLInputElement>>('rowProductInput');

  readonly loading = signal(false);
  readonly saving = signal(false);
  readonly loadingDefaults = signal(false);
  readonly loadingLatest = signal(false);
  readonly errorMessage = signal<string | null>(null);
  readonly priceId = signal<number | null>(null);
  /** Sửa cả bảng giá (StationPrices + các dòng) — route `price-boards/:boardId/edit`. */
  readonly stationPricesBoardId = signal<number | null>(null);
  /** Hiển thị tên cửa hàng khi sửa bảng giá (có thể khác DonViId trên profile). */
  readonly boardEditDisplayDonViId = signal<number | null>(null);

  readonly form = this.fb.group({
    donViId: this.fb.control<number | null>(null, [Validators.required]),
    /** Hiển thị + tìm mặt hàng (autocomplete); không gửi API. */
    productSearch: this.fb.nonNullable.control(''),
    productId: this.fb.control<number | null>(null, [Validators.required]),
    price: this.fb.control<number | null>(null, [Validators.required, Validators.min(0)]),
    unitId: this.fb.control<number | null>(null),
    effectiveDate: ['', [Validators.required, vnEffectiveDateTimeValidator()]],
    isCurrent: this.fb.nonNullable.control(false),
    note: ['', [Validators.maxLength(STORE_PRICE_NOTE_MAX)]],
  });

  readonly batchForm = this.fb.group({
    donViId: this.fb.control<number | null>(null, [Validators.required]),
    effectiveDate: ['', [Validators.required, vnEffectiveDateTimeValidator()]],
    isCurrent: this.fb.nonNullable.control(false),
    rows: this.fb.array<FormGroup>(
      [this.createPriceRow()],
      { validators: [Validators.minLength(1), uniquePriceRowProductsValidator()] },
    ),
  });

  readonly missingDefaultProductNames = computed(() => {
    const defs = this.defaultProducts();
    if (defs.length === 0) {
      return [] as string[];
    }
    const selected = new Set<number>();
    for (const g of this.batchRows.controls) {
      const v = g.get('productId')?.value as number | null;
      if (v !== null && v !== undefined && Number.isFinite(v)) {
        selected.add(v);
      }
    }
    return defs.filter((d) => !selected.has(d.id)).map((d) => `${d.code} — ${d.name}`);
  });

  /** Cửa hàng read-only: profile (thêm mới) hoặc bảng đang sửa (board editor). */
  readonly createBatchStoreSummary = computed(() => {
    const fromBoard = this.boardEditDisplayDonViId();
    const id =
      fromBoard !== null && fromBoard !== undefined && Number.isFinite(fromBoard)
        ? fromBoard
        : this.userContext.donViId();
    if (id === null || id === undefined || !Number.isFinite(id)) {
      return null;
    }
    const s = this.stores().find((x) => x.id === id);
    return s ? `${s.ma} — ${s.ten}` : `DonViId: ${id}`;
  });

  constructor() {
    forkJoin({
      stores: this.storesApi.list({ skip: 0, take: STORE_PRICE_LIST_MAX_TAKE }),
      products: this.prices.listProducts({ take: 500, defaultsOnly: false }),
      donViTinh: this.prices.listDonViTinh(),
    })
      .pipe(takeUntilDestroyed())
      .subscribe({
        next: ({ stores, products, donViTinh }) => {
          this.stores.set(stores.items);
          this.productCatalog.set(products);
          this.donViTinhOptions.set(donViTinh);
        },
        error: () => {
          this.stores.set([]);
          this.productCatalog.set([]);
          this.donViTinhOptions.set([]);
        },
      });

    combineLatest([this.route.paramMap, this.route.queryParamMap])
      .pipe(
        switchMap(([pm, qm]) => {
          const boardIdStr = pm.get('boardId');
          const boardIdNum = boardIdStr && boardIdStr !== '' ? Number(boardIdStr) : null;
          const boardId =
            boardIdNum !== null && Number.isFinite(boardIdNum) && boardIdNum >= 1 ? boardIdNum : null;

          this.errorMessage.set(null);
          this.loading.set(true);

          if (boardId !== null) {
            this.stationPricesBoardId.set(boardId);
            this.priceId.set(null);
            return this.prices.getPriceBoardEditor(boardId).pipe(
              tap((b) => this.patchFromBoardEditor(b)),
              catchError((err: unknown) => {
                this.errorMessage.set(
                  err instanceof ApiRequestError ? err.message : 'Không tải được bảng giá.',
                );
                return of(null);
              }),
              finalize(() => this.loading.set(false)),
            );
          }

          this.stationPricesBoardId.set(null);
          this.boardEditDisplayDonViId.set(null);

          const idStr = pm.get('id');
          const editId = idStr && idStr !== '' ? Number(idStr) : null;
          const validEdit = editId !== null && Number.isFinite(editId) ? editId : null;
          this.priceId.set(validEdit);

          if (validEdit !== null) {
            return this.prices.getById(validEdit).pipe(
              tap((d) => this.patchFromDetail(d)),
              catchError((err: unknown) => {
                this.errorMessage.set(
                  err instanceof ApiRequestError ? err.message : 'Không tải được bản ghi giá.',
                );
                return of(null);
              }),
              finalize(() => this.loading.set(false)),
            );
          }

          this.resetForCreate();
          const prefill = this.userContext.consumeStorePriceCreatePrefill();
          const pr = qm.get('productId');
          const productIdFromUrl = pr && pr !== '' ? Number(pr) : null;
          const productId =
            productIdFromUrl !== null && Number.isFinite(productIdFromUrl)
              ? productIdFromUrl
              : prefill.productId !== null && Number.isFinite(prefill.productId)
                ? prefill.productId
                : null;
          this.batchForm.patchValue({
            effectiveDate: vnWallNowEffectiveDisplay(),
          });
          this.batchRows.clear();
          this.batchRows.push(this.createPriceRow());
          if (productId !== null && Number.isFinite(productId)) {
            const row0 = this.batchRows.at(0);
            row0.patchValue({
              productId,
              productSearch: this.labelForProductId(productId),
            });
            this.applyDefaultUnitForProduct(row0, productId);
          }
          this.loading.set(false);
          return of(null);
        }),
        takeUntilDestroyed(),
      )
      .subscribe();
  }

  get batchRows(): FormArray<FormGroup> {
    return this.batchForm.controls.rows;
  }

  isEditMode(): boolean {
    return this.priceId() !== null;
  }

  isBoardEditorMode(): boolean {
    const b = this.stationPricesBoardId();
    return b !== null && Number.isFinite(b) && b >= 1;
  }

  pageTitle(): string {
    if (this.isBoardEditorMode()) {
      return 'Sửa bảng giá';
    }
    return 'Cập nhật giá bán';
  }

  donViTinhLabel(u: StoreAdminDonViTinhLookupDto): string {
    const ma = u.ma?.trim() ?? '';
    const ten = u.ten?.trim() ?? '';
    if (ma && ten) {
      return `${ma} — ${ten}`;
    }
    return ten || ma || String(u.id);
  }

  onBatchProductChange(index: number): void {
    const row = this.batchRows.at(index);
    const pid = row.get('productId')?.value as number | null;
    if (pid !== null && pid !== undefined && Number.isFinite(pid)) {
      this.applyDefaultUnitForProduct(row, pid);
    }
    this.batchRows.updateValueAndValidity();
  }

  /** Gợi ý mặt hàng theo text đang gõ (ô autocomplete). */
  productMatches(filterText: unknown): StoreAdminFuelProductLookupDto[] {
    const q = typeof filterText === 'string' ? filterText.toLowerCase().trim() : '';
    const items = this.productCatalog();
    const src = !q
      ? items
      : items.filter(
          (p) =>
            p.code.toLowerCase().includes(q) ||
            p.name.toLowerCase().includes(q) ||
            String(p.id).includes(q),
        );
    return src.slice(0, 100);
  }

  productLine(p: StoreAdminFuelProductLookupDto): string {
    return `${p.code} — ${p.name}`;
  }

  onBatchProductPicked(index: number, e: MatAutocompleteSelectedEvent): void {
    const p = e.option.value as StoreAdminFuelProductLookupDto;
    const row = this.batchRows.at(index);
    row.patchValue(
      {
        productId: p.id,
        productSearch: this.productLine(p),
      },
      { emitEvent: false },
    );
    this.onBatchProductChange(index);
  }

  onBatchProductSearchBlur(index: number): void {
    const row = this.batchRows.at(index);
    const pid = row.get('productId')?.value as number | null;
    const rawSearch = row.get('productSearch')?.value;
    const search = typeof rawSearch === 'string' ? rawSearch.trim() : '';
    const expected = pid !== null && pid !== undefined && Number.isFinite(pid) ? this.labelForProductId(pid) : '';
    if (search !== expected) {
      row.patchValue({ productId: null }, { emitEvent: false });
    }
    row.get('productId')?.markAsTouched();
  }

  onEditProductPicked(e: MatAutocompleteSelectedEvent): void {
    const p = e.option.value as StoreAdminFuelProductLookupDto;
    this.form.patchValue(
      {
        productId: p.id,
        productSearch: this.productLine(p),
      },
      { emitEvent: false },
    );
    this.syncEditUnitFromProduct();
  }

  onEditProductSearchBlur(): void {
    const pid = this.form.controls.productId.value;
    const raw = this.form.controls.productSearch.value;
    const search = typeof raw === 'string' ? raw.trim() : '';
    const expected = pid !== null && pid !== undefined && Number.isFinite(pid) ? this.labelForProductId(pid) : '';
    if (search !== expected) {
      this.form.patchValue({ productId: null }, { emitEvent: false });
    }
    this.form.controls.productId.markAsTouched();
  }

  private syncEditUnitFromProduct(): void {
    const pid = this.form.controls.productId.value;
    if (pid !== null && pid !== undefined && Number.isFinite(pid)) {
      const p = this.productCatalog().find((x) => x.id === pid);
      if (p?.unitId !== null && p?.unitId !== undefined) {
        this.form.patchValue({ unitId: p.unitId }, { emitEvent: false });
      }
    }
  }

  private applyDefaultUnitForProduct(row: FormGroup, productId: number): void {
    const p = this.productCatalog().find((x) => x.id === productId);
    if (p?.unitId !== null && p?.unitId !== undefined) {
      row.patchValue({ unitId: p.unitId }, { emitEvent: false });
    }
  }

  createPriceRow(initial?: {
    lineId?: number | null;
    productId?: number | null;
    price?: number | null;
    unitId?: number | null;
    note?: string | null;
  }): FormGroup {
    const pid = initial?.productId ?? null;
    return this.fb.group({
      lineId: this.fb.control<number | null>(initial?.lineId ?? null),
      productSearch: this.fb.nonNullable.control(this.labelForProductId(pid)),
      productId: this.fb.control<number | null>(pid, [Validators.required]),
      price: this.fb.control<number | null>(initial?.price ?? null, [Validators.required, Validators.min(0)]),
      unitId: this.fb.control<number | null>(initial?.unitId ?? null),
      note: this.fb.control(initial?.note ?? '', [Validators.maxLength(STORE_PRICE_NOTE_MAX)]),
    });
  }

  private labelForProductId(id: number | null | undefined): string {
    if (id === null || id === undefined || !Number.isFinite(id)) {
      return '';
    }
    const p = this.productCatalog().find((x) => x.id === id);
    return p ? this.productLine(p) : '';
  }

  addPriceRow(focusSelect = true): void {
    if (this.isBoardEditorMode()) {
      return;
    }
    this.batchRows.push(this.createPriceRow());
    this.batchRows.updateValueAndValidity();
    if (focusSelect) {
      queueMicrotask(() => {
        const last = this.productInputs().at(-1);
        last?.nativeElement.focus();
      });
    }
  }

  removePriceRow(index: number): void {
    if (this.isBoardEditorMode()) {
      return;
    }
    if (this.batchRows.length <= 1) {
      return;
    }
    this.batchRows.removeAt(index);
    this.batchRows.updateValueAndValidity();
  }

  loadDefaultProducts(): void {
    if (this.isBoardEditorMode()) {
      return;
    }
    this.loadingDefaults.set(true);
    this.errorMessage.set(null);
    this.prices
      .listProducts({ take: 30, defaultsOnly: true })
      .pipe(finalize(() => this.loadingDefaults.set(false)))
      .subscribe({
        next: (defs) => {
          this.defaultProducts.set(defs);
          this.batchRows.clear();
          if (defs.length === 0) {
            this.batchRows.push(this.createPriceRow());
          } else {
            for (const d of defs) {
              this.batchRows.push(
                this.createPriceRow({ productId: d.id, price: null, unitId: d.unitId, note: '' }),
              );
            }
          }
          this.batchRows.updateValueAndValidity();
          queueMicrotask(() => {
            this.productInputs().at(0)?.nativeElement.focus();
          });
        },
        error: (err: unknown) => {
          this.errorMessage.set(err instanceof ApiRequestError ? err.message : 'Không tải được danh mục mặc định.');
        },
      });
  }

  copyFromLatest(): void {
    if (this.isBoardEditorMode()) {
      return;
    }
    const donViId = this.batchForm.getRawValue().donViId;
    if (donViId === null || donViId === undefined || !Number.isFinite(Number(donViId))) {
      this.errorMessage.set('Tài khoản chưa gắn DonViId (cửa hàng). Không thể sao chép.');
      return;
    }
    this.loadingLatest.set(true);
    this.errorMessage.set(null);
    this.prices
      .latestSubmission(Number(donViId))
      .pipe(finalize(() => this.loadingLatest.set(false)))
      .subscribe({
        next: (rows) => {
          if (rows.length === 0) {
            this.errorMessage.set('Chưa có bản ghi giá trước đó cho cửa hàng này.');
            return;
          }
          this.batchRows.clear();
          for (const r of rows) {
            this.batchRows.push(
              this.createPriceRow({
                productId: r.productId,
                price: r.price,
                unitId: r.unitId,
                note: r.note ?? '',
              }),
            );
          }
          this.batchForm.patchValue({
            effectiveDate: isoToVnEffectiveDateTime(rows[0]?.effectiveDate ?? ''),
            isCurrent: rows.some((x) => x.isCurrent),
          });
          this.batchRows.updateValueAndValidity();
        },
        error: (err: unknown) => {
          this.errorMessage.set(err instanceof ApiRequestError ? err.message : 'Không tải được giá gần nhất.');
        },
      });
  }

  submit(): void {
    if (this.isBoardEditorMode()) {
      this.submitBoardEditor();
      return;
    }
    if (this.isEditMode()) {
      this.submitEdit();
      return;
    }
    this.submitBatch();
  }

  private submitBoardEditor(): void {
    const bid = this.stationPricesBoardId();
    if (bid === null || !Number.isFinite(bid)) {
      return;
    }
    this.batchForm.markAllAsTouched();
    for (const row of this.batchRows.controls) {
      row.markAllAsTouched();
    }
    if (this.batchForm.invalid) {
      return;
    }
    const v = this.batchForm.getRawValue();
    const rowsRaw = v.rows as Array<Record<string, unknown>>;
    const rows: StoreAdminStationPriceBoardEditorSaveRequest['rows'] = rowsRaw.map((r) => ({
      id: Number(r['lineId']),
      productId: Number(r['productId']),
      price: Number(r['price']),
      unitId: parseNullableInt(r['unitId']),
      note: strOrNull(r['note'] as string | null | undefined),
    }));
    if (rows.some((x) => !Number.isFinite(x.id) || x.id < 1)) {
      this.errorMessage.set('Thiếu id dòng giá (lineId).');
      return;
    }
    const body: StoreAdminStationPriceBoardEditorSaveRequest = {
      effectiveDate: effectiveDisplayToApiIso(v.effectiveDate ?? ''),
      isCurrent: v.isCurrent,
      rows,
    };
    this.saving.set(true);
    this.errorMessage.set(null);
    this.prices
      .savePriceBoardEditor(bid, body)
      .pipe(finalize(() => this.saving.set(false)))
      .subscribe({
        next: () => void this.router.navigateByUrl('/store-prices'),
        error: (err: unknown) => {
          this.errorMessage.set(err instanceof ApiRequestError ? err.message : 'Lưu thất bại.');
        },
      });
  }

  private submitEdit(): void {
    this.form.markAllAsTouched();
    if (this.form.invalid) {
      return;
    }
    const body = this.buildUpsert();
    this.saving.set(true);
    this.errorMessage.set(null);
    const id = this.priceId();
    const req$ = id !== null ? this.prices.update(id, body) : this.prices.create(body);
    req$.pipe(finalize(() => this.saving.set(false))).subscribe({
      next: () => void this.router.navigateByUrl('/store-prices'),
      error: (err: unknown) => {
        this.errorMessage.set(err instanceof ApiRequestError ? err.message : 'Lưu thất bại.');
      },
    });
  }

  private submitBatch(): void {
    this.batchForm.markAllAsTouched();
    for (const row of this.batchRows.controls) {
      row.markAllAsTouched();
    }
    if (this.batchForm.invalid) {
      return;
    }
    const v = this.batchForm.getRawValue();
    const rowsRaw = v.rows as Array<Record<string, unknown>>;
    const body: StoreAdminStorePriceBatchCreateRequest = {
      donViId: Number(v.donViId),
      effectiveDate: effectiveDisplayToApiIso(v.effectiveDate ?? ''),
      isCurrent: v.isCurrent,
      rows: rowsRaw.map((r) => ({
        productId: Number(r['productId']),
        price: Number(r['price']),
        unitId: parseNullableInt(r['unitId']),
        note: strOrNull(r['note'] as string | null | undefined),
      })),
    };
    this.saving.set(true);
    this.errorMessage.set(null);
    this.prices
      .batchCreate(body)
      .pipe(finalize(() => this.saving.set(false)))
      .subscribe({
        next: () => void this.router.navigateByUrl('/store-prices'),
        error: (err: unknown) => {
          this.errorMessage.set(err instanceof ApiRequestError ? err.message : 'Lưu thất bại.');
        },
      });
  }

  cancel(): void {
    void this.router.navigateByUrl('/store-prices');
  }

  onPriceEnter(index: number, ev: Event): void {
    const ke = ev as KeyboardEvent;
    if (ke.key !== 'Enter') {
      return;
    }
    ke.preventDefault();
    if (index < this.batchRows.length - 1) {
      const el = this.productInputs().at(index + 1)?.nativeElement ?? null;
      el?.focus();
    } else if (!this.isBoardEditorMode()) {
      this.addPriceRow(true);
    }
  }

  private resetForCreate(): void {
    this.form.reset({
      donViId: null,
      productSearch: '',
      productId: null,
      price: null,
      unitId: null,
      effectiveDate: '',
      isCurrent: false,
      note: '',
    });
    this.batchForm.reset({
      donViId: null,
      effectiveDate: '',
      isCurrent: false,
    });
    this.batchRows.clear();
    this.batchRows.push(this.createPriceRow());
    this.defaultProducts.set([]);
    this.applyLoggedInDonViToBatchForm();
  }

  /** Gán DonViId từ profile đăng nhập; ẩn khỏi chỉnh sửa (chỉ getRawValue khi lưu). */
  private applyLoggedInDonViToBatchForm(): void {
    const id = this.userContext.donViId();
    const n = typeof id === 'number' && Number.isFinite(id) ? id : null;
    this.applyDonViIdToBatchForm(n);
  }

  private applyDonViIdToBatchForm(donViId: number | null): void {
    this.batchForm.controls.donViId.enable({ emitEvent: false });
    this.batchForm.patchValue({ donViId }, { emitEvent: false });
    this.batchForm.controls.donViId.disable({ emitEvent: false });
  }

  private patchFromBoardEditor(b: StoreAdminStationPriceBoardEditorResponseDto): void {
    this.boardEditDisplayDonViId.set(b.donViId);
    this.batchForm.patchValue({
      effectiveDate: isoToVnEffectiveDateTime(b.activeDate),
      isCurrent: b.isActive,
    });
    this.batchRows.clear();
    for (const line of b.lines) {
      this.batchRows.push(
        this.createPriceRow({
          lineId: line.lineId,
          productId: line.productId,
          price: line.price,
          unitId: line.unitId,
          note: line.note ?? '',
        }),
      );
    }
    this.batchRows.updateValueAndValidity();
    this.applyDonViIdToBatchForm(b.donViId);
  }

  private patchFromDetail(d: StoreAdminStorePriceDetailDto): void {
    this.form.patchValue({
      donViId: d.donViId,
      productId: d.productId,
      productSearch: this.labelForProductId(d.productId),
      price: d.price,
      unitId: d.unitId,
      effectiveDate: isoToVnEffectiveDateTime(d.effectiveDate),
      isCurrent: d.isCurrent,
      note: d.note ?? '',
    });
    this.applyStorePortalDonViPin();
  }

  private applyStorePortalDonViPin(): void {
    const pin = retailPinnedDonViIdForStoreRole(this.userContext);
    if (pin === null) {
      return;
    }
    this.form.patchValue({ donViId: pin }, { emitEvent: false });
    this.form.controls.donViId.disable({ emitEvent: false });
  }

  private buildUpsert(): StoreAdminStorePriceUpsertRequest {
    const v = this.form.getRawValue();
    return {
      donViId: Number(v.donViId),
      productId: Number(v.productId),
      price: Number(v.price),
      unitId: parseNullableInt(v.unitId),
      effectiveDate: effectiveDisplayToApiIso(v.effectiveDate ?? ''),
      isCurrent: v.isCurrent,
      note: strOrNull(v.note),
    };
  }
}
