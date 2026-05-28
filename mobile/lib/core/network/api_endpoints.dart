/// Paths only (no host). Must match ASP.NET route templates.
///
/// **Spotlight:** nearest, cheapest, top-rated wired in Flutter.
/// `/api/stations/nearest`, `/api/stations/cheapest`, `/api/stations/top-rated`;
/// reviews `/api/stations/{id}/reviews` (+ rating summary); bad reports `POST /api/bad-reports`.
/// Admin inventory map: `/api/admin/inventory-map?groupCode=XANG|DAU`.
/// Phased plan: `mobile/docs/flutter-map-upgrade-phases.md`.
abstract final class ApiEndpoints {
  static const stations = '/api/stations';
  static const stationsMap = '/api/stations/map';
  /// Citizen viewport — markers trong bbox + optional keyword (Phase 2.G).
  static const stationsMapBounds = '/api/stations/map/bounds';
  /// Province-level clusters (count + centroid) cho low zoom (Phase 2.G).
  static const stationsMapClusters = '/api/stations/map/clusters';
  static const stationsStoreServicesCatalog = '/api/stations/store-services-catalog';
  static const stationsNearest = '/api/stations/nearest';
  static const stationsCheapest = '/api/stations/cheapest';
  static const stationsTopRated = '/api/stations/top-rated';
  static String stationById(int id) => '/api/stations/$id';

  static String stationReviews(int stationId) => '/api/stations/$stationId/reviews';

  /// Đánh giá cây xăng do tài khoản đã gửi (`MyStationReviewsController`).
  static const myReviews = '/api/my-reviews';

  static String stationRatingSummary(int stationId) => '/api/stations/$stationId/rating-summary';

  static const badReports = '/api/bad-reports';

  /// Ảnh đính kèm báo vi phạm — multipart, JWT (`BadReportsController.UploadImage`).
  static const badReportsUploadImage = '/api/bad-reports/upload-image';

  /// Báo vi phạm do tài khoản đã gửi (`MyBadReportsController`).
  static const myBadReports = '/api/my-bad-reports';

  static const pricesLatest = '/api/prices/latest';
  static String pricesByStation(int stationId) => '/api/prices/by-station/$stationId';

  static const inventorySummary = '/api/inventory/summary';
  static String inventoryByStation(int stationId) => '/api/inventory/by-station/$stationId';

  /// Tồn kho từ sổ kho (header/detail + legacy) — bản đồ “Còn hàng” (`?donViIds=1,2,3`).
  static const inventoryMapStockByIds = '/api/inventory/map-stock-by-ids';

  static const geographyProvinces = '/api/geography/provinces';
  static const geographyDistricts = '/api/geography/districts';
  static const geographyWards = '/api/geography/wards';

  static const reportsOverview = '/api/reports/overview';

  /// Lãnh đạo (`Loai == 6`, Bearer JWT) — tương đương `api/dashboard/*` trên DMPPortal cũ.
  static const leaderDashboardSnapshot = '/api/leader/dashboard/snapshot';

  /// `fuelType`: `gasoline` | `oil` — đồng bộ kỳ với [month]/[year] (tùy chọn).
  static String leaderDashboardInventoryDetail(
    String fuelType, {
    int? month,
    int? year,
    String? statusGroup,
  }) {
    final b = StringBuffer('/api/leader/dashboard/inventory-detail?fuelType=')
      ..write(Uri.encodeQueryComponent(fuelType));
    if (month != null) b.write('&month=$month');
    if (year != null) b.write('&year=$year');
    if (statusGroup != null && statusGroup.isNotEmpty) {
      b.write('&statusGroup=');
      b.write(Uri.encodeQueryComponent(statusGroup));
    }
    return b.toString();
  }
  static const leaderHomeInventorySummary = '/api/leader/home/inventory-summary';
  static const leaderHomeNationalStockMovement = '/api/leader/home/national-stock-movement';
  static const leaderHomePriceSummary = '/api/leader/home/price-summary';
  static const leaderHomeDistributorMap = '/api/leader/home/distributor-map';

  /// Bỏ [month]/[year] để API chọn kỳ mới nhất theo cấu hình máy chủ (mốc ngày trong tháng, giờ VN).
  static String leaderStabilizationFundSummary({int? month, int? year}) {
    if (month != null && year != null) {
      return '/api/leader/stabilization-fund/summary?month=$month&year=$year';
    }
    return '/api/leader/stabilization-fund/summary';
  }

  static String leaderStabilizationFundDistributors({int? month, int? year}) {
    if (month != null && year != null) {
      return '/api/leader/stabilization-fund/distributors?month=$month&year=$year';
    }
    return '/api/leader/stabilization-fund/distributors';
  }

  static String leaderStabilizationFundDistributorHistory(int id, {int? month, int? year}) {
    if (month != null && year != null) {
      return '/api/leader/stabilization-fund/distributors/$id/history?month=$month&year=$year';
    }
    return '/api/leader/stabilization-fund/distributors/$id/history';
  }

  /// Bán lẻ — Lãnh đạo (Bearer). Filter: provinceId / status (bool) / managingUnitId.
  static String leaderRetailDashboard({int? provinceId, bool? status, int? managingUnitId}) {
    final params = <String, String>{};
    if (provinceId != null) params['provinceId'] = '$provinceId';
    if (status != null) params['status'] = status ? 'true' : 'false';
    if (managingUnitId != null) params['managingUnitId'] = '$managingUnitId';
    if (params.isEmpty) return '/api/leader/retail/dashboard';
    final qs = params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&');
    return '/api/leader/retail/dashboard?$qs';
  }

  static const leaderRetailManagingUnits = '/api/leader/retail/managing-units';
  static const leaderRetailProvinces = '/api/leader/retail/provinces';

  /// Bản đồ điều hành — Lãnh đạo (Bearer).
  static const leaderMapDistributors = '/api/leader/map/distributors';
  static String leaderMapDistributorInventory(int id) => '/api/leader/map/distributors/$id/inventory';
  static const leaderMapInventory = '/api/leader/map/inventory';
  static const leaderMapStations = '/api/leader/map/stations';

  static String leaderMapViolations(int stationId) => '/api/leader/map/violations?stationId=$stationId';

  /// Loca AI Leader Assistant — Bearer JWT, chỉ `Loai == 6` (Phase 2B).
  static const leaderAiChat = '/api/leader-ai/chat';
  static const leaderAiChatStream = '/api/leader-ai/chat/stream';
  static const leaderAiConversations = '/api/leader-ai/conversations';
  static String leaderAiConversation(String id) => '/api/leader-ai/conversations/$id';
  static const leaderAiReport = '/api/leader-ai/report';
  static const leaderAiHealth = '/api/leader-ai/health';
  static const leaderAiVoiceTranscribe = '/api/leader-ai/voice/transcribe';

  /// Voice → form đổ nhiên liệu cho citizen (Loai=5). Toggle bằng setting `loca.donhienlieu`.
  static const fuelVoiceFeatureStatus = '/api/fuel/voice/feature-status';
  static const fuelVoiceParseTransaction = '/api/fuel/voice/parse-fuel-tx';

  static String leaderMapPrices(String idsCommaSeparated) => '/api/leader/map/prices?ids=$idsCommaSeparated';

  /// Phân tích Lãnh đạo (GET, `window=d7|d30|m3|m6`, `fuel=xang|dau` khi cần).
  static String leaderAnalyticsInventoryTrend(String window) =>
      '/api/leader/analytics/inventory-trend?window=$window';

  static String leaderAnalyticsImportExportTrend(String window, String fuel) =>
      '/api/leader/analytics/import-export-trend?window=$window&fuel=$fuel';

  static String leaderAnalyticsPriceTrend(String window) =>
      '/api/leader/analytics/price-trend?window=$window';

  static String leaderAnalyticsPeriodComparison(String window) =>
      '/api/leader/analytics/period-comparison?window=$window';

  static String leaderAnalyticsMarketInsight(String window, String fuel) =>
      '/api/leader/analytics/market-insight?window=$window&fuel=$fuel';

  /// Store-admin inventory map (SP `dbo.sp_StoreAdmin_InventoryMap_ListByGroupCode`).
  static const adminInventoryMap = '/api/admin/inventory-map';

  /// Store-admin inventory vouchers (`StationInventoryTransactionHeaders` / `Details`).
  static const adminInventoryTransactions = '/api/admin/inventory-transactions';

  static String adminInventoryTransactionsByStore(int donViId) =>
      '/api/admin/inventory-transactions/by-store/$donViId';

  static String adminInventoryTransactionById(int id) => '/api/admin/inventory-transactions/$id';

  /// Current on-hand per product (`StationInventoryTransactions` aggregate).
  static String adminInventoriesCurrentByStore(int donViId) =>
      '/api/admin/inventories/current/by-store/$donViId';

  /// Store-admin retail sale prices (`StationPrices` / `StationProductPrices`) — same module as Angular `store-prices`.
  static const adminStorePrices = '/api/admin/store-prices';

  static String adminStorePricesById(int id) => '/api/admin/store-prices/$id';

  static String adminStorePricesCurrentByStore(int donViId) =>
      '/api/admin/store-prices/current/by-store/$donViId';

  static String adminStorePricesByStore(int donViId) => '/api/admin/store-prices/by-store/$donViId';

  static const adminStorePricesProducts = '/api/admin/store-prices/products';

  static const adminStorePricesDonViTinh = '/api/admin/store-prices/don-vi-tinh';

  static const adminStorePricesLatestSubmission = '/api/admin/store-prices/latest-submission';

  static const adminStorePricesBatch = '/api/admin/store-prices/batch';

  /// Store-admin optional retail services per station (`StationStoreServices`).
  static const adminStoreServices = '/api/admin/store-services';

  static const adminStoreServicesCatalog = '/api/admin/store-services/catalog';

  static String adminStoreServicesByStore(int donViId) =>
      '/api/admin/store-services/by-store/$donViId';

  static String adminStoreServiceById(int id) => '/api/admin/store-services/$id';

  /// Angular hub product filter — `FuelProductsApiService.list`.
  static const adminFuelProducts = '/api/admin/fuel-products';

  /// Angular hub store autocomplete — `StoresApiService.list`.
  static const adminStores = '/api/admin/stores';

  /// Portal user vehicles (`UserVehiclesController`).
  static const myVehicles = '/api/my-vehicles';

  /// Danh mục nhiên liệu cho form xe (JWT portal, không cần admin key).
  static const myVehiclesFuelProductOptions = '/api/my-vehicles/fuel-product-options';

  static String myVehicleById(int id) => '/api/my-vehicles/$id';

  static String myVehicleSetDefault(int id) => '/api/my-vehicles/$id/set-default';

  /// Portal fuel tracking (`FuelController`).
  static const fuelCurrentVehicle = '/api/fuel/current-vehicle';

  static const fuelSummary = '/api/fuel/summary';

  static const fuelInsights = '/api/fuel/insights';

  static const fuelTransactions = '/api/fuel/transactions';

  static String fuelTransactionById(int id) => '/api/fuel/transactions/$id';

  /// Đổi mật khẩu portal (JWT Bearer).
  static const authChangePassword = '/api/auth/change-password';

  /// Quên mật khẩu — gửi email đặt lại (anonymous).
  static const authForgotPassword = '/api/auth/forgot-password';

  /// Đặt lại mật khẩu bằng token từ email (anonymous).
  static const authResetPassword = '/api/auth/reset-password';

  /// Thống kê đánh giá / báo vi phạm / đổ xăng (JWT).
  static const accountActivitySummary = '/api/account/activity-summary';

  /// Ghi nhận yêu cầu xoá dữ liệu cá nhân (JWT) — `UserDataDeletionController`.
  static const userRequestDeleteData = '/api/user/request-delete-data';

}
