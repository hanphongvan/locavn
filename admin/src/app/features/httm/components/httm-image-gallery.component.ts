import { DatePipe, NgClass } from '@angular/common';
import {
  ChangeDetectionStrategy,
  Component,
  Inject,
  Input,
  OnChanges,
  OnInit,
  SimpleChanges,
  inject,
  signal,
} from '@angular/core';

import { API_BASE_URL } from '../../../core/tokens/api-base-url.token';
import type { HttmFacilityImageDto } from '../models/httm-facility.model';
import { HttmFacilityService } from '../services/httm-facility.service';

/** Gallery ảnh — Phase 2: tải danh sách ảnh qua `GET /api/httm/:id/images` và render lưới thumbnail. */
@Component({
  selector: 'app-httm-image-gallery',
  standalone: true,
  imports: [DatePipe, NgClass],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    @if (loading()) {
      <p class="muted">Đang tải ảnh…</p>
    } @else if (error()) {
      <p class="error">{{ error() }}</p>
    } @else if (items().length === 0) {
      <p class="muted">Chưa có ảnh nào.</p>
    } @else {
      <div class="grid">
        @for (img of items(); track img.id) {
          <a class="card" [href]="resolveUrl(img.imageUrl)" target="_blank" rel="noopener">
            <img [src]="resolveUrl(img.imageUrl)" [alt]="img.caption ?? img.imageType" loading="lazy" />
            <div class="meta">
              <span class="chip" [ngClass]="'chip-' + img.imageType">{{ img.imageType }}</span>
              @if (img.caption) {
                <span class="caption" [title]="img.caption">{{ img.caption }}</span>
              }
              @if (img.takenDate) {
                <span class="date">{{ img.takenDate | date: 'dd/MM/yyyy' }}</span>
              }
            </div>
          </a>
        }
      </div>
    }
  `,
  styles: [
    `
      .muted {
        color: rgba(0, 0, 0, 0.6);
        font-style: italic;
      }
      .error {
        color: #b00020;
      }
      .grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
        gap: 12px;
      }
      .card {
        display: flex;
        flex-direction: column;
        border: 1px solid rgba(0, 0, 0, 0.12);
        border-radius: 8px;
        overflow: hidden;
        text-decoration: none;
        color: inherit;
        background: #fff;
        transition: box-shadow 0.15s ease-in-out;
      }
      .card:hover {
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
      }
      .card img {
        width: 100%;
        aspect-ratio: 4 / 3;
        object-fit: cover;
        background: #f5f5f5;
        display: block;
      }
      .meta {
        display: flex;
        flex-direction: column;
        gap: 4px;
        padding: 8px;
        font-size: 12px;
      }
      .chip {
        align-self: flex-start;
        padding: 2px 8px;
        border-radius: 999px;
        background: var(--app-brand-muted-bg);
        color: var(--app-brand-dark);
        font-weight: 500;
        text-transform: capitalize;
      }
      .chip-exterior { background: var(--app-brand-muted-bg); color: var(--app-brand-dark); }
      .chip-interior { background: #f3e5f5; color: #4a148c; }
      .chip-legal { background: #fff3e0; color: #e65100; }
      .chip-other { background: #eceff1; color: #37474f; }
      .caption {
        color: rgba(0, 0, 0, 0.75);
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
      }
      .date {
        color: rgba(0, 0, 0, 0.55);
      }
    `,
  ],
})
export class HttmImageGalleryComponent implements OnInit, OnChanges {
  private readonly api = inject(HttmFacilityService);

  @Input() facilityId: string | null = null;

  readonly loading = signal(false);
  readonly error = signal<string | null>(null);
  readonly items = signal<HttmFacilityImageDto[]>([]);

  private readonly base: string;

  constructor(@Inject(API_BASE_URL) base: string) {
    this.base = base.replace(/\/$/, '');
  }

  ngOnInit(): void {
    this.reload();
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['facilityId'] && !changes['facilityId'].firstChange) {
      this.reload();
    }
  }

  reload(): void {
    const id = this.facilityId;
    if (!id) {
      this.items.set([]);
      return;
    }
    this.loading.set(true);
    this.error.set(null);
    this.api.listImages(id).subscribe({
      next: (data) => {
        this.items.set(data ?? []);
        this.loading.set(false);
      },
      error: (err: unknown) => {
        this.error.set(err instanceof Error ? err.message : 'Không tải được danh sách ảnh.');
        this.loading.set(false);
      },
    });
  }

  resolveUrl(url: string): string {
    if (!url) {
      return url;
    }
    if (/^https?:\/\//i.test(url)) {
      return url;
    }
    return `${this.base}${url.startsWith('/') ? '' : '/'}${url}`;
  }
}
