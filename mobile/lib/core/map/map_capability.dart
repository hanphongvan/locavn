/// Provider không feature-parity (xem `mobile/docs/map-provider-architecture.md`).
/// UI phải kiểm tra capability trước khi gọi tính năng tương ứng, không giả định.
enum MapCapability {
  nativeClustering,
  vectorStyle,
  offline,
  heatmap,
  buildings3d,
  traffic,
}
