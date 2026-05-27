import { Injectable, signal } from '@angular/core';

/** Phase 1: nền OSM (Carto); Goong cần API key — sau này đồng bộ `AppSystemSettings`. */
export type HttmMapTileProvider = 'osm' | 'goong';

export interface HttmMapTileSpec {
  url: string;
  attribution: string;
  maxZoom: number;
}

@Injectable({ providedIn: 'root' })
export class HttmMapService {
  readonly tileProvider = signal<HttmMapTileProvider>('osm');

  setTileProvider(p: HttmMapTileProvider): void {
    this.tileProvider.set(p);
  }

  /** OSM qua Carto Light; Goong tạm dùng cùng nền cho đến khi có key. */
  getTileSpec(): HttmMapTileSpec {
    const url = 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';
    const attribution =
      this.tileProvider() === 'goong'
        ? 'Goong (chưa cấu hình key) — đang hiển thị nền OSM/Carto.'
        : '&copy; OpenStreetMap &copy; CARTO';
    return { url, attribution, maxZoom: 19 };
  }

  readonly defaultCenterLat = 15.9266657;
  readonly defaultCenterLng = 107.9650855;
  readonly defaultZoom = 6;
}
