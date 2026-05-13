import { Component } from '@angular/core';

/** Gallery ảnh — Phase 1: API chưa trả danh sách ảnh theo facility; chỉ upload từ tab cha. */
@Component({
  selector: 'app-httm-image-gallery',
  standalone: true,
  template: `<p class="muted">Xem thư viện ảnh đầy đủ sẽ bổ sung khi backend có endpoint liệt kê.</p>`,
})
export class HttmImageGalleryComponent {}
