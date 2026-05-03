import { Component, input } from '@angular/core';

export type AppStatusBadgeVariant = 'success' | 'warning' | 'neutral' | 'danger' | 'info';

@Component({
  selector: 'app-status-badge',
  standalone: true,
  templateUrl: './status-badge.component.html',
  styleUrl: './status-badge.component.scss',
})
export class StatusBadgeComponent {
  readonly label = input.required<string>();
  readonly variant = input<AppStatusBadgeVariant>('neutral');
}
