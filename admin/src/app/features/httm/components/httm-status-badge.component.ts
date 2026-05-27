import { Component, input } from '@angular/core';

@Component({
  selector: 'app-httm-status-badge',
  standalone: true,
  template: `<span class="httm-badge httm-badge--status">{{ label() }}</span>`,
  styleUrl: './httm-badges.component.scss',
})
export class HttmStatusBadgeComponent {
  readonly code = input<string>('');
  readonly label = input<string>('');
}
