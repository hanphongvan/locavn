import type { AbstractControl, ValidationErrors, ValidatorFn } from '@angular/forms';

/** Email format only when value is non-empty (backend allows null). */
export function optionalEmail(): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    const v = control.value;
    if (v === null || v === undefined || String(v).trim() === '') {
      return null;
    }
    const s = String(v).trim();
    const ok = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(s);
    return ok ? null : { email: true };
  };
}

export function optionalLatitude(): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    const v = control.value as unknown;
    if (v === null || v === undefined || v === '') {
      return null;
    }
    const n = typeof v === 'number' ? v : Number(v);
    if (Number.isNaN(n)) {
      return { number: true };
    }
    if (n < -90 || n > 90) {
      return { latRange: true };
    }
    return null;
  };
}

export function optionalLongitude(): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    const v = control.value as unknown;
    if (v === null || v === undefined || v === '') {
      return null;
    }
    const n = typeof v === 'number' ? v : Number(v);
    if (Number.isNaN(n)) {
      return { number: true };
    }
    if (n < -180 || n > 180) {
      return { lonRange: true };
    }
    return null;
  };
}
