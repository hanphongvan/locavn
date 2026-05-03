import { CommonModule } from '@angular/common';
import {
  Component,
  ElementRef,
  inject,
  signal,
  viewChildren,
} from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { MatAutocompleteModule, MatAutocompleteSelectedEvent } from '@angular/material/autocomplete';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
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
import { combineLatest, of } from 'rxjs';
import { catchError, finalize, switchMap, tap } from 'rxjs/operators';

import { CurrentUserContextService } from '../../core/auth/current-user-context.service';
import { ApiRequestError } from '../../core/http/api-request-error';
import { VnGroupedNumberInputDirective } from '../../shared/inputs/vn-grouped-number-input.directive';
import type {
  StoreAdminDonViTinhLookupDto,
  StoreAdminFuelProductLookupDto,
} from '../store-prices/models/store-admin-store-price.models';
import { StorePricesApiService } from '../store-prices/services/store-prices-api.service';
import type {
  StoreAdminInventoryTransactionBundleDto,
  StoreAdminInventoryTransactionSaveRequest,
} from './models/store-admin-inventory-transaction.models';
import { InventoryTransactionsApiService } from './services/inventory-transactions-api.service';
import { INVENTORY_TX_DEFAULT_DETAIL_ROWS, INVENTORY_TX_NOTE_MAX } from './inventory-transaction.constants';

function strOrNull(s: string | null | undefined): string | null {
  if (s === null || s === undefined) {
    return null;
  }
  const t = String(s).trim();
  return t === '' ? null : t;
}

function parseOptionalAmount(v: unknown): number | null {
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

/** ISO từ API → hiển thị `dd/MM/yyyy HH:mm` theo giờ Việt Nam. */
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

function vnWallNowEffectiveDisplay(): string {
  const { day, month, year, hour, minute } = hcmPartsFromDate(new Date());
  return `${day}/${month}/${year} ${hour}:${minute}`;
}

/**
 * Parse `dd/MM/yyyy HH:mm` (24h) → chuỗi gửi API `yyyy-MM-ddTHH:mm:ss` (không hậu tố `Z`).
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
    const v = String(control.value ?? '').trim();
    if (v === '') {
      return null;
    }
    return vnEffectiveDateTimeToIso(v) === '' ? { vnDateTime: true } : null;
  };
}

function effectiveDisplayToApiIso(display: string): string {
  return vnEffectiveDateTimeToIso(display.trim());
}

function positiveQuantityValidator(ctrl: AbstractControl): ValidationErrors | null {
  const v = ctrl.value;
  if (v === null || v === undefined || v === '') {
    return null;
  }
  const n = typeof v === 'number' ? v : Number(v);
  if (!Number.isFinite(n) || n <= 0) {
    return { positiveQuantity: true };
  }
  return null;
}

function allowedTransactionTypeValidator(ctrl: AbstractControl): ValidationErrors | null {
  const v = ctrl.value;
  if (v === null || v === undefined) {
    return null;
  }
  if (v !== 1 && v !== -1) {
    return { transactionTypeInvalid: true };
  }
  return null;
}

function optionalNonNegativeAmountValidator(ctrl: AbstractControl): ValidationErrors | null {
  const v = ctrl.value;
  if (v === null || v === undefined || v === '') {
    return null;
  }
  const n = typeof v === 'number' ? v : Number(v);
  if (!Number.isFinite(n)) {
    return { amountNumber: true };
  }
  if (n < 0) {
    return { amountMin: true };
  }
  return null;
}

/** No duplicate ProductId across filled rows. */
function uniqueDetailProductsValidator(control: AbstractControl): ValidationErrors | null {
  const fa = control as FormArray<FormGroup>;
  const ids: number[] = [];
  for (const g of fa.controls) {
    const v = g.get('productId')?.value;
    if (v !== null && v !== undefined && v !== '' && Number.isFinite(Number(v))) {
      ids.push(Number(v));
    }
  }
  if (ids.length === 0) {
    return null;
  }
  return ids.length !== new Set(ids).size ? { duplicateProducts: true } : null;
}

/** Khi đã chọn mặt hàng, phải có `unitId` hợp lệ (đồng bộ từ danh mục). */
function inventoryDetailUnitValidator(group: AbstractControl): ValidationErrors | null {
  const fg = group as FormGroup;
  const pid = fg.get('productId')?.value;
  const uid = fg.get('unitId')?.value;
  const hasProduct = pid !== null && pid !== undefined && Number.isFinite(Number(pid));
  if (!hasProduct) {
    return null;
  }
  if (uid === null || uid === undefined || !Number.isFinite(Number(uid)) || Number(uid) < 1) {
    return { lineUnitInvalid: true };
  }
  return null;
}

@Component({
  selector: 'app-inventory-transaction-form-page',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    RouterLink,
    MatAutocompleteModule,
    MatButtonModule,
    MatIconModule,
    MatInputModule,
    VnGroupedNumberInputDirective,
  ],
  templateUrl: './inventory-transaction-form-page.component.html',
  styleUrl: './inventory-transaction-form-page.component.scss',
})
export class InventoryTransactionFormPageComponent {
  private readonly fb = inject(FormBuilder);
  private readonly txApi = inject(InventoryTransactionsApiService);
  /** Cùng nguồn form giá: chỉ mặt hàng lá (SP `sp_StoreAdmin_FuelProducts_ListActiveForLookup`). */
  private readonly storePricesApi = inject(StorePricesApiService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly userContext = inject(CurrentUserContextService);

  readonly NOTE_MAX = INVENTORY_TX_NOTE_MAX;

  readonly productInputs = viewChildren<ElementRef<HTMLInputElement>>('invRowProductInput');

  readonly products = signal<StoreAdminFuelProductLookupDto[]>([]);

  /** `DM_DonViTinh` — cùng API `GET .../store-prices/don-vi-tinh` như form giá. */
  readonly donViTinhOptions = signal<StoreAdminDonViTinhLookupDto[]>([]);

  readonly loading = signal(false);
  readonly loadingDefaults = signal(false);
  readonly saving = signal(false);
  readonly copyingLatest = signal(false);
  readonly errorMessage = signal<string | null>(null);
  readonly transactionId = signal<number | null>(null);

  private detailRowSeq = 0;

  readonly form = this.fb.group({
    donViId: this.fb.control<number | null>(null, [Validators.required]),
    transactionType: this.fb.control<number | null>(null, [
      Validators.required,
      allowedTransactionTypeValidator,
    ]),
    transactionDate: ['', [Validators.required, vnEffectiveDateTimeValidator()]],
    note: ['', [Validators.maxLength(INVENTORY_TX_NOTE_MAX)]],
    details: this.fb.array<FormGroup>([], { validators: [uniqueDetailProductsValidator] }),
  });

  constructor() {
    this.storePricesApi
      .listProducts({ take: 500, defaultsOnly: false })
      .pipe(takeUntilDestroyed())
      .subscribe({
        next: (products) => {
          this.products.set(products);
          this.syncDetailProductSearchLabels();
        },
        error: () => {
          this.products.set([]);
        },
      });

    this.storePricesApi
      .listDonViTinh()
      .pipe(takeUntilDestroyed())
      .subscribe({
        next: (rows) => this.donViTinhOptions.set(rows),
        error: () => this.donViTinhOptions.set([]),
      });

    combineLatest([this.route.paramMap, this.route.queryParamMap])
      .pipe(
        switchMap(([pm, qm]) => {
          const idStr = pm.get('id');
          const editId = idStr && idStr !== '' ? Number(idStr) : null;
          const validEdit = editId !== null && Number.isFinite(editId) ? editId : null;
          this.transactionId.set(validEdit);
          this.errorMessage.set(null);
          this.loading.set(true);

          if (validEdit !== null) {
            return this.txApi.getById(validEdit).pipe(
              tap((d) => this.patchFromBundle(d)),
              catchError((err: unknown) => {
                this.errorMessage.set(
                  err instanceof ApiRequestError ? err.message : 'Không tải được giao dịch.',
                );
                return of(null);
              }),
              finalize(() => this.loading.set(false)),
            );
          }

          this.resetForCreate();
          const prefill = this.userContext.consumeInventoryTransactionCreatePrefill();
          const pr = qm.get('productId');
          const productIdFromUrl = pr && pr !== '' ? Number(pr) : null;
          const productId =
            productIdFromUrl !== null && Number.isFinite(productIdFromUrl)
              ? productIdFromUrl
              : prefill.productId !== null && Number.isFinite(prefill.productId)
                ? prefill.productId
                : null;
          this.details.clear();
          this.addLine(productId);
          this.form.patchValue({
            transactionDate: vnWallNowEffectiveDisplay(),
            transactionType: 1,
          });
          this.applyDonViIdForCreateMode();
          this.loading.set(false);
          return of(null);
        }),
        takeUntilDestroyed(),
      )
      .subscribe();
  }

  get details(): FormArray<FormGroup> {
    return this.form.controls.details as FormArray<FormGroup>;
  }

  isEditMode(): boolean {
    return this.transactionId() !== null;
  }

  canCopyLatest(): boolean {
    const v = this.form.getRawValue().donViId as number | null | undefined;
    return v !== null && v !== undefined && Number.isFinite(Number(v));
  }

  pageTitle(): string {
    return this.isEditMode() ? 'Sửa giao dịch kho' : 'Thêm giao dịch kho';
  }

  trackDetailRow(_index: number, ctrl: AbstractControl): string {
    const uid = (ctrl as FormGroup).get('rowUid')?.value;
    return typeof uid === 'string' ? uid : `r-${_index}`;
  }

  detailRowHasProduct(row: AbstractControl): boolean {
    const v = (row as FormGroup).get('productId')?.value;
    return v !== null && v !== undefined && Number.isFinite(Number(v));
  }

  productLine(p: StoreAdminFuelProductLookupDto): string {
    return `${p.code} — ${p.name}`;
  }

  productMatches(filterText: unknown): StoreAdminFuelProductLookupDto[] {
    const q = typeof filterText === 'string' ? filterText.toLowerCase().trim() : '';
    const items = this.products();
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

  labelForProductId(id: number | null | undefined): string {
    if (id === null || id === undefined || !Number.isFinite(id)) {
      return '';
    }
    const p = this.products().find((x) => x.id === id);
    return p ? this.productLine(p) : '';
  }

  donViTinhLabel(u: StoreAdminDonViTinhLookupDto): string {
    const ma = u.ma?.trim() ?? '';
    const ten = u.ten?.trim() ?? '';
    if (ma && ten) {
      return ` ${ten}`;
    }
    return ten || ma || String(u.id);
  }

  onDetailProductPicked(index: number, e: MatAutocompleteSelectedEvent): void {
    const p = e.option.value as StoreAdminFuelProductLookupDto;
    const row = this.details.at(index);
    row.patchValue(
      {
        productId: p.id,
        productSearch: this.productLine(p),
        unitId: p.unitId ?? null,
      },
      { emitEvent: false },
    );
    this.details.updateValueAndValidity();
  }

  onDetailProductSearchBlur(index: number): void {
    const row = this.details.at(index);
    const pid = row.get('productId')?.value as number | null;
    const rawSearch = row.get('productSearch')?.value;
    const search = typeof rawSearch === 'string' ? rawSearch.trim() : '';
    const expected = pid !== null && pid !== undefined && Number.isFinite(pid) ? this.labelForProductId(pid) : '';
    if (search !== expected) {
      row.patchValue({ productId: null, unitId: null }, { emitEvent: false });
    }
    row.get('productId')?.markAsTouched();
    this.details.updateValueAndValidity();
  }

  addLine(initialProductId: number | null = null, focusProductSelect = true): void {
    this.details.push(this.createLineGroup(initialProductId));
    if (focusProductSelect) {
      queueMicrotask(() => {
        this.productInputs().at(-1)?.nativeElement.focus();
      });
    }
  }

  removeLine(index: number): void {
    if (this.details.length <= 1) {
      return;
    }
    this.details.removeAt(index);
    this.details.updateValueAndValidity();
  }

  onDetailKeydown(event: KeyboardEvent, index: number, field: 'product' | 'unit' | 'qty' | 'amt' | 'note'): void {
    if (event.key !== 'Enter') {
      return;
    }
    if (field === 'unit') {
      event.preventDefault();
      document.getElementById(`inv-detail-qty-${index}`)?.focus();
      return;
    }
    if (field === 'note' || (field === 'amt' && index === this.details.length - 1)) {
      event.preventDefault();
      this.addLine(null, true);
    }
  }

  loadDefaultProducts(): void {
    this.loadingDefaults.set(true);
    this.errorMessage.set(null);
    this.storePricesApi
      .listProducts({ take: Math.max(30, INVENTORY_TX_DEFAULT_DETAIL_ROWS), defaultsOnly: true })
      .pipe(finalize(() => this.loadingDefaults.set(false)))
      .subscribe({
        next: (defs) => {
          const list = defs.slice(0, INVENTORY_TX_DEFAULT_DETAIL_ROWS);
          if (list.length === 0) {
            this.errorMessage.set('Chưa có mặt hàng mặc định (mặt hàng lá có SortOrder) trong danh mục.');
            return;
          }
          this.details.clear();
          for (const p of list) {
            this.addLine(p.id, false);
          }
          queueMicrotask(() => {
            document.getElementById(`inv-detail-qty-${this.details.length - 1}`)?.focus();
          });
          this.details.updateValueAndValidity();
        },
        error: (err: unknown) => {
          this.errorMessage.set(
            err instanceof ApiRequestError ? err.message : 'Không tải được danh mục mặc định.',
          );
        },
      });
  }

  copyLatest(): void {
    if (this.isEditMode()) {
      return;
    }
    const dv = this.form.getRawValue().donViId as number | null;
    if (dv === null || dv === undefined || !Number.isFinite(Number(dv))) {
      this.errorMessage.set('Tài khoản chưa gắn DonViId (cửa hàng). Không thể sao chép phiếu gần nhất.');
      return;
    }
    this.errorMessage.set(null);
    this.copyingLatest.set(true);
    this.txApi
      .getLatest(Number(dv))
      .pipe(finalize(() => this.copyingLatest.set(false)))
      .subscribe({
        next: (b) => this.applyLatestAsTemplate(b),
        error: (err: unknown) => {
          const msg =
            err instanceof ApiRequestError
              ? err.httpStatus === 404
                ? 'Chưa có giao dịch nào cho cửa hàng này.'
                : err.message
              : 'Không tải được phiếu gần nhất.';
          this.errorMessage.set(msg);
        },
      });
  }

  copyPreviousRow(index: number): void {
    if (index < 1) {
      return;
    }
    const prev = this.details.at(index - 1) as FormGroup;
    const cur = this.details.at(index) as FormGroup;
    cur.patchValue({
      productId: prev.get('productId')?.value,
      productSearch: prev.get('productSearch')?.value ?? '',
      unitId: prev.get('unitId')?.value,
      quantity: prev.get('quantity')?.value,
      amount: prev.get('amount')?.value,
      lineNote: prev.get('lineNote')?.value ?? '',
    });
    this.details.updateValueAndValidity();
  }

  submit(): void {
    this.form.markAllAsTouched();
    if (this.form.invalid) {
      return;
    }
    const body = this.buildSave();
    this.saving.set(true);
    this.errorMessage.set(null);
    const id = this.transactionId();
    const req$ = id !== null ? this.txApi.update(id, body) : this.txApi.create(body);
    req$.pipe(finalize(() => this.saving.set(false))).subscribe({
      next: () => void this.router.navigateByUrl('/inventory-transactions'),
      error: (err: unknown) => {
        this.errorMessage.set(err instanceof ApiRequestError ? err.message : 'Lưu thất bại.');
      },
    });
  }

  cancel(): void {
    void this.router.navigateByUrl('/inventory-transactions');
  }

  /** Khi danh sách mặt hàng tải sau form (sửa phiếu), đồng bộ lại nhãn ô tìm kiếm. */
  private syncDetailProductSearchLabels(): void {
    for (let i = 0; i < this.details.length; i++) {
      const g = this.details.at(i) as FormGroup;
      const pid = g.get('productId')?.value as number | null;
      if (pid === null || pid === undefined || !Number.isFinite(pid)) {
        continue;
      }
      const label = this.labelForProductId(pid);
      if (label !== '') {
        g.patchValue(
          { productSearch: label, unitId: this.lookupProductUnitId(pid) },
          { emitEvent: false },
        );
      }
    }
  }

  private createLineGroup(initialProductId: number | null = null): FormGroup {
    this.detailRowSeq += 1;
    const pid =
      initialProductId !== null && Number.isFinite(initialProductId) ? Number(initialProductId) : null;
    return this.fb.group(
      {
        rowUid: [`row-${this.detailRowSeq}`],
        productSearch: [pid !== null ? this.labelForProductId(pid) : '', []],
        productId: this.fb.control<number | null>(pid, [Validators.required]),
        unitId: this.fb.control<number | null>(this.lookupProductUnitId(pid), []),
        quantity: this.fb.control<number | null>(null, [Validators.required, positiveQuantityValidator]),
        amount: this.fb.control<number | null>(null, [optionalNonNegativeAmountValidator]),
        lineNote: ['', [Validators.maxLength(INVENTORY_TX_NOTE_MAX)]],
      },
      { validators: [inventoryDetailUnitValidator] },
    );
  }

  private lookupProductUnitId(productId: number | null): number | null {
    if (productId === null || !Number.isFinite(productId)) {
      return null;
    }
    const p = this.products().find((x) => x.id === productId);
    return p?.unitId ?? null;
  }

  private resetForCreate(): void {
    this.details.clear();
    this.form.controls.donViId.enable({ emitEvent: false });
    this.form.reset({
      donViId: null,
      transactionType: null,
      transactionDate: '',
      note: '',
    });
  }

  private patchFromBundle(d: StoreAdminInventoryTransactionBundleDto): void {
    this.details.clear();
    for (const line of d.details) {
      this.detailRowSeq += 1;
      this.details.push(
        this.fb.group(
          {
            rowUid: [`edit-${line.id}-${this.detailRowSeq}`],
            productSearch: [this.labelForProductId(line.productId), []],
            productId: this.fb.control<number | null>(line.productId, [Validators.required]),
            unitId: this.fb.control<number | null>(line.unitId, []),
            quantity: this.fb.control<number | null>(line.quantity, [Validators.required, positiveQuantityValidator]),
            amount: this.fb.control<number | null>(line.amount ?? null, [optionalNonNegativeAmountValidator]),
            lineNote: [line.note ?? '', [Validators.maxLength(INVENTORY_TX_NOTE_MAX)]],
          },
          { validators: [inventoryDetailUnitValidator] },
        ),
      );
    }
    if (this.details.length === 0) {
      this.addLine();
    }
    this.form.patchValue({
      donViId: d.donViId,
      transactionType: d.transactionType,
      transactionDate: isoToVnEffectiveDateTime(d.transactionDate),
      note: d.note ?? '',
    });
    this.lockDonViIdControl();
    this.details.updateValueAndValidity();
  }

  /** Copy latest as editable template: new transaction date, same store, lines from latest. */
  private applyLatestAsTemplate(b: StoreAdminInventoryTransactionBundleDto): void {
    const userDv = this.userContext.donViId();
    const donViId =
      userDv !== null && userDv !== undefined && Number.isFinite(Number(userDv)) ? Number(userDv) : b.donViId;
    this.form.patchValue({
      donViId,
      transactionType: b.transactionType,
      transactionDate: vnWallNowEffectiveDisplay(),
      note: b.note ?? '',
    });
    this.details.clear();
    for (const line of b.details) {
      this.addLine(null, false);
      const g = this.details.at(this.details.length - 1) as FormGroup;
      g.patchValue({
        productId: line.productId,
        productSearch: this.labelForProductId(line.productId),
        unitId: line.unitId,
        quantity: line.quantity,
        amount: line.amount ?? null,
        lineNote: line.note ?? '',
      });
    }
    if (this.details.length === 0) {
      this.addLine();
    }
    this.lockDonViIdControl();
    this.details.updateValueAndValidity();
    queueMicrotask(() => {
      this.productInputs().at(0)?.nativeElement.focus();
    });
  }

  /** Tạo mới: DonViId = profile đăng nhập; luôn ẩn/khóa trên UI. */
  private applyDonViIdForCreateMode(): void {
    const id = this.userContext.donViId();
    if (id !== null && id !== undefined && Number.isFinite(id)) {
      this.form.patchValue({ donViId: id }, { emitEvent: false });
    }
    this.lockDonViIdControl();
  }

  private lockDonViIdControl(): void {
    this.form.controls.donViId.disable({ emitEvent: false });
  }

  private buildSave(): StoreAdminInventoryTransactionSaveRequest {
    const v = this.form.getRawValue() as {
      donViId: number | null;
      transactionType: number | null;
      transactionDate: string;
      note: string;
      details: Array<{
        rowUid: string;
        productSearch: string;
        productId: number | null;
        unitId: number | null;
        quantity: number | null;
        amount: unknown;
        lineNote: string;
      }>;
    };
    return {
      donViId: Number(v.donViId),
      transactionType: Number(v.transactionType),
      transactionDate: effectiveDisplayToApiIso(String(v.transactionDate ?? '')),
      note: strOrNull(v.note),
      details: v.details.map((row) => {
        const uid = row.unitId;
        return {
          productId: Number(row.productId),
          unitId: Number(uid),
          useProductDefaultUnit: false,
          quantity: Number(row.quantity),
          amount: parseOptionalAmount(row.amount),
          note: strOrNull(row.lineNote),
        } satisfies StoreAdminInventoryTransactionSaveRequest['details'][number];
      }),
    };
  }
}
