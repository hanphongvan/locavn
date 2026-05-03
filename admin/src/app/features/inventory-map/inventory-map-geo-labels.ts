import * as L from 'leaflet';

/** Pane z-index below station markers; pointer-events none so clicks reach the map/markers. */
const GEO_LABEL_PANE = 'invMapGeoLabels';

export interface SeaIslandGeoLabelDef {
  readonly lat: number;
  readonly lng: number;
  /** Fixed Vietnamese caption (escaped when rendered). */
  readonly text: string;
}

/**
 * Approximate label anchors (WGS84) — cartographic reference only, not a territorial statement.
 * Hoàng Sa: Paracels centroid; Trường Sa: Spratlys area centroid for small-scale maps.
 */
export const SEA_ISLAND_GEO_LABELS: readonly SeaIslandGeoLabelDef[] = [
  { lat: 16.52, lng: 111.95, text: 'Quần đảo Hoàng Sa' },
  { lat: 8.85, lng: 114.25, text: 'Quần đảo Trường Sa' },
];

const ICON_W = 168;
const ICON_H = 22;

function escapeLabelText(s: string): string {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

/**
 * Adds non-interactive text overlays (not image markers). Returns a layer group for optional removal;
 * usually left on map for the map lifetime.
 */
export function mountSeaIslandGeoLabels(map: L.Map): L.LayerGroup {
  if (!map.getPane(GEO_LABEL_PANE)) {
    const pane = map.createPane(GEO_LABEL_PANE);
    pane.style.zIndex = '340';
    pane.style.pointerEvents = 'none';
  }

  const group = L.layerGroup();

  for (const def of SEA_ISLAND_GEO_LABELS) {
    const icon = L.divIcon({
      className: 'inv-map-geo-label',
      html: `<span class="inv-map-geo-label__text">${escapeLabelText(def.text)}</span>`,
      iconSize: [ICON_W, ICON_H],
      iconAnchor: [ICON_W / 2, ICON_H / 2],
    });

    L.marker([def.lat, def.lng], {
      icon,
      interactive: false,
      keyboard: false,
      pane: GEO_LABEL_PANE,
      zIndexOffset: -400,
    }).addTo(group);
  }

  group.addTo(map);
  return group;
}
