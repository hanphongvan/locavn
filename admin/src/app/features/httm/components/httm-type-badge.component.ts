import { Component, input } from '@angular/core';

@Component({
  selector: 'app-httm-type-badge',
  standalone: true,
  template: `<span class="httm-badge httm-badge--type">{{ label() }}</span>`,
  styleUrl: './httm-badges.component.scss',
})
export class HttmTypeBadgeComponent {
  readonly code = input<string>('');
  readonly label = input<string>('');
}
