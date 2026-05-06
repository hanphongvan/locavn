namespace Httm.XangDau.Api.Features.Leader.Contracts;

/// <summary>KPI tổng hợp cửa hàng bán lẻ (sau khi áp filter).</summary>
public sealed record LeaderRetailKpiDto(
    long TotalStores,
    long ActiveStores,
    long PausedStores);

/// <summary>1 dòng ranking theo tỉnh — cho UI ranking + drill-down.</summary>
public sealed record LeaderRetailProvinceRowDto(
    int? ProvinceId,
    string? ProvinceCode,
    string? ProvinceName,
    long TotalStores,
    long ActiveStores,
    long PausedStores,
    DateTime? LastUpdatedAt);

/// <summary>Mức độ cảnh báo — không nhúng business logic vào SP.</summary>
public enum LeaderRetailWarningSeverity
{
    Low = 0,
    Medium = 1,
    High = 2,
}

/// <summary>1 cảnh báo điều hành (do C# rule engine sinh).</summary>
public sealed record LeaderRetailWarningDto(
    string Code,
    LeaderRetailWarningSeverity Severity,
    string Title,
    string Detail,
    int? ProvinceId = null,
    string? ProvinceName = null,
    int? StationId = null,
    string? StationName = null);

/// <summary>Response của <c>GET /api/leader/retail/dashboard</c>.</summary>
public sealed record LeaderRetailDashboardResponse(
    LeaderRetailKpiDto Kpi,
    IReadOnlyList<LeaderRetailProvinceRowDto> Provinces,
    IReadOnlyList<LeaderRetailWarningDto> Warnings);

/// <summary>1 đơn vị quản lý có cửa hàng bán lẻ bên dưới.</summary>
public sealed record LeaderRetailManagingUnitDto(
    int Id,
    string? Code,
    string? Name,
    long StoreCount);

/// <summary>Response của <c>GET /api/leader/retail/managing-units</c>.</summary>
public sealed record LeaderRetailManagingUnitsResponse(
    IReadOnlyList<LeaderRetailManagingUnitDto> Items);

/// <summary>1 tỉnh có cửa hàng bán lẻ.</summary>
public sealed record LeaderRetailProvinceDto(
    int Id,
    string? Code,
    string? Name,
    long StoreCount);

/// <summary>Response của <c>GET /api/leader/retail/provinces</c>.</summary>
public sealed record LeaderRetailProvincesResponse(
    IReadOnlyList<LeaderRetailProvinceDto> Items);
