import { Component, input } from '@angular/core';

import { FilterPanelComponent } from '../../../shared/ui';

/** Khối lọc dùng chung danh sách / bản đồ HTTM (Phase 1: bọc `FilterPanel`). */
@Component({
  selector: 'app-httm-filter-bar',
  standalone: true,
  imports: [FilterPanelComponent],
  template: `<app-filter-panel [title]="title()"><ng-content /></app-filter-panel>`,
})
export class HttmFilterBarComponent {
  readonly title = input<string>('Tìm kiếm & bộ lọc');
}
