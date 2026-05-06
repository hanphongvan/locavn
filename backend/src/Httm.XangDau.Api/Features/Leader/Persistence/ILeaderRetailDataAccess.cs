using Httm.XangDau.Api.Features.Leader.Contracts;

namespace Httm.XangDau.Api.Features.Leader.Persistence;

/// <summary>
/// Truy vấn dashboard / dropdown filter Leader Retail (`CapDonViId = 248`) qua stored procedure.
/// </summary>
public interface ILeaderRetailDataAccess
{
    /// <summary>Gọi <c>dbo.sp_LeaderRetail_GetDashboard</c> — KPI + ranking + raw stations.</summary>
    Task<LeaderRetailDashboardData> GetDashboardAsync(
        int? provinceId,
        bool? status,
        int? managingUnitId,
        CancellationToken cancellationToken = default);

    /// <summary>Gọi <c>dbo.sp_LeaderRetail_GetManagingUnits</c>.</summary>
    Task<IReadOnlyList<LeaderRetailManagingUnitDto>> GetManagingUnitsAsync(
        CancellationToken cancellationToken = default);

    /// <summary>Gọi <c>dbo.sp_LeaderRetail_GetProvinces</c>.</summary>
    Task<IReadOnlyList<LeaderRetailProvinceDto>> GetProvincesAsync(
        CancellationToken cancellationToken = default);
}

/// <summary>Snapshot dữ liệu thuần từ SP — service C# sẽ apply rule engine để sinh warnings.</summary>
public sealed record LeaderRetailDashboardData(
    LeaderRetailKpiDto Kpi,
    IReadOnlyList<LeaderRetailProvinceRowDto> Provinces,
    IReadOnlyList<LeaderRetailStationRow> Stations);

/// <summary>Raw row 1 cửa hàng cho rule engine (thiếu toạ độ, dữ liệu cũ, …).</summary>
public sealed record LeaderRetailStationRow(
    int StationId,
    string? StationName,
    int? ProvinceId,
    string? ProvinceName,
    int? ManagingUnitId,
    string? ManagingUnitName,
    double? ViDo,
    double? KinhDo,
    bool? TrangThai,
    DateTime? Modified);
