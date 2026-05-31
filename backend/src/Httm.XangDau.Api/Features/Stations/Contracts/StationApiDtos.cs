using Httm.XangDau.Api.Features.FuelReporting.Contracts;

namespace Httm.XangDau.Api.Features.Stations.Contracts;

/// <summary>Paginated station read models (mobile list / map).</summary>
public sealed record PagedStationsResponse<T>(IReadOnlyList<T> Items, int TotalCount, int Skip, int Take);

/// <summary>
/// 1 cluster / 1 tỉnh cho <c>GET /api/stations/map/clusters</c>: số trạm + centroid (avg lat/lng).
/// Dùng khi zoom map &lt; threshold để tránh render hàng nghìn marker.
/// </summary>
public sealed record StationMapProvinceClusterDto(
    int ProvinceId,
    string ProvinceCode,
    string ProvinceName,
    long StationCount,
    double CentroidLat,
    double CentroidLng);

/// <summary>One row in <c>StationOperatingHours</c> (weekly template).</summary>
public sealed record StationOperatingSlotDto(
    int DayOfWeek,
    bool IsClosedAllDay,
    string? OpensAt,
    string? ClosesAt);

/// <summary>Lightweight row for <c>GET /api/stations</c> — <c>DM_DonVi</c> with optional geography.</summary>
public sealed record StationListItemDto(
    int StationId,
    string StationCode,
    string StationName,
    /// <summary>Prefer <c>DiaChiChiTiet</c>, else <c>DiaChi</c>.</summary>
    string? AddressLine,
    string? ProvinceCode,
    string? ProvinceName,
    string? WardCode,
    string? WardName,
    /// <summary>District derived from <c>DM_XaPhuong.QuanHuyenId</c> when ward is linked.</summary>
    int? DistrictId,
    string? LicenseNumber,
    bool? IsActive,
    /// <summary>Visitor-facing open now (Vietnam time), from <c>StationOperatingHours</c> when configured.</summary>
    bool? OpenNow = null,
    /// <summary><c>open</c>, <c>closed</c>, or <c>unknown</c> (no schedule for today).</summary>
    string? OpenStatus = null,
    /// <summary>Today opening time (<c>HH:mm</c>) when known.</summary>
    string? OpeningTime = null,
    /// <summary>Today closing time (<c>HH:mm</c>) when known.</summary>
    string? ClosingTime = null,
    decimal? PriceRon95 = null,
    decimal? PriceDiesel = null);

/// <summary>Minimal marker payload for <c>GET /api/stations/map</c> — only stations with valid coordinates.</summary>
public sealed record StationMapItemDto(
    int StationId,
    string StationName,
    double Latitude,
    double Longitude,
    string? ShortAddress,
    decimal? PriceRon95 = null,
    decimal? PriceDiesel = null,
    /// <summary><c>DM_DonVi.TrangThai</c> — license / business flag.</summary>
    bool? IsActive = null,
    bool? OpenNow = null,
    string? OpenStatus = null,
    /// <summary>Giờ mở hiển thị — ưu tiên <c>DM_DonVi.OpenTime</c> khi có; không thì lịch <c>StationOperatingHours</c> hôm nay.</summary>
    string? OpeningTime = null,
    /// <summary>Giờ đóng — ưu tiên <c>DM_DonVi.CloseTime</c> khi có; không thì lịch tuần hôm nay.</summary>
    string? ClosingTime = null,
    /// <summary>Active <c>StationStoreServices.ServiceCode</c> values for map filtering (client-side).</summary>
    IReadOnlyList<string>? ActiveServiceCodes = null,
    /// <summary>Stable slug mapped từ <c>DM_DonVi.CapTrenId</c> (đầu mối) qua <c>StationBranding</c> appsettings. Null = dùng marker chung.</summary>
    string? BrandKey = null,
    /// <summary>Remote logo URL fallback khi brand chưa bundle trong app. Null = bundle-only / không có logo.</summary>
    string? BrandLogoUrl = null,
    /// <summary><c>DM_DonVi.CapTrenId</c> — đầu mối (CapDonViId=235) của trạm. Mobile dùng để lọc client-side theo đầu mối.</summary>
    int? ParentDonViId = null);

/// <summary>
/// V2 marker payload cho <c>GET /api/stations/map/v2</c>. Khác V1:
/// - <c>PriceRon95</c>/<c>PriceDiesel</c>/<see cref="PriceForSelectedFuel"/> lấy trực tiếp từ
///   <c>StationStoreServices.Price</c> (ServiceCode = <c>RON95</c>/<c>DIESEL</c>/<c>fuelCode</c> truyền vào).
/// - Khi <c>fuelCode</c> được set, response chỉ chứa các trạm có dịch vụ ấy đang <c>IsActive</c>.
/// </summary>
public sealed record StationMapItemV2Dto(
    int StationId,
    string StationName,
    double Latitude,
    double Longitude,
    string? ShortAddress,
    decimal? PriceRon95 = null,
    decimal? PriceDiesel = null,
    /// <summary>Giá theo fuel code mobile đã chọn (null khi <c>fuelCode</c> không truyền).</summary>
    decimal? PriceForSelectedFuel = null,
    bool? IsActive = null,
    bool? OpenNow = null,
    string? OpenStatus = null,
    string? OpeningTime = null,
    string? ClosingTime = null,
    IReadOnlyList<string>? ActiveServiceCodes = null,
    string? BrandKey = null,
    string? BrandLogoUrl = null,
    int? ParentDonViId = null);

/// <summary>Một đầu mối (<c>DM_DonVi</c> với <c>CapDonViId=235</c>) có ít nhất 1 trạm bán lẻ (<c>CapDonViId=248</c>).</summary>
public sealed record StationDistributorDto(
    int Id,
    string Name,
    int StationCount,
    /// <summary>Slug brand từ <c>StationBranding</c> appsettings; null nếu đầu mối chưa cấu hình logo riêng.</summary>
    string? BrandKey = null,
    /// <summary>Logo URL remote (optional, đi kèm <c>BrandKey</c>).</summary>
    string? BrandLogoUrl = null);

/// <summary>One configured retail service on a station (<c>StationStoreServices</c>).</summary>
public sealed record StationDetailStoreServiceDto(
    string ServiceCode,
    string DisplayName,
    string? IconKey,
    bool IsActive,
    decimal? Price,
    int SortOrder);

/// <summary>Detail row for <c>GET /api/stations/{id}</c> — petrol station (<c>CapDonViId = 248</c>) only.</summary>
public sealed record StationDetailDto(
    int StationId,
    string StationCode,
    string StationName,
    string? Phone,
    string? Email,
    string? AddressLine,
    string? LicenseNumber,
    DateTime? LicenseDate,
    DateTime? LicenseExpiryDate,
    double? Latitude,
    double? Longitude,
    string? ProvinceCode,
    string? ProvinceName,
    string? WardCode,
    string? WardName,
    int? DistrictId,
    /// <summary>Same format as <c>GET /api/geography/wards?districtCode=</c> when <see cref="DistrictId"/> is set (<c>QuanHuyenId</c> as string).</summary>
    string? DistrictCode,
    bool? IsActive,
    bool? OpenNow,
    string? OpenStatus,
    string? OpeningTime,
    string? ClosingTime,
    IReadOnlyList<StationOperatingSlotDto>? WeeklyOperatingHours,
    /// <summary>Latest <c>QT_TK_ThongKe</c> price lines (<c>Loai = 1</c>, same period resolution as <c>/api/prices</c>).</summary>
    StationReportingPricesDto? LatestReportingPrices,
    StationReportingStockDto? LatestReportingStock,
    /// <summary>Ron95 chip price from the same map snapshot as list/map (may be set when line-level <see cref="LatestReportingPrices"/> is empty).</summary>
    decimal? PriceRon95 = null,
    /// <summary>Diesel chip price from the same map snapshot as list/map.</summary>
    decimal? PriceDiesel = null,
    /// <summary>Rows from <c>StationStoreServices</c> when present.</summary>
    IReadOnlyList<StationDetailStoreServiceDto>? StoreServices = null);

/// <summary>
/// Một dòng giá nhiên liệu của cây xăng (V2) — lấy từ <c>StationStoreServices</c> với
/// <c>ServiceCode</c> bắt đầu bằng <c>E5</c> / <c>E10</c> / <c>DIESEL</c> / <c>RON</c>.
/// </summary>
public sealed record StationDetailPriceItemDto(
    string ServiceCode,
    string DisplayName,
    decimal? Price,
    int SortOrder);

/// <summary>
/// Detail row V2 cho <c>GET /api/stations/{id}/v2</c>. Khác V1:
/// - Bỏ <c>LatestReportingPrices</c> (giá báo cáo <c>QT_TK_ThongKe</c>); thay bằng
///   <see cref="Prices"/> lấy trực tiếp từ <c>StationStoreServices</c>.
/// - Giữ <c>LatestReportingStock</c> (data tồn kho hiển thị section "Tồn kho hiện tại").
/// - Giữ <c>PriceRon95</c>, <c>PriceDiesel</c> (fallback từ map snapshot cũ).
/// V1 vẫn tồn tại cho app đã release.
/// </summary>
public sealed record StationDetailV2Dto(
    int StationId,
    string StationCode,
    string StationName,
    string? Phone,
    string? Email,
    string? AddressLine,
    string? LicenseNumber,
    DateTime? LicenseDate,
    DateTime? LicenseExpiryDate,
    double? Latitude,
    double? Longitude,
    string? ProvinceCode,
    string? ProvinceName,
    string? WardCode,
    string? WardName,
    int? DistrictId,
    string? DistrictCode,
    bool? IsActive,
    bool? OpenNow,
    string? OpenStatus,
    string? OpeningTime,
    string? ClosingTime,
    IReadOnlyList<StationOperatingSlotDto>? WeeklyOperatingHours,
    StationReportingStockDto? LatestReportingStock,
    /// <summary>Danh sách giá nhiên liệu của cây xăng (V2). Rỗng khi station chưa khai báo.</summary>
    IReadOnlyList<StationDetailPriceItemDto> Prices,
    decimal? PriceRon95 = null,
    decimal? PriceDiesel = null,
    IReadOnlyList<StationDetailStoreServiceDto>? StoreServices = null);

/// <summary>Single-station spotlight for nearest / cheapest / top-rated search APIs.</summary>
public sealed record StationSpotlightDto(
    int StationId,
    string Name,
    string? Address,
    /// <summary>Ron95 <c>So_01</c> from latest reporting snapshot when present.</summary>
    decimal? PriceRon95,
    /// <summary>Diesel <c>So_01</c> from latest reporting snapshot when present.</summary>
    decimal? PriceDiesel,
    /// <summary>From <c>StationReviews</c> when the station has at least one review; otherwise null.</summary>
    double? AverageRating,
    int? ReviewCount,
    /// <summary>Great-circle distance in km; set only for <c>/nearest</c>.</summary>
    double? DistanceKm);
