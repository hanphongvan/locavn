/// Stock level for inventory map marker art (bundled PNGs only; no widget-drawn pins).
///
/// Wire mapping: API / SQL `out` | `low` | `normal` → PNG `station_closed` |
/// `station_cheap` | `station_open` (cùng asset bản đồ cây xăng, Google Map).
enum StockMapStockStatus {
  out,
  low,
  normal,
}
