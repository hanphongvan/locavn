import { Component, input } from '@angular/core';

import type { HttmFacilityLicenseDto } from '../models/httm-facility.model';

@Component({
  selector: 'app-httm-license-card',
  standalone: true,
  template: `
    <div class="lic">
      <div class="lic__head">
        <strong>{{ license().licenseType }}</strong>
        @if (license().expiryAlert30d) {
          <span class="lic__warn">Sắp hết hạn</span>
        }
      </div>
      <div class="lic__row">Số: {{ license().licenseNumber ?? '—' }}</div>
      <div class="lic__row">Hết hạn: {{ license().expiryDate ?? '—' }}</div>
    </div>
  `,
  styles: [
    `
      .lic {
        border: 1px solid #e0e0e0;
        border-radius: 8px;
        padding: 0.6rem 0.75rem;
        margin-bottom: 0.5rem;
      }
      .lic__head {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 0.35rem;
      }
      .lic__row {
        font-size: 0.9rem;
        color: #555;
      }
      .lic__warn {
        color: #c62828;
        font-size: 0.8rem;
      }
    `,
  ],
})
export class HttmLicenseCardComponent {
  readonly license = input.required<HttmFacilityLicenseDto>();
}
