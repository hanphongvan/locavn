/// Whitelist các slug brand đã bundle marker trong `assets/map_markers/brands/`.
///
/// **Pattern asset:** `<brandKey>_<kind>.png` — 3 trạng thái khớp [StationMapMarkerAssetKind]:
/// `open`, `closed`, `cheap`. Tức mỗi brand bundle phải có **3 file**:
/// ```
/// assets/map_markers/brands/petrolimex_open.png
/// assets/map_markers/brands/petrolimex_closed.png
/// assets/map_markers/brands/petrolimex_cheap.png
/// ```
/// Kích thước khuyến nghị **48×56 nền trong suốt** (bottom-tip anchor — đồng bộ marker chung).
/// Slug ở đây PHẢI khớp `StationBranding:Brands[].Key` backend (`appsettings.json`).
///
/// **Khi thêm brand mới đã ký:**
/// 1. Copy 3 file PNG `<slug>_open.png` / `_closed.png` / `_cheap.png` vào folder trên
/// 2. Thêm slug vào [bundled]
/// 3. Cấu hình `ParentDonViId` ở backend appsettings
/// 4. Không cần đụng marker pipeline
abstract final class BrandMarkerRegistry {
  static const String _folder = 'assets/map_markers/brands';

  static const Set<String> bundled = {
    'petrolimex',
    'pvoil',
    'saigon_petro',
  };

  /// 3 trạng thái khớp `StationMapMarkerAssetKind` — hardcode string thay vì import
  /// enum để giữ class này thuần asset (không phụ thuộc presentation layer).
  static const List<String> kinds = ['open', 'closed', 'cheap'];

  static bool isBundled(String? brandKey) =>
      brandKey != null && bundled.contains(brandKey);

  /// Asset path bundled cho (brand, kind). Null nếu brand chưa bundle.
  /// [kind] PHẢI là 1 trong [kinds] (`open`/`closed`/`cheap`).
  static String? assetPathFor(String? brandKey, String kind) {
    if (brandKey == null || brandKey.isEmpty) return null;
    if (!bundled.contains(brandKey)) return null;
    return '$_folder/${brandKey}_$kind.png';
  }

  /// 9 path (3 brand × 3 kind) — preload + test.
  static List<String> allBundledPaths() => [
        for (final b in bundled)
          for (final k in kinds) '$_folder/${b}_$k.png',
      ];
}
