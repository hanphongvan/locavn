import { Component, input } from '@angular/core';

@Component({
  selector: 'app-table-wrapper',
  standalone: true,
  templateUrl: './table-wrapper.component.html',
  styleUrl: './table-wrapper.component.scss',
})
export class TableWrapperComponent {
  readonly caption = input<string | undefined>();
}
