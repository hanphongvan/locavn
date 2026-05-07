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

    /// <summary>
    /// Phase 2A bugfix — gọi <c>sp_Ai_GetRetailFuelInventorySummary</c> cho intent
    /// <c>RETAIL_FUEL_INVENTORY_SUMMARY</c>. Khác <see cref="GetFuelInventorySummaryAsync"/>
    /// (đầu mối) ở chỗ đọc <c>StationInventoryTransaction*</c> + filter <c>FuelProducts.Code</c>.
    /// </summary>
    Task<IReadOnlyList<AiFuelInventoryRow>> GetRetailFuelInventorySummaryAsync(
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

    /// <summary>
    /// Phase 3 — UPSERT <c>AiConversationContexts.LastAnswerSummary</c> theo
    /// <c>ConversationId</c>. AI Gateway gọi mỗi 5 lượt (Section 19.3).
    /// </summary>
    Task UpsertContextSummaryAsync(
        Guid conversationId,
        int userId,
        string summary,
        CancellationToken cancellationToken);
}
