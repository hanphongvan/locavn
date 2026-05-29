import { ChangeDetectionStrategy, Component, input } from '@angular/core';

@Component({
  selector: 'app-dms-logo',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <img
      class="dms-logo"
      src="assets/logodms.png"
      [style.width.px]="size()"
      [style.height.px]="size()"
      alt="Logo DMS — Cục Quản lý và Phát triển thị trường trong nước"
    />
  `,
  styles: `
    :host {
      display: inline-flex;
      flex-shrink: 0;
      line-height: 0;
    }

    .dms-logo {
      display: block;
      object-fit: contain;
    }
  `,
})
export class DmsLogoComponent {
  readonly size = input(52);
}
