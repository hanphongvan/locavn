import { Component, computed, inject, signal } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';

import { AdminAuthService } from '../../../core/auth/admin-auth.service';
import { CurrentUserContextService } from '../../../core/auth/current-user-context.service';
import { getShellNavGroupsForRole } from '../../../config/portal-navigation.config';
import { portalRoleToTopbarLabel } from '../../../core/auth/portal-loai-role';

@Component({
  selector: 'app-admin-shell',
  standalone: true,
  imports: [RouterOutlet, RouterLink, RouterLinkActive],
  templateUrl: './admin-shell.component.html',
  styleUrl: './admin-shell.component.scss',
})
export class AdminShellComponent {
  private readonly auth = inject(AdminAuthService);
  private readonly userContext = inject(CurrentUserContextService);

  readonly navOpen = signal(false);

  readonly navGroups = computed(() => getShellNavGroupsForRole(this.auth.portalRole()));

  /** Nhóm đang thu gọn (mặc định mở hết — id có trong set = đang đóng). */
  private readonly collapsedGroupIds = signal<ReadonlySet<string>>(new Set());

  isGroupCollapsed(groupId: string): boolean {
    return this.collapsedGroupIds().has(groupId);
  }

  toggleGroup(groupId: string): void {
    this.collapsedGroupIds.update((prev) => {
      const next = new Set(prev);
      if (next.has(groupId)) {
        next.delete(groupId);
      } else {
        next.add(groupId);
      }
      return next;
    });
  }

  /** Shown next to logout: displayName, or userName. */
  readonly headerAccountName = computed(() => {
    const d = this.userContext.displayName()?.trim();
    if (d) {
      return d;
    }
    const u = this.userContext.userName().trim();
    return u || '';
  });

  readonly headerRoleLabel = computed(() => portalRoleToTopbarLabel(this.auth.portalRole()));

  toggleNav(): void {
    this.navOpen.update((v) => !v);
  }

  closeNav(): void {
    this.navOpen.set(false);
  }

  onSidebarLinkClick(): void {
    if (typeof globalThis !== 'undefined' && globalThis.matchMedia('(max-width: 1023px)').matches) {
      this.navOpen.set(false);
    }
  }

  logout(): void {
    this.auth.logout();
  }
}
