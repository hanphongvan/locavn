using Httm.XangDau.Api.Features.LeaderAi.Contracts;

namespace Httm.XangDau.Api.Features.LeaderAi.Persistence;

/// <summary>
/// Dapper data access cho 4 SP <c>sp_Ai_*</c> — AI Gateway gọi qua
/// <c>POST /internal/ai/*</c> ở Phase 2A.
/// </summary>
public interface IAiInternalDataAccess
{
    Task<IReadOnlyList<AiFuelInventoryRow>> GetFuelInventorySummaryAsync(
        AiFuelInventoryRequest request,
        CancellationToken cancellationToken);

    Task<IReadOnlyList<AiFuelPriceRow>> GetFuelPriceTrendAsync(
        AiFuelPriceRequest request,
        CancellationToken cancellationToken);

    Task<IReadOnlyList<AiHeadOfficeRow>> GetInventoryByHeadOfficeAsync(
        AiInventoryByHeadOfficeRequest request,
        CancellationToken cancellationToken);

    Task<IReadOnlyList<AiStationDensityRow>> GetStationDensityByProvinceAsync(
        AiStationDensityRequest request,
        CancellationToken cancellationToken);

    /// <summary>INSERT 1 row vào <c>AiToolLogs</c> — phục vụ token usage logging Section 9.</summary>
    Task LogToolCallAsync(
        AiToolLogRequest request,
        CancellationToken cancellationToken);
}
