import {
  Directive,
  ElementRef,
  forwardRef,
  HostListener,
  inject,
  Input,
  OnChanges,
} from '@angular/core';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';

/**
 * Ô nhập số định dạng Việt Nam (vd. gõ `15000` → hiển thị `15.000`, thập phân bằng dấu `,`).
 * Dùng với `formControlName` / `formControl` kiểu `number | null`.
 * `vnMaxFractionDigits`: số chữ số sau dấu phẩy (mặc định 2 — tiền; dùng 3 cho số lượng kho nếu cần).
 */
@Directive({
  selector: '[vnGroupedNumberInput]',
  standalone: true,
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => VnGroupedNumberInputDirective),
      multi: true,
    },
  ],
})
export class VnGroupedNumberInputDirective implements ControlValueAccessor, OnChanges {
  private readonly el = inject<ElementRef<HTMLInputElement>>(ElementRef);

  /** Số chữ số thập phân tối đa (0–6). Mặc định 2 (đồng bộ form giá cửa hàng). */
  @Input() vnMaxFractionDigits: number | string = 2;

  private onChange: (v: number | null) => void = () => void 0;
  private onTouched: () => void = () => void 0;
  private disabled = false;
  private maxFrac = 2;
  private formatter!: Intl.NumberFormat;

  constructor() {
    this.refreshFormatter();
  }

  ngOnChanges(): void {
    this.refreshFormatter();
  }

  private refreshFormatter(): void {
    const n = Number(this.vnMaxFractionDigits);
    this.maxFrac = Number.isFinite(n) && n >= 0 && n <= 6 ? Math.floor(n) : 2;
    this.formatter = new Intl.NumberFormat('vi-VN', {
      minimumFractionDigits: 0,
      maximumFractionDigits: this.maxFrac,
    });
  }

  @HostListener('input')
  onInput(): void {
    if (this.disabled) {
      return;
    }
    const input = this.el.nativeElement;
    const caret = input.selectionStart ?? input.value.length;
    const digitIdx = digitIndexBeforeCaret(input.value, caret);
    const parsed = parseVnNumber(input.value, this.maxFrac);
    this.onChange(parsed);
    const next = parsed === null ? '' : this.formatter.format(parsed);
    if (input.value !== next) {
      input.value = next;
      const pos = caretFromDigitIndex(next, digitIdx);
      queueMicrotask(() => input.setSelectionRange(pos, pos));
    }
  }

  @HostListener('blur')
  onBlur(): void {
    if (this.disabled) {
      return;
    }
    const input = this.el.nativeElement;
    const parsed = parseVnNumber(input.value, this.maxFrac);
    this.onChange(parsed);
    input.value = parsed === null ? '' : this.formatter.format(parsed);
    this.onTouched();
  }

  writeValue(value: number | null): void {
    const input = this.el.nativeElement;
    if (value === null || value === undefined || Number.isNaN(value)) {
      input.value = '';
      return;
    }
    input.value = this.formatter.format(value);
  }

  registerOnChange(fn: (v: number | null) => void): void {
    this.onChange = fn;
  }

  registerOnTouched(fn: () => void): void {
    this.onTouched = fn;
  }

  setDisabledState(isDisabled: boolean): void {
    this.disabled = isDisabled;
    this.el.nativeElement.disabled = isDisabled;
  }
}

/** Đếm chữ số (phần nguyên + phần thập phân đã gõ) trước vị trí con trỏ. */
function digitIndexBeforeCaret(display: string, caret: number): number {
  const sub = display.slice(0, Math.max(0, Math.min(caret, display.length)));
  const lastComma = sub.lastIndexOf(',');
  if (lastComma >= 0) {
    const intPart = sub.slice(0, lastComma).replace(/\D/g, '');
    const decPart = sub.slice(lastComma + 1).replace(/\D/g, '');
    return intPart.length + decPart.length;
  }
  return sub.replace(/\D/g, '').length;
}

/** Đặt con trỏ sau chữ số thứ `digitIndex` (1-based số lượng chữ số đã nhập). */
function caretFromDigitIndex(formatted: string, digitIndex: number): number {
  if (digitIndex <= 0) {
    return 0;
  }
  let seen = 0;
  for (let i = 0; i < formatted.length; i++) {
    const ch = formatted[i];
    if (ch !== undefined && /\d/.test(ch)) {
      seen++;
      if (seen >= digitIndex) {
        return i + 1;
      }
    }
  }
  return formatted.length;
}

function parseVnNumber(raw: string, maxFractionDigits: number): number | null {
  const maxDec = Math.max(0, Math.min(6, maxFractionDigits));
  const t = raw.trim();
  if (t === '' || t === ',' || t === '.') {
    return null;
  }
  const lastComma = t.lastIndexOf(',');
  if (lastComma >= 0) {
    const intRaw = t.slice(0, lastComma).replace(/\./g, '').replace(/\D/g, '');
    const decRaw = t.slice(lastComma + 1).replace(/\D/g, '').slice(0, maxDec);
    if (intRaw === '' && decRaw === '') {
      return null;
    }
    const n = Number(intRaw === '' ? `0.${decRaw}` : `${intRaw}.${decRaw}`);
    return Number.isFinite(n) ? n : null;
  }
  const digits = t.replace(/\./g, '').replace(/\D/g, '');
  if (digits === '') {
    return null;
  }
  const n = Number(digits);
  return Number.isFinite(n) ? n : null;
}
