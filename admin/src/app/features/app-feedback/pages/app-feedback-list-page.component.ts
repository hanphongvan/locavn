import { CommonModule } from '@angular/common';
import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';
import { MatChipsModule } from '@angular/material/chips';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';

import {
  APP_FEEDBACK_CATEGORY_LABELS,
  APP_FEEDBACK_STATUS_LABELS,
  type AppFeedbackImage,
  type AppFeedbackListItem,
} from '../models/app-feedback.model';
import { AppFeedbackService } from '../services/app-feedback.service';

@Component({
  selector: 'app-app-feedback-list-page',
  standalone: true,
  imports: [
    CommonModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatChipsModule,
    MatProgressSpinnerModule,
    MatSnackBarModule,
  ],
  templateUrl: './app-feedback-list-page.component.html',
  styleUrl: './app-feedback-list-page.component.scss',
})
export class AppFeedbackListPageComponent implements OnInit {
  private readonly api = inject(AppFeedbackService);
  private readonly snack = inject(MatSnackBar);

  readonly categoryLabels = APP_FEEDBACK_CATEGORY_LABELS;
  readonly statusLabels = APP_FEEDBACK_STATUS_LABELS;

  readonly items = signal<AppFeedbackListItem[]>([]);
  readonly totalCount = signal(0);
  readonly loading = signal(false);
  readonly page = signal(1);
  readonly pageSize = 20;

  /** Ảnh đã tải theo id (gọi detail khi user mở). */
  private readonly imagesById = signal<Record<number, AppFeedbackImage[]>>({});
  private readonly expandedIds = signal<ReadonlySet<number>>(new Set());
  private readonly loadingImageIds = signal<ReadonlySet<number>>(new Set());

  readonly totalPages = computed(() => Math.max(1, Math.ceil(this.totalCount() / this.pageSize)));
  readonly rangeStart = computed(() => (this.totalCount() === 0 ? 0 : (this.page() - 1) * this.pageSize + 1));
  readonly rangeEnd = computed(() => Math.min(this.page() * this.pageSize, this.totalCount()));

  ngOnInit(): void {
    this.reload();
  }

  reload(): void {
    this.loading.set(true);
    this.api.listAdmin({ skip: (this.page() - 1) * this.pageSize, take: this.pageSize }).subscribe({
      next: (r) => {
        this.items.set(r.items);
        this.totalCount.set(r.totalCount);
      },
      error: () => this.snack.open('Không tải được danh sách góp ý.', 'Đóng'),
      complete: () => this.loading.set(false),
    });
  }

  prevPage(): void {
    if (this.page() <= 1) return;
    this.page.update((p) => p - 1);
    this.reload();
  }

  nextPage(): void {
    if (this.page() >= this.totalPages()) return;
    this.page.update((p) => p + 1);
    this.reload();
  }

  categoryLabel(c: number): string {
    return this.categoryLabels[c] ?? `#${c}`;
  }

  statusLabel(s: number): string {
    return this.statusLabels[s] ?? `#${s}`;
  }

  isExpanded(id: number): boolean {
    return this.expandedIds().has(id);
  }

  isLoadingImages(id: number): boolean {
    return this.loadingImageIds().has(id);
  }

  imagesFor(id: number): AppFeedbackImage[] {
    return this.imagesById()[id] ?? [];
  }

  toggleImages(item: AppFeedbackListItem): void {
    if (item.imageCount === 0) return;
    const id = item.id;
    if (this.isExpanded(id)) {
      this.expandedIds.update((prev) => {
        const next = new Set(prev);
        next.delete(id);
        return next;
      });
      return;
    }

    this.expandedIds.update((prev) => new Set(prev).add(id));
    if (this.imagesById()[id]) return; // đã tải

    this.loadingImageIds.update((prev) => new Set(prev).add(id));
    this.api.getDetail(id).subscribe({
      next: (d) => this.imagesById.update((prev) => ({ ...prev, [id]: d.images })),
      error: () => this.snack.open('Không tải được ảnh đính kèm.', 'Đóng'),
      complete: () =>
        this.loadingImageIds.update((prev) => {
          const next = new Set(prev);
          next.delete(id);
          return next;
        }),
    });
  }
}
