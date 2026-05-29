import { ChangeDetectionStrategy, Component, input } from '@angular/core';

/** Quốc huy Việt Nam — SVG vector (dùng cho header login). */
@Component({
  selector: 'app-vietnam-emblem',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <svg
      class="vn-emblem"
      [attr.width]="size()"
      [attr.height]="size()"
      viewBox="0 0 64 64"
      role="img"
      aria-label="Quốc huy Việt Nam"
    >
      <circle cx="32" cy="34" r="28" fill="#da251d" />
      <circle cx="32" cy="34" r="24" fill="none" stroke="#ffcd00" stroke-width="1.2" opacity="0.9" />
      <path fill="#ffcd00" d="M32 10 L34.2 18.8 H43.4 L35.9 24.2 L38.1 33 L32 28.2 L25.9 33 L28.1 24.2 L20.6 18.8 H29.8 Z" />
      <path
        fill="#ffcd00"
        opacity="0.95"
        d="M14 38 C18 32 22 30 32 30 C42 30 46 32 50 38 C46 44 42 46 32 46 C22 46 18 44 14 38 Z"
      />
      <circle cx="32" cy="38" r="9" fill="none" stroke="#ffcd00" stroke-width="2.5" />
      <path fill="#ffcd00" d="M32 31 L33.5 35.5 H38.2 L34.4 38.2 L35.9 42.7 L32 40 L28.1 42.7 L29.6 38.2 L25.8 35.5 H30.5 Z" />
      <path fill="#ffcd00" opacity="0.85" d="M10 48 Q32 54 54 48 L52 52 Q32 58 12 52 Z" />
    </svg>
  `,
  styles: `
    :host {
      display: inline-flex;
      line-height: 0;
    }
    .vn-emblem {
      display: block;
      filter: drop-shadow(0 2px 8px rgba(0, 0, 0, 0.35));
    }
  `,
})
export class VietnamEmblemComponent {
  readonly size = input(48);
}
