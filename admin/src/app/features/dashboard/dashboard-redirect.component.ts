import { Component, OnInit, inject } from '@angular/core';
import { Router } from '@angular/router';

import { AdminAuthService } from '../../core/auth/admin-auth.service';

/** Navigates from `/dashboard` to `/dashboard/{admin|trader|store}` based on `Loai`. */
@Component({
  selector: 'app-dashboard-redirect',
  standalone: true,
  template: '',
})
export class DashboardRedirectComponent implements OnInit {
  private readonly router = inject(Router);
  private readonly auth = inject(AdminAuthService);

  ngOnInit(): void {
    void this.router.navigateByUrl(this.auth.getRoleLandingPath(), { replaceUrl: true });
  }
}
