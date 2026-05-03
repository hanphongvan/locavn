import { SelectionModel } from '@angular/cdk/collections';
import { CommonModule } from '@angular/common';
import { Component, OnDestroy, OnInit, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatCheckboxModule } from '@angular/material/checkbox';
import { MatDialog, MatDialogModule } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';
import { MatPaginatorModule, PageEvent } from '@angular/material/paginator';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatSelectModule } from '@angular/material/select';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { MatTableModule } from '@angular/material/table';
import { MatTooltipModule } from '@angular/material/tooltip';
import { Router, RouterLink } from '@angular/router';
import { Subject, debounceTime, distinctUntilChanged, takeUntil } from 'rxjs';

import {
  FilterPanelComponent,
  PageHeaderComponent,
  SectionCardComponent,
  StatusBadgeComponent,
  TableWrapperComponent,
} from '../../shared/ui';
import type { DonViOptionDto, UserListItemDto } from './user-management.models';
import { UserManagementService } from './user-management.service';
import { UserManagementConfirmDialogComponent } from './user-management-confirm-dialog.component';

@Component({
  selector: 'app-user-management-page',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    RouterLink,
    MatTableModule,
    MatPaginatorModule,
    MatButtonModule,
    MatIconModule,
    MatInputModule,
    MatFormFieldModule,
    MatSelectModule,
    MatCheckboxModule,
    MatProgressSpinnerModule,
    MatSnackBarModule,
    MatTooltipModule,
    MatDialogModule,
    PageHeaderComponent,
    FilterPanelComponent,
    SectionCardComponent,
    TableWrapperComponent,
    StatusBadgeComponent,
  ],
  templateUrl: './user-management-page.component.html',
  styleUrl: './user-management-page.component.scss',
})
export class UserManagementPageComponent implements OnInit, OnDestroy {
  private readonly api = inject(UserManagementService);
  private readonly router = inject(Router);
  private readonly snack = inject(MatSnackBar);
  private readonly dialog = inject(MatDialog);

  private readonly destroy$ = new Subject<void>();
  private readonly keyword$ = new Subject<string>();

  readonly loading = signal(false);
  readonly error = signal<string | null>(null);
  readonly items = signal<UserListItemDto[]>([]);
  readonly totalCount = signal(0);
  readonly pageIndex = signal(0);
  readonly pageSize = signal(20);
  readonly donViOptions = signal<DonViOptionDto[]>([]);

  keyword = '';
  donViId: number | null = null;
  loai: number | null = null;
  locked: boolean | null = null;

  readonly displayedColumns: string[] = [
    'select',
    'userName',
    'displayName',
    'loaiLabel',
    'donViDisplayName',
    'isLocked',
    'actions',
  ];
  readonly selection = new SelectionModel<UserListItemDto>(true, []);

  ngOnInit(): void {
    this.api
      .donVi()
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (rows) => this.donViOptions.set(rows),
        error: () => this.donViOptions.set([]),
      });

    this.keyword$
      .pipe(debounceTime(300), distinctUntilChanged(), takeUntil(this.destroy$))
      .subscribe(() => {
        this.pageIndex.set(0);
        void this.load();
      });

    void this.load();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  onKeywordInput(): void {
    this.keyword$.next(this.keyword);
  }

  onFilterChange(): void {
    this.pageIndex.set(0);
    void this.load();
  }

  onPage(ev: PageEvent): void {
    this.pageIndex.set(ev.pageIndex);
    this.pageSize.set(ev.pageSize);
    void this.load();
  }

  isAllSelected(): boolean {
    const rows = this.items();
    return rows.length > 0 && this.selection.selected.length === rows.length;
  }

  masterToggle(): void {
    if (this.isAllSelected()) {
      this.selection.clear();
    } else {
      for (const r of this.items()) {
        this.selection.select(r);
      }
    }
  }

  checkboxLabel(row?: UserListItemDto): string {
    if (!row) {
      return `${this.isAllSelected() ? 'Bỏ chọn' : 'Chọn'} tất cả`;
    }
    return `${this.selection.isSelected(row) ? 'Bỏ chọn' : 'Chọn'} ${row.userName}`;
  }

  async load(): Promise<void> {
    this.loading.set(true);
    this.error.set(null);
    this.selection.clear();
    this.api
      .list({
        keyword: this.keyword || null,
        donViId: this.donViId,
        loai: this.loai,
        locked: this.locked,
        skip: this.pageIndex() * this.pageSize(),
        take: this.pageSize(),
      })
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (page) => {
          this.items.set(page.items);
          this.totalCount.set(page.totalCount);
          this.loading.set(false);
        },
        error: (e: unknown) => {
          this.loading.set(false);
          const msg = e instanceof Error ? e.message : 'Không tải được danh sách.';
          this.error.set(msg);
          this.snack.open(msg, 'Đóng', { duration: 6000 });
        },
      });
  }

  addNew(): void {
    void this.router.navigate(['/users/new']);
  }

  edit(row: UserListItemDto): void {
    void this.router.navigate(['/users', row.id]);
  }

  exportExcel(): void {
    this.api
      .exportCsvBlob({
        keyword: this.keyword || null,
        donViId: this.donViId,
        loai: this.loai,
        locked: this.locked,
      })
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (blob) => {
          const url = URL.createObjectURL(blob);
          const a = document.createElement('a');
          a.href = url;
          a.download = 'users.csv';
          a.click();
          URL.revokeObjectURL(url);
          this.snack.open('Đã tải file CSV (mở bằng Excel).', 'OK', { duration: 4000 });
        },
        error: () => this.snack.open('Xuất file thất bại.', 'Đóng', { duration: 5000 }),
      });
  }

  lockSelected(): void {
    const ids = this.selection.selected.map((x) => x.id);
    if (ids.length === 0) {
      this.snack.open('Chọn ít nhất một người dùng.', 'OK');
      return;
    }

    const ref = this.dialog.open(UserManagementConfirmDialogComponent, {
      data: {
        title: 'Khóa tài khoản',
        message: `Khóa ${ids.length} tài khoản đã chọn?`,
      },
    });
    ref.afterClosed().subscribe((ok) => {
      if (!ok) {
        return;
      }
      this.api.lock({ userIds: ids }).subscribe({
        next: (r) => {
          this.snack.open(`Đã khóa ${r.affected} tài khoản.`, 'OK');
          void this.load();
        },
        error: () => this.snack.open('Thao tác thất bại.', 'Đóng'),
      });
    });
  }

  unlockSelected(): void {
    const ids = this.selection.selected.map((x) => x.id);
    if (ids.length === 0) {
      this.snack.open('Chọn ít nhất một người dùng.', 'OK');
      return;
    }

    const ref = this.dialog.open(UserManagementConfirmDialogComponent, {
      data: {
        title: 'Mở khóa tài khoản',
        message: `Mở khóa ${ids.length} tài khoản đã chọn?`,
      },
    });
    ref.afterClosed().subscribe((ok) => {
      if (!ok) {
        return;
      }
      this.api.unlock({ userIds: ids }).subscribe({
        next: (r) => {
          this.snack.open(`Đã mở khóa ${r.affected} tài khoản.`, 'OK');
          void this.load();
        },
        error: () => this.snack.open('Thao tác thất bại.', 'Đóng'),
      });
    });
  }

  syncAccounts(): void {
    const ref = this.dialog.open(UserManagementConfirmDialogComponent, {
      data: {
        title: 'Đồng bộ tài khoản',
        message: 'Chạy đồng bộ hồ sơ nhân sự (A_TienIch_HoSoNhanSu)?',
      },
    });
    ref.afterClosed().subscribe((ok) => {
      if (!ok) {
        return;
      }
      this.api.sync().subscribe({
        next: (r) => this.snack.open(r.message, 'OK', { duration: 5000 }),
        error: () => this.snack.open('Đồng bộ thất bại.', 'Đóng'),
      });
    });
  }

  deleteOne(row: UserListItemDto): void {
    const ref = this.dialog.open(UserManagementConfirmDialogComponent, {
      data: {
        title: 'Xóa người dùng',
        message: `Xóa vĩnh viễn "${row.userName}"?`,
      },
    });
    ref.afterClosed().subscribe((ok) => {
      if (!ok) {
        return;
      }
      this.api.delete(row.id).subscribe({
        next: () => {
          this.snack.open('Đã xóa.', 'OK');
          void this.load();
        },
        error: () => this.snack.open('Xóa thất bại.', 'Đóng'),
      });
    });
  }
}
