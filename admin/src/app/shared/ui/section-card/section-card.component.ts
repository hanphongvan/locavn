import { booleanAttribute, Component, input } from '@angular/core';

@Component({
  selector: 'app-section-card',
  standalone: true,
  templateUrl: './section-card.component.html',
  styleUrl: './section-card.component.scss',
})
export class SectionCardComponent {
  readonly title = input.required<string>();
  readonly flushBody = input(false, { transform: booleanAttribute });
}
